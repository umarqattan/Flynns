//
//  HomeViewController.swift
//  Flynns
//
//  Created by Umar Qattan on 12/2/18.
//  Copyright © 2018 ukaton. All rights reserved.
//

import UIKit
import CoreBluetooth

class HomeViewController: UIViewController {

    // bluetooth variables
    var centralManager: CBCentralManager?
    var peripherals = [CBPeripheral]()
    var rxCharacteristicLeft: CBCharacteristic?
    var rxCharacteristicRight: CBCharacteristic?
    var connectedPeripherals = Int(0)
    
    // demo variables
    var leftSensorArray:[Int] = [Int]()
    var rightSensorArray:[Int] = [Int]()
    var currentRotation = CGFloat(0)
    var currentValue = Float(0)
    
    // Flynns object
    var flynns: Flynns?
    
    private lazy var segmentedControl: UISegmentedControl = {
        let segmentedControl = UISegmentedControl(frame: .zero)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false
        segmentedControl.addTarget(self, action: #selector(updateUI(_:)), for: .valueChanged)
        segmentedControl.insertSegment(withTitle: "Rotate", at: 0, animated: true)
        segmentedControl.insertSegment(withTitle: "Scroll", at: 1, animated: true)
        segmentedControl.insertSegment(withTitle: "Pan", at: 2, animated: true)
        segmentedControl.apportionsSegmentWidthsByContent = false
        
        return segmentedControl
    }()
    
    private lazy var rotatingImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "ukaton"))
        imageView.frame = .zero
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private lazy var scrollView: UIScrollView = {
        let scrollView = UIScrollView(frame: .zero)
        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.isScrollEnabled = true
        
        return scrollView
    }()
    
    private lazy var qrImageView: UIImageView = {
        let imageView = UIImageView(image: UIImage(named: "qr"))
        imageView.frame = .zero
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.contentMode = .scaleAspectFit
        
        return imageView
    }()
    
    private lazy var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = -200
        slider.maximumValue = 200
        slider.isContinuous = true
        slider.setValue(0, animated: true)
        
        return slider
    }()
    
    private lazy var lowerRightLabel: UILabel =  {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .right
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body, compatibleWith: UIScreen.main.traitCollection)
        label.text = "Bottom Right"
        
        return label
    }()
    
    private lazy var upperRightLabel: UILabel =  {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .right
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body, compatibleWith: UIScreen.main.traitCollection)
        label.text = "Top Right"
        
        return label
    }()
    
    private lazy var lowerLeftLabel: UILabel =  {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.text = "Bottom Left"
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body, compatibleWith: UIScreen.main.traitCollection)
        
        return label
    }()
    
    private lazy var upperLeftLabel: UILabel =  {
        let label = UILabel(frame: .zero)
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .black
        label.numberOfLines = 0
        label.textAlignment = .left
        label.lineBreakMode = .byWordWrapping
        label.font = UIFont.preferredFont(forTextStyle: UIFont.TextStyle.body, compatibleWith: UIScreen.main.traitCollection)
        label.text = "Top Left"
        
        return label
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.setupViews()
        self.applyConstraints()
        self.addObservers()
        self.startManager()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.removeObservers()
    }
    
    func addObservers() {
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels(_:)), name: NSNotification.Name(rawValue: "NotifyLeft"), object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(updateLabels(_:)), name: NSNotification.Name(rawValue: "NotifyRight"), object: nil)
    }
    
    func removeObservers() {
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "NotifyLeft"), object: nil)
        NotificationCenter.default.removeObserver(self, name: NSNotification.Name(rawValue: "NotifyRight"), object: nil)
    }
    
    func setupFlynns() {
        self.flynns = Flynns(leftSensorValues: self.leftSensorArray, rightSensorValues: self.rightSensorArray)
    }
    
    func setupViews() {
        
        self.view.addSubview(self.segmentedControl)
        self.view.addSubview(self.lowerRightLabel)
        self.view.addSubview(self.upperRightLabel)
        self.view.addSubview(self.lowerLeftLabel)
        self.view.addSubview(self.upperLeftLabel)
        self.view.addSubview(self.slider)
    }
    
    func applyConstraints() {
        NSLayoutConstraint.activate([
            // segmentedControl constraints
            self.segmentedControl.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
            self.segmentedControl.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            self.segmentedControl.widthAnchor.constraint(equalToConstant: self.view.frame.width/2),
            
            // lowerRightLabel constraints
            self.lowerRightLabel.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.lowerRightLabel.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            
            // upperRightLabel constraints
            self.upperRightLabel.trailingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.trailingAnchor),
            self.upperRightLabel.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
            
            // lowerLeftLabel constraints
            self.lowerLeftLabel.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.lowerLeftLabel.bottomAnchor.constraint(equalTo: self.view.layoutMarginsGuide.bottomAnchor),
            
            // upperLeftLabel constraints
            self.upperLeftLabel.leadingAnchor.constraint(equalTo: self.view.layoutMarginsGuide.leadingAnchor),
            self.upperLeftLabel.topAnchor.constraint(equalTo: self.view.layoutMarginsGuide.topAnchor),
        ])
    }
}

extension HomeViewController: CBCentralManagerDelegate, CBPeripheralDelegate {
    
    func startManager() {
        print("Starting the central manager.")
        self.centralManager = CBCentralManager(delegate: self, queue: nil)
    }
    
    func centralManagerDidUpdateState(_ central: CBCentralManager) {
        
        print("The central manager updated state.")
        
        switch central.state {
        case .poweredOff:
            print("Powered Off")
        case .poweredOn:
            print("Powered On")
            print("Scanning...")
            self.centralManager?.scanForPeripherals(withServices: nil, options: nil)
        case .resetting:
            print("Resetting")
        case .unauthorized:
            print("Unauthorized")
        case .unsupported:
            print("Unsupported")
        case .unknown:
            print("Unknown")
        }
    }
    
    // Central Bluetooth manager discovered a peripheral
    func centralManager(_ central: CBCentralManager, didDiscover peripheral: CBPeripheral, advertisementData: [String : Any], rssi RSSI: NSNumber) {
        
        print("Looking for peripherals...")

        guard let name = peripheral.name else { return }
        
        print("Found peripheral named: \(name)")
        
        if name == "FLYNNS_LEFT" || name == "FLYNNS_RIGHT" {
            self.peripherals.append(peripheral)
            central.connect(
                peripheral,
                options: [CBConnectPeripheralOptionNotifyOnConnectionKey : true]
            )
        }
    }
    
    // Peripheral discovered characteristic(s) for service
    func peripheral(_ peripheral: CBPeripheral, didDiscoverCharacteristicsFor service: CBService, error: Error?) {
        
        print("Peripheral discovered characteristics for service: \(service)")
        
        guard let name = peripheral.name else { return }
        
        if let characteristics = service.characteristics {
            for characteristic in characteristics {
                print("Characteristic UUID: \(characteristic.uuid.uuidString)")
                peripheral.setNotifyValue(true, for: characteristic)
                peripheral.readValue(for: characteristic)
                
                if name == "FLYNNS_LEFT" {
                    self.rxCharacteristicLeft = characteristic
                } else if name == "FLYNNS_RIGHT" {
                    self.rxCharacteristicRight = characteristic
                }
            }
        } else if let error = error {
            print(error.localizedDescription)
        }
    }
    
    // Peripheral updated value for characteristic(s)
    func peripheral(_ peripheral: CBPeripheral, didUpdateValueFor characteristic: CBCharacteristic, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        } else {
            print("Updated value for characteristic: \(characteristic.uuid)")
            if let rxCharacteristicLeft = self.rxCharacteristicLeft, characteristic == rxCharacteristicLeft {
                if let value = characteristic.value, let asciiString = String(data: value, encoding: .utf8) {
                    print("Value received: \(asciiString).")
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: "NotifyLeft"),
                        object: nil,
                        userInfo: ["value_left": asciiString]
                    )
                }
            }
            
            if let rxCharacteristicRight = self.rxCharacteristicRight, characteristic == rxCharacteristicRight {
                if let value = characteristic.value, let asciiString = String(data: value, encoding: .utf8) {
                    print("Value received: \(asciiString).")
                    NotificationCenter.default.post(
                        name: NSNotification.Name(rawValue: "NotifyRight"),
                        object: nil,
                        userInfo: ["value_right": asciiString]
                    )
                }
            }
        }
    }
    
    // Peripheral
    func peripheral(_ peripheral: CBPeripheral, didUpdateNotificationStateFor characteristic: CBCharacteristic, error: Error?) {
        
        print("Updated notification state for characteristic: \(characteristic)")
        if let rxCharacteristicLeft = self.rxCharacteristicLeft, characteristic == rxCharacteristicLeft {
            if let value = characteristic.value, let asciiString = String(data: value, encoding: .utf8) {
                print("First left value received: \(asciiString).")
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "NotifyLeft"),
                    object: nil,
                    userInfo: ["value_left": asciiString]
                )
            }
        }
        
        if let rxCharacteristicRight = self.rxCharacteristicRight, characteristic == rxCharacteristicRight {
            if let value = characteristic.value, let asciiString = String(data: value, encoding: .utf8) {
                print("First right value received: \(asciiString).")
                NotificationCenter.default.post(
                    name: NSNotification.Name(rawValue: "NotifyRight"),
                    object: nil,
                    userInfo: ["value_right": asciiString]
                )
            }
        }
    
        if let error = error {
            print(error.localizedDescription)
        }
    }

    func peripheral(_ peripheral: CBPeripheral, didDiscoverServices error: Error?) {
        if let services = peripheral.services, let service = services.first {
            print("Peripheral discovered services.")
            print("Currently discovering characteristics for service: \(service)")
            peripheral.discoverCharacteristics(nil, for: service)
        } else if let error = error {
            print(error.localizedDescription)
        }
    }
    
    // Central manager connected to a peripheral. Stop scanning when connected to 2 peripherals
    // i.e., FLYNNS_LEFT and FLYNNS_RIGHT
    func centralManager(_ central: CBCentralManager, didConnect peripheral: CBPeripheral) {
        peripheral.delegate = self
        peripheral.discoverServices(nil)
        print("Connected to peripheral: \(String(describing: peripheral.name))")
        if self.peripherals.count == 2 {
            self.stopScan()
        }
    }
    
    // Central manager disconnected from a peripheral. Find the current peripheral amongst the cached peripherals and
    //
    func centralManager(_ central: CBCentralManager, didDisconnectPeripheral peripheral: CBPeripheral, error: Error?) {
    
        print("Attempting to disconnect from peripheral...")
        
        if let error = error {
            print(error.localizedDescription)
        } else {
            if self.peripherals.count != 0 {
                if let peripheralToDisconnect = self.peripherals.filter({$0 == peripheral}).first {
                    print("Disconnected from peripheral \(peripheral)")
                    peripheralToDisconnect.delegate = nil
                    self.peripherals = self.peripherals.filter({$0 != peripheral})
                }
            }
            self.startManager()
        }
    }
    
    func centralManager(_ central: CBCentralManager, didFailToConnect peripheral: CBPeripheral, error: Error?) {
        if let error = error {
            print(error.localizedDescription)
        }
    }

    func stopScan() {
        print("Central Manager stopped scanning for peripherals.")
        self.centralManager?.stopScan()
    }
}

extension HomeViewController {
    @objc func updateLabels(_ notification: Notification) {
        if let userInfo = notification.userInfo as? [String: String] {
            if let leftValue = userInfo["value_left"] {
                self.leftSensorArray = leftValue.components(separatedBy: ",").map({
                    if let component = Int($0) {
                        return component
                    } else {
                        return 0
                    }
                })
            } else if let rightValue = userInfo["value_right"] {
                self.rightSensorArray = rightValue.components(separatedBy: ",").map({
                    if let component = Int($0) {
                        return component
                    } else {
                        return 0
                    }
                })
            }
        
            
            if self.flynns == nil {
                self.flynns = Flynns(leftSensorValues: [0,0,0,0,0,0,0,0], rightSensorValues: [0,0,0,0,0,0,0,0])
            } else {
            
                self.flynns?.update(leftSensorValues: self.leftSensorArray, rightSensorValues: self.rightSensorArray)
            }
            //self.updateLabels(leftSensorArray: self.leftSensorArray, rightSensorArray: self.rightSensorArray)
            
//            flynns.updateLabels(
//                for: [
//                    self.lowerRightLabel,
//                    self.upperRightLabel,
//                    self.lowerLeftLabel,
//                    self.upperLeftLabel
//                ]
//            )
            
            switch self.segmentedControl.selectedSegmentIndex {
            case 0:
                self.flynns?.updateRotation(for: self.rotatingImageView)
                self.updateImageView(
                    leftSensorArray: self.leftSensorArray,
                    rightSensorArray: self.rightSensorArray
                )
                print("Rotate")
            case 1:
                self.flynns?.updateScroll(for: self.scrollView)
                
                self.updateScrollView(
                    leftSensorArray: self.leftSensorArray,
                    rightSensorArray: self.rightSensorArray
                )
                print("Scroll")
            case 2:
                flynns?.updateSlide(for: self.slider)
                self.updateSlider(
                    leftSensorArray: self.leftSensorArray,
                    rightSensorArray: self.rightSensorArray
                )
                print("Pan")
            default:
                print("Unknown")
            }
        }
        self.view.layoutIfNeeded()
    }
    
    @objc func updateUI(_ sender: UISegmentedControl) {
        
        switch sender.selectedSegmentIndex {
        case 0:
            self.rotateImageViewFeature(true)
            self.scrollViewFeature(false)
            self.panFeature(false)
            print("Rotate")
        case 1:
            self.rotateImageViewFeature(false)
            self.scrollViewFeature(true)
            self.panFeature(false)
            print("Scroll")
        case 2:
            self.rotateImageViewFeature(false)
            self.scrollViewFeature(false)
            self.panFeature(true)
            print("Pan")
        default:
            print("Unknown")
        }
        view.layoutIfNeeded()
    }
    
    func updateLabels(leftSensorArray: [Int], rightSensorArray: [Int]) {
        guard leftSensorArray.count == 8,
            rightSensorArray.count == 8 else { return }
        
        var bottomRightAverage: CGFloat = 0
        var topRightAverage: CGFloat = 0
        var bottomLeftAverage: CGFloat = 0
        var topLeftAverage: CGFloat = 0
        for i in 0..<8 {
            if i < 4 {
                bottomRightAverage += CGFloat(rightSensorArray[i]) / 8
                bottomLeftAverage += CGFloat(leftSensorArray[i]) / 8
            } else {
                topRightAverage += CGFloat(rightSensorArray[i]) / 8
                topLeftAverage += CGFloat(leftSensorArray[i]) / 8
            }
        }
        
        self.lowerRightLabel.text = "\(Int(bottomRightAverage))"
        self.upperRightLabel.text = "\(Int(topRightAverage))"
        self.lowerLeftLabel.text = "\(Int(bottomLeftAverage))"
        self.upperLeftLabel.text = "\(Int(topLeftAverage))"
    }
    
    // MARK: - ROTATION
    
    func updateImageView(leftSensorArray: [Int], rightSensorArray: [Int]) {
        guard leftSensorArray.count == 8,
            rightSensorArray.count == 8,
            leftSensorArray.reduce(0, +) > 25 || rightSensorArray.reduce(0, +) > 25 else { return }
        
        for i in 0..<8 {
            if i < 4 {
                self.currentRotation -= CGFloat(leftSensorArray[i] + rightSensorArray[7-i]) / 800 * 2 * .pi
            } else {
                self.currentRotation += CGFloat(leftSensorArray[i] + rightSensorArray[7-i]) / 800 * 2 * .pi
            }
        }
        self.rotatingImageView.transform = CGAffineTransform(rotationAngle: self.currentRotation)
    }
    
    // MARK: - SLIDER
    
    func updateSlider(leftSensorArray: [Int], rightSensorArray: [Int]) {
        guard leftSensorArray.count == 8,
            rightSensorArray.count == 8,
            leftSensorArray.reduce(0, +) > 25 || rightSensorArray.reduce(0, +) > 25 else { return }
        
        leftSensorArray.forEach({ self.currentValue -= Float($0) / 8 })
        rightSensorArray.forEach({ self.currentValue += Float($0) / 8})
        self.slider.setValue(self.currentValue, animated: true)
    }
    
    // MARK: - SCROLL VIEW
    func updateScrollView(leftSensorArray: [Int], rightSensorArray: [Int]) {
        guard leftSensorArray.count == 8,
            rightSensorArray.count == 8,
            leftSensorArray.reduce(0, +) > 25 || rightSensorArray.reduce(0, +) > 25 else { return }
        
        var newOffset: CGFloat = 0
        for i in 0..<rightSensorArray.count {
            newOffset -= CGFloat(leftSensorArray[i]) / 8
            newOffset += CGFloat(rightSensorArray[i]) / 8
        }
        
        var scrollBounds = self.scrollView.bounds
        scrollBounds.origin = CGPoint(x: self.scrollView.contentOffset.x, y: self.scrollView.contentOffset.y + newOffset)
        
        self.scrollView.bounds = scrollBounds
    }
    
    // MARK: - FEATURES
    
    func rotateImageViewFeature(_ enabled: Bool) {
        if enabled {
            self.view.addSubview(self.rotatingImageView)
            NSLayoutConstraint.activate([
                    self.rotatingImageView.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                    self.rotatingImageView.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                    self.rotatingImageView.widthAnchor.constraint(equalToConstant: self.view.frame.width/2),
                    self.rotatingImageView.heightAnchor.constraint(equalTo: self.view.widthAnchor)
            ])
        } else {
            guard self.rotatingImageView.constraints.count > 0 else { return }
            NSLayoutConstraint.deactivate(self.rotatingImageView.constraints)
            self.rotatingImageView.removeFromSuperview()
            self.view.layoutIfNeeded()
        }
        self.currentRotation = 0
    }
    
    func scrollViewFeature(_ enabled: Bool) {
        if enabled {
            self.view.addSubview(self.scrollView)
            self.scrollView.addSubview(self.qrImageView)
            NSLayoutConstraint.activate([
                    self.scrollView.leadingAnchor.constraint(equalTo: self.view.leadingAnchor),
                    self.scrollView.topAnchor.constraint(equalTo: self.segmentedControl.bottomAnchor),
                    self.scrollView.trailingAnchor.constraint(equalTo: self.view.trailingAnchor),
                    self.scrollView.bottomAnchor.constraint(equalTo: self.view.bottomAnchor),
                    self.qrImageView.widthAnchor.constraint(equalToConstant: self.view.frame.width / 2),
                    self.qrImageView.heightAnchor.constraint(equalTo: self.qrImageView.widthAnchor),
                    self.qrImageView.centerXAnchor.constraint(equalTo: self.scrollView.centerXAnchor),
                    self.qrImageView.centerYAnchor.constraint(equalTo: self.scrollView.centerYAnchor),
            ])
        } else {
            guard self.scrollView.constraints.count > 0 else { return }
            var constraints = [NSLayoutConstraint]()
            constraints += self.scrollView.constraints
            constraints += self.qrImageView.constraints
            NSLayoutConstraint.deactivate(constraints)
            self.qrImageView.removeFromSuperview()
            self.scrollView.removeFromSuperview()
            self.view.layoutIfNeeded()
        }
    }
    
    func panFeature(_ enabled: Bool) {
        if enabled {
            self.view.addSubview(self.slider)
            NSLayoutConstraint.activate([
                self.slider.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                self.slider.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                self.slider.widthAnchor.constraint(equalToConstant: self.view.frame.width * 0.75)
            ])
        } else {
            guard self.slider.constraints.count > 0 else { return }
            NSLayoutConstraint.deactivate(self.slider.constraints)
            self.slider.removeFromSuperview()
            self.view.layoutIfNeeded()
        }
    }
}
