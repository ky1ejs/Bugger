//
//  Device.swift
//  Bugger
//
//  Created by Kyle McAlpine on 27/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import Foundation
import SystemConfiguration.CaptiveNetwork
import CoreTelephony

typealias KeyValue = (key: String, value: String)

struct Device {
    static var meta: [KeyValue] =  [
        (key: "Bundle ID",              value: bundleID),
        (key: "Version",                value: appVersion),
        (key: "Build",                  value: appBuild),
        (key: "OS",                     value: systemName),
        (key: "OS Version",             value: systemVersion),
        (key: "Device Model",           value: deviceModel),
        (key: "Device Orientation",     value: orientation),
        (key: "Device Locale",          value: locale),
        (key: "Device Date",            value: date),
        (key: "Battery Charge",         value: batteryLevel),
        (key: "Battery State",          value: batteryState),
        (key: "Screen Size",            value: screenSize),
        (key: "Screen Density",         value: screenDensity),
        (key: "Carrier Name",           value: carrierName),
        (key: "Carrier Connection",     value: carrierConnectionType),
        (key: "SSID",                   value: connectedWifiSSID),
        (key: "Memory Capacity",        value: memoryCapacity),
        (key: "Memory Used",            value: memoryUsed),
        (key: "Disk Capacity",          value: diskCapacity),
        (key: "Disk Used",              value: diskUsed)
    ]
    
    static var bundleID: String {
        return Bundle.main.infoDictionary?[String(kCFBundleIdentifierKey)] as? String ?? ""
    }
    
    static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    static var appBuild: String {
        return Bundle.main.infoDictionary?[String(kCFBundleVersionKey)] as? String ?? ""
    }
    
    static var systemName: String {
        return UIDevice.current.systemName
    }
    
    static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    static var deviceModel: String {
        return UIDevice.current.model
    }
    
    static var orientation: String {
        switch UIDevice.current.orientation {
        case .landscapeLeft:        return "Landscape Left"
        case .landscapeRight:       return "Landscape Right"
        case .portrait:             return "Portrait"
        case .portraitUpsideDown:   return "Portrait Upside Down"
        case .faceDown:             return "Face Down"
        case .faceUp:               return "Face Up"
        case .unknown:              return "Unknown"
        }
    }
    
    static var locale: String {
        return Locale.current.description
    }
    
    static var date: String {
        return String(describing: Date())
    }
    
    static var batteryLevel: String {
        return "\(UIDevice.current.batteryLevel)%"
    }
    
    static var batteryState: String {
        switch UIDevice.current.batteryState {
        case .charging:     return "Charging"
        case .full:         return "Full"
        case .unknown:      return "Unknown"
        case .unplugged:    return "Unplugged"
        }
    }
    
    static var screenSize: String {
        let screenSize = UIScreen.main.bounds.size
        return "\(screenSize.width) x \(screenSize.height)"
    }
    
    static var screenDensity: String {
        return String(describing: UIScreen.main.scale)
    }
    
    static var carrierName: String {
        return CTTelephonyNetworkInfo().subscriberCellularProvider?.carrierName ?? ""
    }
    
    static var carrierConnectionType: String {
        switch CTTelephonyNetworkInfo().currentRadioAccessTechnology {
        case CTRadioAccessTechnologyGPRS?,
             CTRadioAccessTechnologyEdge?,
             CTRadioAccessTechnologyCDMA1x?:        return "2G"
        case CTRadioAccessTechnologyWCDMA?,
             CTRadioAccessTechnologyHSDPA?,
             CTRadioAccessTechnologyHSUPA?,
             CTRadioAccessTechnologyCDMAEVDORev0?,
             CTRadioAccessTechnologyCDMAEVDORevA?,
             CTRadioAccessTechnologyCDMAEVDORevB?,
             CTRadioAccessTechnologyeHRPD?:         return "3G"
        case CTRadioAccessTechnologyLTE?:           return "4G"
        default:                                    return ""
        }
    }
    
    static var connectedWifiSSID: String {
        guard let supportedInterfaces = CNCopySupportedInterfaces() as? [CFString],
            let interface = supportedInterfaces.first,
            let unsafeInterfaceData = CNCopyCurrentNetworkInfo(interface),
            let interfaceData = unsafeInterfaceData as? Dictionary<String,AnyObject>,
            let ssid = interfaceData["SSID"] as? String
            else { return "" }
        return ssid
    }
    
    static var memoryCapacity: String {
        // .phsicalMemory is in bytes, convert to Mb
        return "\(ProcessInfo().physicalMemory / 1048576) Mb"
    }
    
    static var memoryUsed: String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? "\(info.resident_size) Mb" : ""
    }
    
    static var fileSystemAttributes: [FileAttributeKey : Any]? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let path = paths.last,
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path)
            else { return nil }
        return attrs
    }
    
    static var diskCapacity: String {
        guard let cap = fileSystemAttributes?[.systemSize] as? Int else { return  "" }
        return String(describing: cap / 1048576)
    }
    
    static var diskUsed: String {
        guard let used = fileSystemAttributes?[.systemFreeSize] as? Int else { return  "" }
        return String(describing: used / 1048576)
    }
}
