//
//  TransferServiceScanner.swift
//  Test01
//
//  Created by Jay Bergonia on 29/5/2018.
//  Copyright © 2018 Tektos Limited. All rights reserved.
//

import CoreBluetooth

protocol TransferServiceScannerDelegate: NSObjectProtocol {
    func didStartScan()
    func didStopScan()
    func didTransderData(data: NSData?)
    
}


class TransferServiceScanner: NSObject, CBCentralManagerDelegate, CBPeripheralDelegate {

    var centralManager: CBCentralManager!
    var discoveredPeripheral: CBPeripheral?
    var data: NSMutableData = NSMutableData()
    weak var delegate: TransferServiceScannerDelegate?
 
    init(delegate: TransferServiceScannerDelegate?) {
        super.init()
        centralManager = CBCentralManager(delegate: self, queue: nil)
        self.delegate = delegate
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            print("CentralManager.isON")
            break
        case .poweredOff:
            print("CentralManager.isOFF")
            break
        default:
            print("CentralManager changed state \(central.state)")
            break
        }
    }
    
    //MARK: TransferServiceScanner startScanMethod
    func startScan() {
        let services = [CBUUID(string: kTransferServiceUUID)]
        let options = Dictionary(dictionaryLiteral:(CBCentralManagerScanOptionAllowDuplicatesKey, false))
        centralManager.scanForPeripherals(withServices: services, options: options)
        delegate?.didStartScan()
        
    }
    
    func stopScan() {
        print("Stop scan")
        centralManager.stopScan()
        delegate?.didStopScan()
    }
    
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        // reject if above reasonable range, or too low
        if (RSSI.intValue > -15) || (RSSI.intValue < -35) {
            print("not in range, RSSI is \(RSSI.intValue)")
            return; }
        if (discoveredPeripheral != peripheral) {
            discoveredPeripheral = peripheral
            print("connecting to peripheral \(peripheral)")
            centralManager.connect(peripheral, options: nil)
        }
    }
    
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        stopScan()
        data.length = 0
        peripheral.delegate = self
        peripheral.discoverServices([CBUUID(string: kTransferServiceUUID)])
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        print("didFailToConnectPeripheral")
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        // look for the characteristics we want
        for service in peripheral.services! {
            peripheral.discoverCharacteristics([CBUUID(string: kTransferCharacteristicUUID)], for: service)
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        // loop through and verify the characteristic is the correct one, then subscribe to it
        let cbuuid = CBUUID(string: kTransferCharacteristicUUID)
        for characteristic in service.characteristics! {
            print("characteristic.UUID is \(characteristic.uuid)")
            if characteristic.uuid == cbuuid {
                peripheral.setNotifyValue(true, for: characteristic)
            }
        }
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        let stringFromData = NSString(data: characteristic.value!, encoding:
            String.Encoding.utf8.rawValue)
        print("received \(String(describing: stringFromData))")
        if stringFromData == "EOM" {
            
            // data transfer is complete, so notify delegate
            delegate?.didTransderData(data: data)
            
            // unsubscribe from characteristic
            peripheral.setNotifyValue(false, for: characteristic)
            
            // disconnect from peripheral
            centralManager.cancelPeripheralConnection(peripheral)
        }
        data.append(characteristic.value!)
    }
    
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        if (error != nil) {
            print("Encountered error: \(error!.localizedDescription)")
            return
        }
        if characteristic.uuid != CBUUID(string: kTransferCharacteristicUUID) {
            return
        }
        if characteristic.isNotifying {
            print("notification started for \(characteristic)")
        } else {
            print("notification stopped for \(characteristic), disconnecting...")
            centralManager.cancelPeripheralConnection(peripheral)
        }
    }
}
