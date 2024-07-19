//
//  AdjacentFloorsConnection.swift
//  ScanBuild
//
//  Created by Danil Lugli on 17/07/24.
//

import Foundation

class AdjacentFloorsConnection: Connection {
    private var _targetFloor: String
    private var _targetRoom: String
    
    init(name: String, targetFloor: String, targetRoom: String) {
        self._targetFloor = targetFloor
        self._targetRoom = targetRoom
        super.init(name: name)
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        _targetFloor = try container.decode(String.self, forKey: .targetFloor)
        _targetRoom = try container.decode(String.self, forKey: .targetRoom)
        let superDecoder = try container.superDecoder()
        try super.init(from: superDecoder)
    }
    
    var targetFloor: String {
        get {
            return _targetFloor
        }
        set {
            _targetFloor = newValue
        }
    }
    
    var targetRoom: String {
        get {
            return _targetRoom
        }
        set {
            _targetRoom = newValue
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case targetFloor
        case targetRoom
    }
}

