//
//  MediatorCommands.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 03/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation

enum MediatorCommands {
    case bluetoothFoundNewDevice
    case bluetoothUpdateDeviceData
    case setCharacteristicNotifyEnable
    case setCharacteristicNotifyDisable
    case timeStepNotifyEnabled
    case writeValueToVibeCharacteristic
    case writeValueToTimeCharacteristic
    case timeSyncCallback
    case readCharacteristicValue
    case startGame
    case gestureDetected
    case logEvent
    case playExerciseSound
    case playPlayerWins
    case soundCompleted
    case addBand
    case onBandsUpdated
    case onBandPeripheralDisconnected
}
