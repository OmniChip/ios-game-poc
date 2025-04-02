//
// Created by Sebastian Kroszka on 08/09/2020.
// Copyright (c) 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

class TimeSyncState {
    var tsGroup: CBCharacteristic?
    var tsMode: CBCharacteristic?
    var tsSteps: CBCharacteristic?
    var supported: Bool {
        get {
            tsGroup != nil && tsMode != nil && tsSteps != nil && tsSteps?.descriptors?.first(where: { $0.uuid == cccDescriptor }) != nil
        }
    }
    var state = SyncState.initial
    var counter: UInt8 = 0
    var seq = 0

    init(timeService: CBService) {
        tsGroup = timeService.characteristics?.first(where: { $0.uuid == timeGroupCharacteristic})
        tsMode = timeService.characteristics?.first(where: { $0.uuid == timeModeCharacteristic})
        tsSteps = timeService.characteristics?.first(where: { $0.uuid == timeStepsCharacteristic})
    }

    func wrapCb( cb: @escaping (Int) -> Void) -> (Int) -> Void {
        let s = seq + 1
        return { (status: Int) -> Void in
            if s == self.seq {
                cb(status)
            }
        }
    }

    func updateTimeStepped() {
        tsSteps?.value?.let(block: { it in
            if it.count > 0 {
                counter = it[0]
            }
        })
    }
}

enum SyncType: UInt8 {
    case master = 2
    case slave = 1
    case disabled = 0
}

enum SyncState: Int {
    case initial = 0
    case stepNotifyOn = 1
    case modeDisabled = 2
    case gotCounter = 3
    case groupSet = 4
    case modeSlave = 5
    case synced = 6
    case modeMaster = 7
}
