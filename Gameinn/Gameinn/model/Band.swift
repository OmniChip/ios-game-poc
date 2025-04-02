//
//  Band.swift
//  Gameinn
//
//  Created by Sebastian Kroszka on 03/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

class Band: GameElement {
    var calibrationData: Any? = nil

    var peripheral: CBPeripheral
    var calibrator = Calibrator()
    var calibrationAvailable = true
    var calibrationWriteInProgress = false
    var calibrationState: UInt8 = 0

    var lastTimestamp: UInt64 = 0
    var startTimestamp: UInt64 = 0

    var listening = false

    /* now used as Band position */
    var association: Int = -1
    /* */

    var inertiaChatacteristic: CBCharacteristic? = nil
    var vibeCharacteristic: CBCharacteristic? = nil
    var timeSync: TimeSyncState? = nil
    private var bandDataList: [BandData] = []

    var lastData: BandData? {
        get {
            return bandDataList.first
        }
    }

    var currentTimeSyncState: SyncState = SyncState.initial

    required init(peripheral: CBPeripheral, mediator: Mediator?) {
        self.peripheral = peripheral
        super.init()
        self.mediator = mediator
        self.register()
        inertiaChatacteristic = self.peripheral.services?.first(where: { $0.uuid == inertiaService })?.characteristics?.first(where: { $0.uuid == inertiaDataCharacteristic })
        vibeCharacteristic = self.peripheral.services?.first(where: { $0.uuid == motorService })?.characteristics?.first(where: { $0.uuid == motorCharacteristic })
        let time = self.peripheral.services?.first(where: { $0.uuid == timeService })
        timeSync = TimeSyncState(timeService: time!)
        startListening()
    }


    func hasOwns(_ device: CBPeripheral) -> Bool {
        return self.peripheral.identifier == device.identifier
    }

    func updateData(_ data: BandData) {
        if self.bandDataList.count >= 30 {
            self.bandDataList.removeLast()
        }
        self.lastTimestamp = data.timestamp
        self.bandDataList.insert(data, at: 0)
    }

    func reset() {
        self.association = -1
        calibrator.destroy()
        self.lastTimestamp = 0
        self.startTimestamp = 0
    }

    func resetTS() {
        self.startTimestamp = self.lastTimestamp
    }

    func associationName() -> String {
        var playerID = "undefined"
        if let player = appDelegate?.game.getAssociatedPlayer(for: self) {
            playerID = "\(player.playerId)"
        }

        switch association {
        case 0:
            return "player \(playerID) left hand"
        case 1:
            return "player \(playerID) right hand"
        case 2:
            return "player \(playerID) left leg"
        case 3:
            return "player \(playerID) right leg"
        case 4:
            return "player \(playerID) torso"
        default:
            return "unused"
        }
    }


    var inertiaCalibrationStatus: String {
        get {
            if !calibrationAvailable {
                return "Not Available"
            } else if calibrationWriteInProgress {
                return "Pending"
            } else if !calibrator.isActive() {
                return "OK"
            } else {
                return calibrator.getStatusString()
            }
        }
    }

    var calibrationStatus: String {
        get {
            "TS: " + timeSyncStatus + " I: " + inertiaCalibrationStatus
        }
    }

    var timeSyncStatus: String {
        get {
            switch timeSync?.state {
            case nil:
                return "unavailable"
            case .modeMaster:
                return "master"
            case .modeSlave:
                return "slave"
            case .synced:
                return "synced"
            default:
                return ""
            }
        }
    }

    func restartTimesync() {
        let ts = timeSync
        if ts == nil {
            return
        }

        var restartState: SyncState
        if ts?.state == .initial {
            restartState = SyncState.initial
        } else {
            restartState = SyncState.stepNotifyOn
        }

        continueTimesync(state: restartState, result: 0)
    }

    func continueTimesync(state: SyncState, result: Int) {
        let ts = timeSync
        if ts == nil {
            return
        }
        if state == SyncState.synced && ts?.state != .modeSlave {
            return
        }
        ts?.state = state
        currentTimeSyncState = state
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) \(self.peripheral.name as! String) TimeSync moving to state \(state)" as AnyObject)
        if state == .initial {
            mediator?.send(command: .setCharacteristicNotifyEnable, sender: self, contextObject: (peripheral, ts?.tsSteps) as AnyObject)
            return
        }

        if state == .stepNotifyOn {
            let value = Data.init(repeating: UInt8(SyncType.disabled.rawValue), count: 1)
            mediator?.send(command: .writeValueToTimeCharacteristic, sender: self, contextObject: (peripheral, value, ts?.tsMode) as AnyObject)
        } else if state == .modeDisabled {
            mediator?.send(command: .readCharacteristicValue, sender: self, contextObject: (peripheral, ts?.tsSteps) as AnyObject)
        } else if state == .gotCounter {
            mediator?.send(command: .writeValueToTimeCharacteristic, sender: self, contextObject: (peripheral, appDelegate?.game.timesyncGroup, ts?.tsGroup) as AnyObject)
        } else if state == .groupSet {
            if appDelegate?.game.timingMaster != nil {
                currentTimeSyncState = .modeSlave
                let value = Data.init(repeating: UInt8(SyncType.slave.rawValue), count: 1)
                mediator?.send(command: .writeValueToTimeCharacteristic, sender: self, contextObject: (peripheral, value, ts?.tsMode) as AnyObject)
            } else {
                currentTimeSyncState = .modeMaster
                appDelegate?.game.timingMaster = self
                let value = Data.init(repeating: UInt8(SyncType.master.rawValue), count: 1)
                mediator?.send(command: .writeValueToTimeCharacteristic, sender: self, contextObject: (peripheral, value, ts?.tsMode) as AnyObject)
            }
        }
    }

//    var identity: String {
//        if let name = peripheral?.name, let identifier = peripheral?.identifier.uuidString {
//            return "\(name) \(identifier)"
//        } else {
//            return "Can't identify device"
//        }
//    }

    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if command == .timeStepNotifyEnabled {
            continueTimesync(state: .stepNotifyOn, result: 0)
        } else if command == .timeSyncCallback {
            if currentTimeSyncState == .stepNotifyOn {
                continueTimesync(state: .modeDisabled, result: 0)
            } else if currentTimeSyncState == .modeDisabled {
                timeSync?.updateTimeStepped()
                continueTimesync(state: .gotCounter, result: 0)
            } else if currentTimeSyncState == .gotCounter {
                continueTimesync(state: .groupSet, result: 0)
            } else if currentTimeSyncState == .modeSlave {
                continueTimesync(state: .modeSlave, result: 0)
                currentTimeSyncState = .initial
            } else if currentTimeSyncState == .modeMaster {
                continueTimesync(state: .modeMaster, result: 0)
                currentTimeSyncState = .initial
            } else if currentTimeSyncState == .initial {
                continueTimesync(state: .synced, result: 0)
            }
        }
    }

/* func writeCalibrationDone(zeroCharacteristic: CBCharacteristic, zeroData: Data, status: Int) {
    if status == 0 {
        calibrationWriteInProgress = false
        setupCalibration(data: zeroData)
    } else {
        peripheral.writeValue(zeroData, for: zeroCharacteristic, type: .withResponse)
    }
}

func setZeroOffset(data: Data?) {
    let zeroCharacteristic = peripheral.services?.first(where: { $0.uuid == inertiaService })?.characteristics?.first(where: { $0.uuid == inertiaZeroCharacteristic })
    var zeroData: Data? = nil
    if data != nil {
        zeroData = data!
    } else {
        zeroData = Data.init(repeating: UInt8(0), count: 12)
    }

    calibrationWriteInProgress = true
    peripheral.writeValue(zeroData!, for: zeroCharacteristic!, type: .withoutResponse)
}

func processCalibration(values: BandData) {
    if calibrator.process(values) {
        let zeroData = calibrator.getZeroOffset().getAxisData()
        calibrator.destroy()
        onCalibrationChange?(self)
        setZeroOffset(data: Data.init(zeroData))
    } else {
        let mask = calibrator.getCalibrationNeededMask()
        if calibrationState != mask {
            calibrationState = mask
            onCalibrationChange?(self)
        }
    }
}

func updateSensorData(data: Data) {
    let values = BandData(data: data)
    if calibrator.isActive() {
        processCalibration(values: values)
    }
    onNewData?(self, values)
}

func setupCalibration(data: Data?) {
    let isZero = data?.allSatisfy({ $0 == UInt8(0) })
    if isZero != calibrator.isActive() {
        if calibrator.isActive() {
            calibrator.destroy()
        } else {
            calibrator.create()
            calibrationState = calibrator.getCalibrationNeededMask()
        }
    }
    calibrationAvailable = data != nil
    onCalibrationChange?(self)
}

func resetCalibration() {
    if calibrator.isActive() {
        calibrator.destroy()
    }
    onCalibrationChange?(self)
    setZeroOffset(data: nil)
} */

    func cleanup() {
        stopListening()
        if calibrator.isActive() {
            calibrator.destroy()
        }
    }

    func triggerVibe(vibes: Data) {
        if vibes.count == 0 {
            return
        }
        if vibes.count > 8 {
            return
        }
        _ = vibeCharacteristic?.apply { characteristic in
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Band::triggerVibe, triggered vibe" as AnyObject)
            mediator?.send(command: .writeValueToVibeCharacteristic, sender: self, contextObject: (peripheral, vibes, characteristic) as AnyObject)
        }
    }

    func startListening() {
        if listening {
            return
        }
        mediator?.send(command: .setCharacteristicNotifyEnable, sender: self, contextObject: (peripheral, inertiaChatacteristic) as AnyObject)
        listening = true
    }

    func stopListening() {
        if !listening {
            return
        }
        mediator?.send(command: .setCharacteristicNotifyDisable, sender: self, contextObject: (peripheral, inertiaChatacteristic) as AnyObject)
        listening = false
    }
}
