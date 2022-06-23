//
//  beaconTest.swift
//  music-room-ios
//
//  Created by Антон Тропин on 19.06.2022.
//

import Foundation
import Combine
import CoreLocation
import SwiftUI


class BeaconDetector: NSObject, ObservableObject, CLLocationManagerDelegate {
	var didChange = PassthroughSubject<Void, Never>()
	var locationManager: CLLocationManager?
	var lastDistance: CLProximity = .unknown
	
	override init() {
		super.init()
		
		locationManager = CLLocationManager()
		locationManager?.delegate = self
		locationManager?.requestWhenInUseAuthorization()
	}
	
	func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
		if manager.authorizationStatus == .authorizedWhenInUse {
			if CLLocationManager.isMonitoringAvailable(for: CLBeaconRegion.self) {
				if CLLocationManager.isRangingAvailable() {
					// let's go
				}
			}
		}
	}
	
	func startScanning() {
		let uuid = UUID(uuidString: "")
	}
}
