//
//  LocationService.swift
//  OpenWeather
//
//  Created by Oleksandr Voropayev on 14.08.2023.
//

import Foundation
import CoreLocation
import Combine

protocol LocationService {
    typealias Location = (latitude: Double, longitude: Double)

    var location: Result<Location?, LocationError> { get }
    var locationPublisher: Published<Result<Location?, LocationError>>.Publisher { get }

    func start()
}

enum LocationError: Error {
    case permissionDenied
    case locationNotFound
}

final class LocationServiceImpl: NSObject, CLLocationManagerDelegate, LocationService {
    @Published private(set) var location: Result<Location?, LocationError> = .success(nil)
    var locationPublisher: Published<Result<Location?, LocationError>>.Publisher {
        $location
    }

    private let locationManager = CLLocationManager()

    init(desiredAccuracy: CLLocationAccuracy = kCLLocationAccuracyNearestTenMeters) {
        super.init()

        locationManager.delegate = self
        locationManager.desiredAccuracy = desiredAccuracy
    }

    func start() {
        if locationManager.authorizationStatus == .authorizedAlways ||
            locationManager.authorizationStatus == .authorizedWhenInUse {
            locationManager.requestLocation()
        } else {
            DispatchQueue.main.async {
                self.locationManager.requestWhenInUseAuthorization()
            }
        }
    }

    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        if let error = error as? CLError, error.code == .denied {
            location = .failure(.permissionDenied)
        } else {
            location = .failure(.locationNotFound)
        }
    }

    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        locations.first.map {
            location = .success(($0.coordinate.latitude, $0.coordinate.longitude))
        }
    }

    func locationManagerDidChangeAuthorization(_ manager: CLLocationManager) {
        switch manager.authorizationStatus {
        case .authorizedAlways,
             .authorizedWhenInUse:
            manager.requestLocation()
        case .denied,
             .notDetermined,
             .restricted:
            location = .failure(.permissionDenied)
        @unknown default:
            location = .failure(.permissionDenied)
        }
    }

}
