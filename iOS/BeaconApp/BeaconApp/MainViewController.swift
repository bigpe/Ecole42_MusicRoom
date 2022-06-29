//
//  ViewController.swift
//  BeaconApp
//
//  Created by Антон Тропин on 22.06.2022.
//

import UIKit
import CoreLocation
import CoreBluetooth

class MainViewController: UIViewController, UITextFieldDelegate {
	
	@IBOutlet var switchButton: UIButton!
	@IBOutlet var bluetoothStatusLabel: UILabel!
	@IBOutlet var majorTF: UITextField!
	@IBOutlet var minorTF: UITextField!
	@IBOutlet var statusImage: UIImageView!

	let uuid = UUID(uuidString: "F34A1A1F-500F-48FB-AFAA-9584D641D7B1")!
	var beaconRegion: CLBeaconRegion!
	var bluetoothPeripheralManager: CBPeripheralManager!
	var dataDictionary = NSDictionary()
	var isBroadcasting = false

	override func viewDidLoad() {
		super.viewDidLoad()
		
		bluetoothPeripheralManager = CBPeripheralManager(delegate: self, queue: nil, options: nil)

		statusImage.image = UIImage(systemName: "dot.radiowaves.left.and.right")

		majorTF.textColor = UIColor.getImperialRed()
		minorTF.textColor = UIColor.getImperialRed()
		majorTF.text = "1"
		minorTF.text = "1"
		majorTF.delegate = self
		minorTF.delegate = self
		addDoneButtonOnNumpad(textFields: minorTF, majorTF)
		
		viewUpdate()
	}

	@IBAction func switchBroadcastingState() {
		if !isBroadcasting {
			if bluetoothPeripheralManager.state == .poweredOn {
				let major: CLBeaconMajorValue = UInt16(Int(majorTF.text ?? "1") ?? 1)
				let minor: CLBeaconMinorValue = UInt16(Int(minorTF.text ?? "1") ?? 1)
				beaconRegion = CLBeaconRegion(uuid: uuid, major: major, minor: minor, identifier: "musicRoom")
				dataDictionary = beaconRegion.peripheralData(withMeasuredPower: nil)
				bluetoothPeripheralManager.startAdvertising((dataDictionary as! [String : Any]))
				
				isBroadcasting = true
				viewUpdate()
			}
		} else {
			bluetoothPeripheralManager.stopAdvertising()
			
			isBroadcasting = false
			viewUpdate()
		}
	}

}



// MARK: - CBPeripheralManagerDelegate

extension MainViewController: CBPeripheralManagerDelegate {
	func peripheralManagerDidUpdateState(_ peripheral: CBPeripheralManager) {
		var statusMessage = ""
		
		switch peripheral.state {
			case .poweredOn:
				statusMessage = "Turned On"
			case .poweredOff:
				if isBroadcasting {
					switchBroadcastingState()
				}
				statusMessage = "Turned Off"
			case .resetting:
				statusMessage = "Resetting"
			case .unauthorized:
				statusMessage = "Not Authorized"
			case .unsupported:
				statusMessage = "Not Supported"
			default:
				statusMessage = "Unknown"
		}
		
		bluetoothStatusLabel.text = statusMessage
	}
}



// MARK: - UITextFieldDelegate

extension MainViewController: UITextViewDelegate {
	override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
		super.touchesBegan(touches, with: event)
		view.endEditing(true)
	}
	
	func textFieldShouldReturn(_ textField: UITextField) -> Bool {
		if textField == majorTF {
			minorTF.becomeFirstResponder()
		}
		return true
	}
}



// MARK: - Other Class Methods

extension MainViewController {
	func addDoneButtonOnNumpad(textFields: UITextField...) {
		for textField in textFields {
			let keypadToolbar: UIToolbar = UIToolbar()
			keypadToolbar.items=[
				UIBarButtonItem(barButtonSystemItem: UIBarButtonItem.SystemItem.flexibleSpace, target: self, action: nil),
				UIBarButtonItem(title: "Done", style: UIBarButtonItem.Style.done, target: textField, action: #selector(UITextField.resignFirstResponder)),
			]
			keypadToolbar.sizeToFit()
			textField.inputAccessoryView = keypadToolbar
		}
	}
	
	func viewUpdate() {
		if isBroadcasting {
			statusImage.tintColor = UIColor.getImperialRed()
			switchButton.configuration = .getStopConf()
			switchButton.setTitle("Stop", for: .normal)
			majorTF.isEnabled = false
			minorTF.isEnabled = false
			
		} else {
			statusImage.tintColor = .systemGray5
			switchButton.configuration = .getDefaultConf()
			switchButton.setTitle("Start", for: .normal)
			majorTF.isEnabled = true
			minorTF.isEnabled = true
		}
	}
}


// MARK: - UIColor

extension UIColor {
	static func getPrussianBlue() -> UIColor {
		UIColor(red: 29/225, green: 53/255, blue: 87/255, alpha: 1)
	}
	
	static func getCeladonBlue() -> UIColor {
		UIColor(red: 69/255, green: 123/255, blue: 157/255, alpha: 1)
	}
	
	static func getPowderBlue() -> UIColor {
		UIColor(red: 168/255, green: 218/255, blue: 220/255, alpha: 1)
	}
	
	static func getHoneydew() -> UIColor {
		UIColor(red: 241/255, green: 250/255, blue: 238/255, alpha: 1)
	}
	
	static func getImperialRed() -> UIColor {
		UIColor(red: 230/255, green: 57/255, blue: 70/255, alpha: 1)
	}
}



// MARK: - UIButton Configuration

extension UIButton.Configuration {
	public static func getDefaultConf() -> UIButton.Configuration {
		var custom = UIButton.Configuration.filled()
		custom.titlePadding = 8
		custom.buttonSize = .large
		custom.baseBackgroundColor = UIColor.getCeladonBlue()
		return custom
	}
	
	public static func getStopConf() -> UIButton.Configuration {
		var custom = UIButton.Configuration.filled()
		custom.titlePadding = 8
		custom.buttonSize = .large
		custom.baseBackgroundColor = UIColor.getImperialRed()
		return custom
	}
}
