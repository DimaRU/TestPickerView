//
//  CLLocationExtensions.swift
//  TestPickerView
//
//  Created by Dmitriy Borovikov on 07/04/2019.
//  Copyright © 2019 Dmitriy Borovikov. All rights reserved.
//

import Foundation
import CoreLocation
import ImageIO

extension CLLocation {
    func exifGPSMetadata(heading: CLHeading? = nil) -> NSMutableDictionary {
        
        let altitudeRef = Int(self.altitude < 0.0 ? 1 : 0)
        let latitudeRef = self.coordinate.latitude < 0.0 ? "S" : "N"
        let longitudeRef = self.coordinate.longitude < 0.0 ? "W" : "E"
        
        let gps = NSMutableDictionary()
        // GPS metadata
        gps[(kCGImagePropertyGPSLatitude as String)] = abs(coordinate.latitude)
        gps[(kCGImagePropertyGPSLongitude as String)] = abs(coordinate.longitude)
        gps[(kCGImagePropertyGPSLatitudeRef as String)] = latitudeRef
        gps[(kCGImagePropertyGPSLongitudeRef as String)] = longitudeRef
        gps[(kCGImagePropertyGPSAltitude as String)] = Int(abs(altitude))
        gps[(kCGImagePropertyGPSAltitudeRef as String)] = altitudeRef
        gps[(kCGImagePropertyGPSTimeStamp as String)] = timestamp.isoTime()
        gps[(kCGImagePropertyGPSDateStamp as String)] = timestamp.isoDate()
        gps[(kCGImagePropertyGPSVersion as String)] = "2.2.0.0"
        gps["HPositioningError"] = horizontalAccuracy

        // Speed, must be converted from m/s to km/h
        if speed >= 0 {
            gps[kCGImagePropertyGPSSpeedRef as String] = "K"
            gps[kCGImagePropertyGPSSpeed as String] = speed * 3.6
        }
        
        // Heading
        if course >= 0 {
            gps[kCGImagePropertyGPSTrackRef as String] = "T"
            gps[kCGImagePropertyGPSTrack as String] = course
        }
        
        if let heading = heading {
            gps[(kCGImagePropertyGPSImgDirection as String)] = heading.trueHeading
            gps[(kCGImagePropertyGPSImgDirectionRef as String)] = "T"
        }
        
        return gps
    }

    
    func location_accuracy(byAddingAccuracy horizontalError: CLLocationDistance) -> CLLocation {
        return CLLocation(coordinate: coordinate, altitude: altitude, horizontalAccuracy: CLLocationAccuracy(horizontalError), verticalAccuracy: verticalAccuracy, course: course, speed: speed, timestamp: timestamp)
    }
    
    
}
