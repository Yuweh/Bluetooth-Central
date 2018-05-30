//
//  ViewController.swift
//  Test01
//
//  Created by Jay Bergonia on 29/5/2018.
//  Copyright © 2018 Tektos Limited. All rights reserved.
//

import UIKit
import CoreBluetooth

class MainViewController: UIViewController, TransferServiceScannerDelegate {
    
    @IBOutlet weak var blueToothLabel: UILabel!
    @IBOutlet weak var tableView: UITableView!
    @IBOutlet weak var textView: UITextView!
    
    var centralManager: CBCentralManager!
    var scanner: TransferServiceScanner!
    var isBluetoothPoweredOn: Bool = false
    var isScanning: Bool = false

    
    override func viewDidLoad() {
        super.viewDidLoad()
        //tableView.delegate = self
        //tableView.dataSource = self
        centralManager = CBCentralManager(delegate: self, queue: nil)
        
    }
    
    
    @IBAction func SearchBtnPressed(_ sender: UIBarButtonItem) {

        if isScanning && isBluetoothPoweredOn {
            scanner.stopScan()
        } else if isScanning && !isBluetoothPoweredOn {
            self.showAlertSettings()
        } else  if !isScanning && isBluetoothPoweredOn {
            scanner.startScan()
        }
        
//        if !isBluetoothPoweredOn {
//            print("Turn Bluetooth On")
//            self.showAlertSettings()
//        } else {
//            print("Now Process")
//            self.startScan()
//        }
    }
    
    
    //Alert to Check if Bluetooth.isON
    func showAlertSettings() {
        let alert = UIAlertController(title: "Notice", message: "Please turn on your Bluetooth", preferredStyle: .alert)
        let Okay = UIAlertAction(title: "Ok", style: .default, handler: nil)
        alert.addAction(Okay)
    }
    
    
    //MARK: Func for TransferServiceScannerdDelegate
    func didStartScan() {
        textView.text = "Scanning ..."
        textView.textColor = UIColor.black
        isScanning = true
    }
    
    func didStopScan() {
        textView.text = ""
        isScanning = false
    }
    
    func didTransderData(data: NSData?) {
        textView.text = "\(String(describing: data))"
        textView.textColor = UIColor.black
        isScanning = false
    }

    
}

extension MainViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        switch (central.state) {
        case .poweredOn:
            blueToothLabel.text = "Bluetooth ON"
            isBluetoothPoweredOn = true
            break
        case .poweredOff:
            blueToothLabel.text = "Bluetooth OFF"
            blueToothLabel.textColor = UIColor.red
            isBluetoothPoweredOn = false
            break
        default:
            break
        }
    }
    
    
}

//extension MainViewController: UITableViewDelegate, UITableViewDataSource {
//
//    func numberOfSections(in tableView: UITableView) -> Int {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
//        <#code#>
//    }
//
//    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
//        <#code#>
//    }
//
//}

