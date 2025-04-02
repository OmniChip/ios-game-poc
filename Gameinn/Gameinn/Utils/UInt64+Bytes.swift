//
// Created by Sebastian Kroszka on 24/09/2020.
// Copyright (c) 2020 Embiq. All rights reserved.
//

import Foundation

extension UInt64 {
    func listOfBytes(mask: UInt64) -> Array<Int> {
        var seq = Array<Int>()
        var v = mask
        var i = 0
        while v != UInt64(0) {
            if v & UInt64(1) != UInt64(0) {
                seq.append(i)
            }
            v = v >> 1
            i += 1
        }
        return seq
    }
}