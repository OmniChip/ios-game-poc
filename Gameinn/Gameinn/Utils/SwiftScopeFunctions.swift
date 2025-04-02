//
// Created by Sebastian Kroszka on 08/09/2020.
// Copyright (c) 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

@inline(__always) func run<R>(block: () -> R) -> R {
    return block()
}

protocol ScopeFunc {
}

extension ScopeFunc {

    @inline(__always) func `let`<R>(block: (Self) -> R) -> R {
        return block(self)
    }

    @inline(__always) func apply(block: (Self) -> ()) -> Self {
        block(self)
        return self
    }

    @inline(__always) func also(block: (Self) -> ()) -> Self {
        block(self)
        return self
    }

    @inline(__always) func takeIf(predicate: (Self) -> Bool) -> Self? {
        if (predicate(self)) {
            return self
        } else {
            return nil
        }
    }

    @inline(__always) func takeUnless(predicate: (Self) -> Bool) -> Self? {
        if (!predicate(self)) {
            return self
        } else {
            return nil
        }
    }

    @inline(__always) func `repeat`(times: Int, action: (Int) -> ()) -> () {
        for index in (0...times - 1) {
            action(index)
        }
    }
}

extension Data: ScopeFunc {
    public func `let`(block: (Data) -> ()) {
        return block(self)
    }
}

extension SyncState: ScopeFunc {
    public func `let`(block: (SyncState) -> ()) {
        return block(self)
    }
}

extension UInt64: ScopeFunc {
    public func `let`(block: (UInt64) -> ()) {
        return block(self)
    }
}

extension Player: ScopeFunc {
    @inline(__always) func apply(block: (Player) -> ()) -> Self {
        block(self)
        return self
    }
}

extension CBCharacteristic: ScopeFunc {
    @inline(__always) func apply(block: (CBCharacteristic) -> ()) -> Self {
        block(self)
        return self
    }
}
