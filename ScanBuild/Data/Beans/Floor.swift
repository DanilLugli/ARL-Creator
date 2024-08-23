import Foundation
import SceneKit
import simd
import SwiftUI

class Floor: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {
    
    private var _id = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    private var _planimetry: Image
    @Published private var _associationMatrix: [String: RotoTraslationMatrix]
    @Published private var _rooms: [Room]
    @Published private var _sceneObjects: [SCNNode]?
    @Published private var _scene: SCNScene?
    @Published private var _sceneConfiguration: SCNScene?
    private var _floorURL: URL
    
    init(name: String, lastUpdate: Date, planimetry: Image, associationMatrix: [String: RotoTraslationMatrix], rooms: [Room], sceneObjects: [SCNNode]?, scene: SCNScene?, sceneConfiguration: SCNScene?, floorURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._planimetry = planimetry
        self._associationMatrix = associationMatrix
        self._rooms = rooms
        self._sceneObjects = sceneObjects
        self._scene = scene
        self._sceneConfiguration = sceneConfiguration
        self._floorURL = floorURL
    }
    
    static func ==(lhs: Floor, rhs: Floor) -> Bool {
        return lhs.id == rhs.id // Compara gli ID, o qualsiasi altra proprietà unica
    }
    
    var id: UUID {
        return _id
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
            objectWillChange.send() // Forza la notifica di cambiamento
                
        }
    }
    
    var lastUpdate: Date {
        return _lastUpdate
    }
    
    var planimetry: Image {
        return _planimetry
    }
    
    var associationMatrix: [String: RotoTraslationMatrix] {
        get{
            return _associationMatrix
        }set{
            _associationMatrix = newValue
        }
    }
    
    var rooms: [Room] {
        get {
            return _rooms
        }
        set {
            _rooms = newValue
        }
    }
    
    var sceneObjects: [SCNNode]? {
        return _sceneObjects
    }
    
    var scene: SCNScene? {
        return _scene
    }
    
    var sceneConfiguration: SCNScene? {
        return _sceneConfiguration
    }
    
    var floorURL: URL {
        get {
            return _floorURL
        }
        set {
            _floorURL = newValue
        }
    }
    
    var url: URL {
        get {
            return floorURL
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case rooms
        case associationMatrix
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_rooms, forKey: .rooms)
        try container.encode(_associationMatrix, forKey: .associationMatrix)
    }
    
    func addRoom(room: Room) {
        _rooms.append(room)
        
        // Creare la directory della stanza all'interno di "<floor_name>_Rooms"
        let roomsDirectory = floorURL.appendingPathComponent(BuildingModel.FLOOR_ROOMS_FOLDER)
        let roomURL = roomsDirectory.appendingPathComponent(room.name)
        
        do {
            try FileManager.default.createDirectory(at: roomURL, withIntermediateDirectories: true, attributes: nil)
            room.roomURL = roomURL
            print("Folder created at: \(roomURL.path)")
            
            // Creare le cartelle all'interno della directory della stanza
            let subdirectories = ["JsonMaps", "JsonParametric", "Maps", "MapUsdz", "PlistMetadata", "ReferenceMarker", "TransitionZone"]
            
            for subdirectory in subdirectories {
                let subdirectoryURL = roomURL.appendingPathComponent(subdirectory)
                try FileManager.default.createDirectory(at: subdirectoryURL, withIntermediateDirectories: true, attributes: nil)
                print("Subdirectory created at: \(subdirectoryURL.path)")
            }
            
        } catch {
            print("Error creating folder for room \(room.name): \(error)")
        }
    }

    func deleteRoom(room: Room) {
        // Rimuovi la room dall'array _rooms
        _rooms.removeAll { $0.id == room.id }
        
        // Ottieni l'URL della cartella della room da eliminare
        let roomURL = floorURL.appendingPathComponent(room.name)
        
        // Elimina la cartella della room dal file system
        do {
            if FileManager.default.fileExists(atPath: roomURL.path) {
                try FileManager.default.removeItem(at: roomURL)
                print("Room \(room.name) eliminata con successo da \(roomURL.path).")
            } else {
                print("La cartella della room \(room.name) non esiste.")
            }
        } catch {
            print("Errore durante l'eliminazione della room \(room.name): \(error)")
        }
    }
    
    func renameRoom(floor: Floor, room: Room, newName: String) throws -> Bool {
        let fileManager = FileManager.default
        let oldRoomURL = room.roomURL
        let oldRoomName = room.name
        let newRoomURL = oldRoomURL.deletingLastPathComponent().appendingPathComponent(newName)

        // Verifica se esiste già una stanza con il nuovo nome
        guard !fileManager.fileExists(atPath: newRoomURL.path) else {
            throw NSError(domain: "com.example.ScanBuild", code: 3, userInfo: [NSLocalizedDescriptionKey: "Esiste già una stanza con il nome \(newName)"])
        }

        // Rinomina la cartella della stanza
        do {
            try fileManager.moveItem(at: oldRoomURL, to: newRoomURL)
        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 4, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina della cartella della stanza: \(error.localizedDescription)"])
        }
        
        // Aggiorna l'oggetto room
        room.roomURL = newRoomURL
        room.name = newName

        // Aggiorna il contenuto del file JSON nella cartella del floor associato
        do {
            try updateRoomInFloorJSON(floor: floor, oldRoomName: oldRoomName, newRoomName: newName)
        } catch {
            print("Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)")
        }
        
        // Aggiorna i file nelle sottocartelle della room rinominata
        do {
            try renameRoomFilesInDirectories(room: room, newRoomName: newName)
        } catch {
            print("Errore durante la rinomina dei file nelle sottocartelle della stanza: \(error.localizedDescription)")
        }
        
        // Ricarica i buildings dal file system per aggiornare i percorsi automaticamente
        BuildingModel.getInstance().buildings = []

        do {
            try BuildingModel.getInstance().loadBuildingsFromRoot()
        } catch {
            print("Errore durante il caricamento dei buildings: \(error)")
        }

        return true
    }
    
    func updateRoomInFloorJSON(floor: Floor, oldRoomName: String, newRoomName: String) throws {
        let fileManager = FileManager.default

        // Trova il file JSON del floor che contiene i nomi delle room
        let jsonFileURL = floor.floorURL.appendingPathComponent("\(floor.name).json")

        // Aggiorna il contenuto del file .json cambiando il nome della stanza
        do {
            let jsonData = try Data(contentsOf: jsonFileURL)
            var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]

            // Verifica se il vecchio nome esiste nel file JSON
            guard let roomData = jsonDict?[oldRoomName] as? [String: Any] else {
                throw NSError(domain: "com.example.ScanBuild", code: 8, userInfo: [NSLocalizedDescriptionKey: "Il nome della stanza \(oldRoomName) non esiste nel file JSON del floor."])
            }

            // Aggiorna il nome della stanza nel file JSON
            jsonDict?.removeValue(forKey: oldRoomName)
            jsonDict?[newRoomName] = roomData

            // Scrivi il nuovo contenuto nel file JSON
            let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict as Any, options: .prettyPrinted)
            try updatedJsonData.write(to: jsonFileURL)

            print("Contenuto del file JSON nel floor aggiornato con il nuovo nome della stanza \(newRoomName).")

        } catch {
            throw NSError(domain: "com.example.ScanBuild", code: 9, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'aggiornamento del contenuto del file JSON nel floor: \(error.localizedDescription)"])
        }
    }
    
    func renameRoomFilesInDirectories(room: Room, newRoomName: String) throws {
        let fileManager = FileManager.default
        let directories = ["PlistMetadata", "MapUsdz", "JsonParametric"]

        // Rinomina e aggiorna tutti i file .json nella cartella principale della stanza
        let roomDirectoryURL = room.roomURL
        let roomFiles = try fileManager.contentsOfDirectory(at: roomDirectoryURL, includingPropertiesForKeys: nil)

        for oldFileURL in roomFiles where oldFileURL.pathExtension == "json" {
            let oldFileName = oldFileURL.lastPathComponent
            let newFileName = "\(newRoomName).json"
            let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

            // Rinomina il file
            do {
                try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                print("File .json rinominato da \(oldFileName) a \(newFileName) nella cartella principale della stanza.")
            } catch {
                throw NSError(domain: "com.example.ScanBuild", code: 7, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file .json \(oldFileName): \(error.localizedDescription)"])
            }
        }

        // Itera su ciascuna delle cartelle (PlistMetadata, MapUsdz, JsonParametric)
        for directory in directories {
            let directoryURL = roomDirectoryURL.appendingPathComponent(directory)

            // Verifica se la directory esiste
            guard fileManager.fileExists(atPath: directoryURL.path) else {
                print("La directory \(directory) non esiste per la stanza \(room.name).")
                continue
            }

            // Ottieni tutti i file all'interno della directory
            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)

            // Itera su ciascun file per rinominarlo
            for oldFileURL in fileURLs {
                let oldFileName = oldFileURL.lastPathComponent
                let fileExtension = oldFileURL.pathExtension
                let newFileName = "\(newRoomName).\(fileExtension)"
                let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)

                do {
                    try fileManager.moveItem(at: oldFileURL, to: newFileURL)
                    print("File rinominato da \(oldFileName) a \(newFileName) nella directory \(directory).")
                } catch {
                    throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file \(oldFileName) in \(directory): \(error.localizedDescription)"])
                }
            }
        }
    }

//    func renameFilesInRoomDirectoriesAndUpdateJSON(room: Room, _ oldName: String, newName: String) throws {
//        let fileManager = FileManager.default
//        let directories = ["PlistMetadata", "MapUsdz", "JsonParametric"]
//
//        // Rinomina e aggiorna tutti i file .json nella cartella principale della stanza
//        let roomDirectoryURL = room.roomURL
//        let roomFiles = try fileManager.contentsOfDirectory(at: roomDirectoryURL, includingPropertiesForKeys: nil)
//        
//        for oldFileURL in roomFiles where oldFileURL.pathExtension == "json" {
//            let oldFileName = oldFileURL.lastPathComponent
//            let newFileName = "\(newName).json"
//            let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
//            
//            // Rinomina il file
//            do {
//                try fileManager.moveItem(at: oldFileURL, to: newFileURL)
//                print("File .json rinominato da \(oldFileName) a \(newFileName) nella cartella principale della stanza.")
//            } catch {
//                throw NSError(domain: "com.example.ScanBuild", code: 7, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file .json \(oldFileName): \(error.localizedDescription)"])
//            }
//
//            // Aggiorna il contenuto del file .json cambiando il nome della stanza
//            do {
//                let jsonData = try Data(contentsOf: newFileURL)
//                var jsonDict = try JSONSerialization.jsonObject(with: jsonData, options: []) as? [String: Any]
//                
//                // Verifica se il vecchio nome esiste nel file JSON
//                guard let roomData = jsonDict?[oldName] as? [String: Any] else {
//                    throw NSError(domain: "com.example.ScanBuild", code: 8, userInfo: [NSLocalizedDescriptionKey: "Il nome della stanza \(oldName) non esiste nel file JSON."])
//                }
//
//                // Aggiorna il nome della stanza
//                jsonDict?.removeValue(forKey: oldName)
//                jsonDict?[newName] = roomData
//
//                // Scrivi il nuovo contenuto nel file JSON
//                let updatedJsonData = try JSONSerialization.data(withJSONObject: jsonDict as Any, options: .prettyPrinted)
//                try updatedJsonData.write(to: newFileURL)
//
//                print("Contenuto del file JSON aggiornato con il nuovo nome della stanza \(newName).")
//                
//            } catch {
//                throw NSError(domain: "com.example.ScanBuild", code: 9, userInfo: [NSLocalizedDescriptionKey: "Errore durante l'aggiornamento del contenuto del file JSON: \(error.localizedDescription)"])
//            }
//        }
//
//        // Itera su ciascuna delle cartelle (PlistMetadata, MapUsdz, JsonParametric)
//        for directory in directories {
//            let directoryURL = roomDirectoryURL.appendingPathComponent(directory)
//            
//            // Verifica se la directory esiste
//            guard fileManager.fileExists(atPath: directoryURL.path) else {
//                print("La directory \(directory) non esiste per la stanza \(room.name).")
//                continue
//            }
//
//            // Ottieni tutti i file all'interno della directory
//            let fileURLs = try fileManager.contentsOfDirectory(at: directoryURL, includingPropertiesForKeys: nil)
//
//            // Itera su ciascun file per rinominarlo
//            for oldFileURL in fileURLs {
//                let oldFileName = oldFileURL.lastPathComponent
//                let fileExtension = oldFileURL.pathExtension
//                let newFileName = "\(newName).\(fileExtension)"
//                let newFileURL = oldFileURL.deletingLastPathComponent().appendingPathComponent(newFileName)
//                
//                do {
//                    try fileManager.moveItem(at: oldFileURL, to: newFileURL)
//                    print("File rinominato da \(oldFileName) a \(newFileName) nella directory \(directory).")
//                } catch {
//                    throw NSError(domain: "com.example.ScanBuild", code: 6, userInfo: [NSLocalizedDescriptionKey: "Errore durante la rinomina del file \(oldFileName) in \(directory): \(error.localizedDescription)"])
//                }
//            }
//        }
//    }
    
    func loadAssociationMatrixFromJSON(fileURL: URL) {
        do {
            let data = try Data(contentsOf: fileURL)
            let jsonDecoder = JSONDecoder()
            let jsonObject = try JSONSerialization.jsonObject(with: data, options: [])
            guard let dictionary = jsonObject as? [String: [String: [[Float]]]] else {
                print("Error: Cannot convert JSON data to dictionary")
                return
            }
            
            for (key, value) in dictionary {
                guard let translationArray = value["translation"],
                      let r_YArray = value["R_Y"] else {
                    print("Error: Missing keys in dictionary")
                    continue
                }
                
                let translationMatrix = simd_float4x4(rows: translationArray.map { simd_float4($0) })
                let r_YMatrix = simd_float4x4(rows: r_YArray.map { simd_float4($0) })
                
                let rotoTranslationMatrix = RotoTraslationMatrix(name: key, translation: translationMatrix, r_Y: r_YMatrix)
                
                self._associationMatrix[key] = rotoTranslationMatrix
            }
        } catch {
            print("Error loading JSON data: \(error)")
        }
    }
    
    func isMatrixPresent(named matrixName: String, inFileAt url: URL) -> Bool {
        do {
            let data = try Data(contentsOf: url)
            let json = try JSONSerialization.jsonObject(with: data, options: [])
            
            guard let matricesDict = json as? [String: [String: [[Double]]]] else {
                print("Il formato del file JSON non è corretto.")
                return false
            }
            
            return matricesDict[matrixName] != nil
            
        } catch {
            print("Errore durante la lettura del file JSON: \(error)")
            return false
        }
    }
    
    private func simd_float4(_ array: [Float]) -> simd_float4 {
        return simd.simd_float4(array[0], array[1], array[2], array[3])
    }
    
    private func simd_float4x4(rows: [simd_float4]) -> simd_float4x4 {
        return simd_float4x4(rows: rows)
    }
}
