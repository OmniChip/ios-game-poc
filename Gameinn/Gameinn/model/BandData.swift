//
//  BandData.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 27/08/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation

@objcMembers
public class BandData: NSObject {
    var ax: Int
    var ay: Int
    var az: Int
    var gx: Int
    var gy: Int
    var gz: Int
    var timestamp: UInt64

    override init() {
        self.ax = 0
        self.ay = 0
        self.az = 0
        self.gx = 0
        self.gy = 0
        self.gz = 0
        self.timestamp = 0
    }

    init(data: Data) {
        let gx = Int(UInt16(data[5]) << 8 | UInt16(data[4]))
        self.gx = gx > 0x7fff ? (gx - 0x10000) : gx
        let gy = Int(UInt16(data[7]) << 8 | UInt16(data[6]))
        self.gy = gy > 0x7fff ? (gy - 0x10000) : gy
        let gz = Int(UInt16(data[9]) << 8 | UInt16(data[8]))
        self.gz = gz > 0x7fff ? (gz - 0x10000) : gz
        let ax = Int(UInt16(data[11]) << 8 | UInt16(data[10]))
        self.ax = ax > 0x7fff ? (ax - 0x10000) : ax
        let ay = Int(UInt16(data[13]) << 8 | UInt16(data[12]))
        self.ay = ay > 0x7fff ? (ay - 0x10000) : ay
        let az = Int(UInt16(data[15]) << 8 | UInt16(data[14]))
        self.az = az > 0x7fff ? (az - 0x10000) : az
        let timestamp = UInt64(data[3]) << 24 | UInt64(data[2]) << 16 | UInt64(data[1]) << 8 | UInt64(data[0])
        self.timestamp = timestamp
    }

    func getAxisData() -> [UInt8] {
        let buf = ByteBuffer.init(size: 12)
        _ = buf.order(.little)
        _ = buf.put(Int16(self.gx))
        _ = buf.put(Int16(self.gy))
        _ = buf.put(Int16(self.gz))
        _ = buf.put(Int16(self.ax))
        _ = buf.put(Int16(self.ay))
        _ = buf.put(Int16(self.az))
        return buf.getArray()
    }
}
