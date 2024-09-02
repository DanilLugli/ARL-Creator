import Foundation
import ARKit
import SceneKit
import SwiftUI

class Room: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {
    private var _id: UUID = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    @Published private var _referenceMarkers: [ReferenceMarker]
    @Published private var _transitionZones: [TransitionZone]
    @Published private var _sceneObjects: [SCNNode]
    @Published private var _scene: SCNScene?
    @Published private var _worldMap: ARWorldMap?
    private var _roomURL: URL
    @Published private var _color: UIColor
    
    init(name: String, lastUpdate: Date, referenceMarkers: [ReferenceMarker], transitionZones: [TransitionZone], sceneObjects: [SCNNode], scene: SCNScene?, worldMap: ARWorldMap?, roomURL: URL) {
        self._name = name
        self._lastUpdate = lastUpdate
        self._referenceMarkers = referenceMarkers
        self._transitionZones = transitionZones
        self._sceneObjects = sceneObjects
        self._scene = scene
        self._worldMap = worldMap
        self._roomURL = roomURL
        self._color = Room.randomColor().withAlphaComponent(0.3) // Genera un colore casuale con alpha 0.3
    }
    
    static func ==(lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id // Compara gli ID, o qualsiasi altra proprietà unica
    }
    
    var id: UUID {
        get {
            return _id
        }
    }
    
    var name: String {
        get {
            return _name
        }
        set {
            _name = newValue
        }
    }
    
    var lastUpdate: Date {
        get {
            return _lastUpdate
        }
    }
    
    var referenceMarkers: [ReferenceMarker] {
        get {
            return _referenceMarkers
        }set{
            _referenceMarkers = newValue
        }
    }
    
    var transitionZones: [TransitionZone] {
        get {
            return _transitionZones
        }
    }
    
    var sceneObjects: [SCNNode] {
        get {
            return _sceneObjects
        }
    }
    
    var scene: SCNScene? {
        get {
            return _scene
        }
    }
    
    var worldMap: ARWorldMap? {
        get {
            return _worldMap
        }
    }
    
    var roomURL: URL {
        get {
            return _roomURL
        }set{
            _roomURL = newValue
        }
    }
    
    var url: URL {
        get {
            return roomURL
        }
    }
    
    static func randomColor() -> UIColor {
        let red = CGFloat(arc4random_uniform(256)) / 255.0
        let green = CGFloat(arc4random_uniform(256)) / 255.0
        let blue = CGFloat(arc4random_uniform(256)) / 255.0
        return UIColor(red: red, green: green, blue: blue, alpha: 1.0)
    }
    
    
    // Implementazione personalizzata di Encodable
    private enum CodingKeys: String, CodingKey {
        case name
        case lastUpdate
        case referenceMarkersCount
        case transitionZonesCount
        case transitionZones
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(_name, forKey: .name)
        try container.encode(_lastUpdate, forKey: .lastUpdate)
        try container.encode(_referenceMarkers.count, forKey: .referenceMarkersCount)
        try container.encode(_transitionZones.count, forKey: .transitionZonesCount)
        try container.encode(_transitionZones, forKey: .transitionZones)
    }
    
    // JSON Serialization using Encodable
    func toJSON() -> String? {
        if let jsonData = try? JSONEncoder().encode(self) {
            return String(data: jsonData, encoding: .utf8)
        }
        return nil
    }
    
    func addReferenceMarker(referenceMarker: ReferenceMarker) {
        _referenceMarkers.append(referenceMarker)
    }
    
    func addTransitionZone(transitionZone: TransitionZone) throws {
        _transitionZones.append(transitionZone)
    }
    
    func deleteTransitionZone(transitionZone: TransitionZone) {
        _transitionZones.removeAll { $0.id == transitionZone.id }
    }
    
    // Nuovo metodo per ottenere tutte le connessioni
    func getConnections() -> [Connection] {
        return _transitionZones.compactMap { $0.connection }
    }
}

extension Room {
    func debugPrintRoom() {
        print("Room Debug Info:")
        print("-----------------------------")
        print("ID: \(_id)")
        print("Name: \(_name)")
        print("Last Update: \(_lastUpdate)")
        print("Room URL: \(_roomURL.path)")
        print("Reference Markers (\(_referenceMarkers.count)):")
        
        for marker in referenceMarkers {
            print("\tMarker ID: \(marker.id), Coordinates: \(marker.coordinates)")
        }
        
        print("Transition Zones (\(self.transitionZones.count)):")
        for zone in transitionZones {
            print("\tTransition Zone Name: \(zone.name), Area: \(zone.transitionArea)")
        }
        
        print("Scene Objects (\(self.sceneObjects.count)):")
        for object in sceneObjects {
            print("\tObject Name: \(object.name ?? "Unnamed Object")")
        }
        
        if let scene = scene {
            print("Scene: \(scene.debugDescription)")
        } else {
            print("Scene: None")
        }
        
        if let worldMap = worldMap {
            print("World Map: \(worldMap)")
        } else {
            print("World Map: None")
        }
        
        print("-----------------------------\n")
    }
}
