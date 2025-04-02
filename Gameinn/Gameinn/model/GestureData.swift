//
//  GestureData.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 27/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation

@objcMembers
public class GestureData: NSObject {
    var timestamp: UInt64
    var type: Int
    var x: Float
    var y: Float
    var z: Float

    override init() {
        self.timestamp = 0
        self.type = 0
        self.x = 0
        self.y = 0
        self.z = 0
    }
}
