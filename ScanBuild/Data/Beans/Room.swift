import Foundation
import ARKit
import SceneKit
import SwiftUI

class Room: NamedURL, Encodable, Identifiable, ObservableObject, Equatable {
    private var _id: UUID = UUID()
    @Published private var _name: String
    private var _lastUpdate: Date
    @Published private var _planimetry: SCNViewContainer?
    @Published private var _referenceMarkers: [ReferenceMarker]
    @Published private var _transitionZones: [TransitionZone]
    @Published private var _scene: SCNScene?
    @Published private var _sceneObjects: [SCNNode]?
    private var _roomURL: URL
    @Published private var _color: UIColor
    
    init(_id: UUID = UUID(), _name: String, _lastUpdate: Date, _planimetry: SCNViewContainer? = nil, _referenceMarkers: [ReferenceMarker], _transitionZones: [TransitionZone], _scene: SCNScene? = SCNScene(), _sceneObjects: [SCNNode]? = nil, _roomURL: URL) {
        self._name = _name
        self._lastUpdate = _lastUpdate
        self._planimetry = _planimetry
        self._referenceMarkers = _referenceMarkers
        self._transitionZones = _transitionZones
        self._scene = _scene ?? SCNScene()
        self._sceneObjects = _sceneObjects
        self._roomURL = _roomURL
        self._color = Room.randomColor().withAlphaComponent(0.3)
    }
    
    static func ==(lhs: Room, rhs: Room) -> Bool {
        return lhs.id == rhs.id
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
    
    var scene: SCNScene? {
        get{
            return _scene
        }
        set{
            _scene = newValue
        }
    }
    
    var sceneObjects: [SCNNode]? {
        get {
            return _sceneObjects
        }
        set{
            _sceneObjects = newValue
        }
    }
    
    var roomURL: URL {
        get {
            return _roomURL
        }set{
            _roomURL = newValue
        }
    }
    
    var planimetry: SCNViewContainer {
        return _planimetry ?? SCNViewContainer()
    }
    
    var url: URL {
        get {
            return roomURL
        }
    }
    
    var color: UIColor{
        get{
            return _color
        }
        set{
            _color = newValue
        }
    }
    
    func hasConnections() -> Bool {
        return _transitionZones.contains { $0.connection != nil }
    }
    
    static func randomColor() -> UIColor {
        let colors: [UIColor] = [
            UIColor(red: 1.0, green: 0.35, blue: 0.0, alpha: 1.0),    // #FF5800
            UIColor(red: 1.0, green: 0.84, blue: 0.0, alpha: 1.0),    // #FFD700
            UIColor(red: 1.0, green: 0.27, blue: 0.0, alpha: 1.0),    // #FF4500
            UIColor(red: 0.0, green: 0.75, blue: 1.0, alpha: 1.0),    // #00BFFF
            UIColor(red: 0.13, green: 0.55, blue: 0.13, alpha: 1.0),  // #228B22
            UIColor(red: 0.42, green: 0.35, blue: 0.8, alpha: 1.0),   // #6A5ACD
            UIColor(red: 1.0, green: 0.41, blue: 0.71, alpha: 1.0),   // #FF69B4
            UIColor(red: 0.55, green: 0.27, blue: 0.07, alpha: 1.0),  // #8B4513
            UIColor(red: 0.87, green: 0.63, blue: 0.87, alpha: 1.0),  // #DDA0DD
            UIColor(red: 0.27, green: 0.51, blue: 0.71, alpha: 1.0)   // #4682B4
        ]
        
        return colors[Int(arc4random_uniform(UInt32(colors.count)))]
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
    
    func addTransitionZone(transitionZone: TransitionZone){
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
            print("\tTransition Zone Name: \(zone.name)")
        }
        
        print("Scene Objects (\(self.sceneObjects?.count)):")
        for object in sceneObjects! {
            print("\tObject Name: \(object.name ?? "Unnamed Object")")
        }
        
        print("-----------------------------\n")
    }
}
