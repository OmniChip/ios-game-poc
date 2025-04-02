//
//  GameMediator.swift
//  Gameinn
//
//  Created by Bartlomiej Burzec on 02/09/2020.
//  Copyright © 2020 Embiq. All rights reserved.
//

import Foundation
import CoreBluetooth

protocol Mediator: AnyObject {
    func send(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?)
    func register(participant: MediatorParticipant)
    func unregister(participant: MediatorParticipant)
}

class GameMediator: Mediator {
    var participants: [MediatorParticipant] = []

    /* Method used to receive command from mediator participants */
    func send(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        switch command {
        case .bluetoothFoundNewDevice:
            for participant in self.participants {
                if participant !== sender {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .bluetoothUpdateDeviceData:
            for participant in self.participants {
                if participant !== sender {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .setCharacteristicNotifyEnable:
            for participant in self.participants {
                if participant !== sender && participant is BluetoothManager {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .setCharacteristicNotifyDisable:
            for participant in self.participants {
                if participant !== sender && participant is BluetoothManager {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .timeStepNotifyEnabled:
            for participant in self.participants {
                if participant !== sender && participant is Band {
                    var band = participant as! Band
                    var data = contextObject as! CBPeripheral
                    if band.peripheral == data {
                        participant.receive(command: command, sender: sender, contextObject: contextObject)
                    }
                }
            }

        case .writeValueToVibeCharacteristic:
            for participant in self.participants {
                if participant !== sender && participant is BluetoothManager {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .writeValueToTimeCharacteristic:
            for participant in self.participants {
                if participant !== sender && participant is BluetoothManager {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .timeSyncCallback:
            for participant in self.participants {
                if participant !== sender && participant is Band {
                    var band = participant as! Band
                    var peripheral = contextObject as! CBPeripheral
                    if band.peripheral == peripheral {
                        participant.receive(command: command, sender: sender, contextObject: contextObject)
                    }
                }
            }

        case .readCharacteristicValue:
            for participant in self.participants {
                if participant !== sender && participant is BluetoothManager {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .startGame:
            for participant in self.participants {
                if participant !== sender && participant is Game {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .gestureDetected:
            for participant in self.participants {
                if participant !== sender && participant is Game {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .logEvent:
            for participant in self.participants {
                if participant !== sender && participant is GameBaseViewController {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .playExerciseSound:
            for participant in self.participants {
                if participant !== sender && participant is SoundPlayer {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .playPlayerWins:
            for participant in self.participants {
                if participant !== sender && participant is SoundPlayer {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .soundCompleted:
            for participant in self.participants {
                if participant !== sender && participant is Game {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }

        case .addBand:
            for participant in self.participants {
                if participant !== sender && participant is Game {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }
        default:
            for participant in self.participants {
                if participant !== sender {
                    participant.receive(command: command, sender: sender, contextObject: contextObject)
                }
            }
        }
    }

    func register(participant: MediatorParticipant) {
        if participants.contains(where: { $0 === participant }) == false {
            self.participants.append(participant)
        }
    }

    func unregister(participant: MediatorParticipant) {
        participants.removeAll(where: { $0 === participant })
    }
}
