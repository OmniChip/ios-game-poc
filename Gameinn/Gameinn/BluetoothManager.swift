import Foundation
import CoreBluetooth
import os.log
import UIKit

let deviceInformationService = CBUUID(string: "180A")

let batteryService = CBUUID(string: "180F")

let inertiaService = CBUUID(string: "1833")
let inertiaDataCharacteristic = CBUUID(string: "29fe")
let inertiaZeroCharacteristic = CBUUID(string: "29fd")

let timeService = CBUUID(string: "1805")
let timeGroupCharacteristic = CBUUID(string: "29fa")
let timeStepsCharacteristic = CBUUID(string: "29fb")
let timeModeCharacteristic = CBUUID(string: "29fc")

let motorService = CBUUID(string: "1844")
let motorCharacteristic = CBUUID(string: "29f0")

public let cccDescriptor = CBUUID(string: "2902")

class BluetoothManager: GameElement {
    var centralManager: CBCentralManager!
    var bands: [CBPeripheral]? = [CBPeripheral]()
    var counter = 0
    var player: Player? = nil

    private override init() {
        super.init()
        centralManager = CBCentralManager.init(delegate: self, queue: nil)
    }

    private static let sharedManager: BluetoothManager = {
        let manager = BluetoothManager()
        return manager
    }()

    class func shared() -> BluetoothManager {
        sharedManager
    }

    override func receive(command: MediatorCommands, sender: AnyObject, contextObject: AnyObject?) {
        if command == .setCharacteristicNotifyEnable {
            let data = contextObject as! (CBPeripheral, CBCharacteristic)
            data.0.setNotifyValue(true, for: data.1)
        } else if command == .setCharacteristicNotifyDisable {
            let data = contextObject as! (CBPeripheral, CBCharacteristic)
            data.0.setNotifyValue(false, for: data.1)
        } else if command == .writeValueToVibeCharacteristic {
            let data = contextObject as! (CBPeripheral, Data, CBCharacteristic)
            data.0.writeValue(data.1, for: data.2, type: .withoutResponse)
        } else if command == .writeValueToTimeCharacteristic {
            let data = contextObject as! (CBPeripheral, Data, CBCharacteristic)
            data.0.writeValue(data.1, for: data.2, type: .withResponse)
        } else if command == .readCharacteristicValue {
            let data = contextObject as! (CBPeripheral, CBCharacteristic)
            data.0.readValue(for: data.1)
        }
    }
}

extension BluetoothManager: CBCentralManagerDelegate {
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch central.state {
        case .unknown:
            print("central.state is .unknown")
        case .resetting:
            print("central.state is .resetting")
        case .unsupported:
            print("central.state is .unsupported")
        case .unauthorized:
            print("central.state is .unauthorized")
        case .poweredOff:
            print("central.state is .poweredOff")
        case .poweredOn:
            print("central.state is .poweredOn")
            startScanning()
        @unknown default:
            print("central.state is unknown")
        }
    }

    func startScanning() {
        if (centralManager.isScanning == false) {
            centralManager.scanForPeripherals(withServices: [inertiaService], options: nil)
            mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Scanning for band devices" as AnyObject)
        }
    }
    
    func stopScanning() {
        centralManager.stopScan()
    }

    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral,
                        advertisementData: [String: Any], rssi RSSI: NSNumber) {
        print("\(peripheral) \n")
        if !(bands?.contains(where: { $0.identifier == peripheral.identifier }) ?? false) {
            peripheral.delegate = self
            bands?.append(peripheral)
            centralManager.connect(peripheral, options: nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Connection with device (\(peripheral.identifier)) established" as AnyObject)
        mediator?.send(command: .bluetoothFoundNewDevice, sender: self, contextObject: peripheral)

        if peripheral.identifier == bands?.first(where: { $0.identifier == peripheral.identifier })?.identifier {
            peripheral.discoverServices(nil)
        }
    }

    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        appDelegate?.game.removeBand(peripheral)
        if let index = bands?.firstIndex(of: peripheral) {
            bands?.remove(at: index)
        }
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Failed to connect with device (\(peripheral.identifier))" as AnyObject)
        self.stopScanning()
        self.startScanning()
    }

    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
        appDelegate?.game.removeBand(peripheral)
        if let index = bands?.firstIndex(of: peripheral) {
            bands?.remove(at: index)
        }
        
        mediator?.send(command: .onBandPeripheralDisconnected, sender: self, contextObject: peripheral)
        mediator?.send(command: .logEvent, sender: self, contextObject: "\(Utility.currentDateToString()) Lost connection with device (\(peripheral.identifier))" as AnyObject)
        self.stopScanning()
        self.startScanning()
    }
}

extension BluetoothManager: CBPeripheralDelegate {
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        guard let services = peripheral.services else {
            return
        }
        for service in services {
            print(service)
            print("\(service.uuid.uuidString) \n")

            let serviceUUID = service.uuid.uuidString

            switch serviceUUID {
            case inertiaService.uuidString:
                peripheral.discoverCharacteristics([inertiaDataCharacteristic], for: service)
            case motorService.uuidString:
                peripheral.discoverCharacteristics([motorCharacteristic], for: service)
            case timeService.uuidString:
                peripheral.discoverCharacteristics([timeGroupCharacteristic, timeModeCharacteristic, timeStepsCharacteristic], for: service)
            default:
                os_log("")
            }
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        guard let characteristics = service.characteristics else {
            return
        }

        for characteristic in characteristics {
            print("discovered characteristic: \(characteristic)")

            if characteristic.uuid == inertiaDataCharacteristic || characteristic.uuid == timeStepsCharacteristic {
                peripheral.discoverDescriptors(for: characteristic)
            }

            if characteristic.uuid == motorCharacteristic {
                prepareAndAddBand(peripheral: peripheral)
            }
        }
    }

    func prepareAndAddBand(peripheral: CBPeripheral) {
        let band = Band(peripheral: peripheral, mediator: appDelegate?.gameMediator)
        appDelegate?.game.onFoundBand(band)
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverDescriptorsFor characteristic: CBCharacteristic, error: Error?) {
        guard let descriptors = characteristic.descriptors else {
            return
        }
        for descriptor in descriptors {
            if descriptor.uuid == cccDescriptor {
                print("for characteristic \(characteristic.uuid) descriptor: \(descriptor.uuid) \n")
            }
        }
    }

    public func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid == timeStepsCharacteristic {
            mediator?.send(command: .timeStepNotifyEnabled, sender: self, contextObject: peripheral as AnyObject)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if characteristic.uuid.uuidString == inertiaDataCharacteristic.uuidString {
            if let data = characteristic.value {
                let pair: (CBPeripheral, Data) = (peripheral, data)
                appDelegate?.game.onUpdateBandData(pair)
            }
        } else if characteristic.uuid == timeStepsCharacteristic {
            mediator?.send(command: .timeSyncCallback, sender: self, contextObject: peripheral as AnyObject)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didWriteValueFor characteristic: CBCharacteristic, error: Error?) {
        let result = error == nil ? "\(Utility.currentDateToString()) Successfully wrote value for characteristic \(characteristic.uuid.uuidString)" : "\(Utility.currentDateToString()) Writing value for characteristic \(characteristic.uuid.uuidString) ended with error"
        mediator?.send(command: .logEvent, sender: self, contextObject: result as AnyObject)
        if characteristic.uuid == timeModeCharacteristic || characteristic.uuid == timeGroupCharacteristic {
            mediator?.send(command: .timeSyncCallback, sender: self, contextObject: peripheral as AnyObject)
        }
    }
}

