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
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        case "iPod5,1":                                     return "iPod Touch 5"
        case "iPod7,1":                                     return "iPod Touch 6"
        case "iPhone3,1", "iPhone3,2", "iPhone3,3":         return "iPhone 4"
        case "iPhone4,1":                                   return "iPhone 4s"
        case "iPhone5,1", "iPhone5,2":                      return "iPhone 5"
        case "iPhone5,3", "iPhone5,4":                      return "iPhone 5c"
        case "iPhone6,1", "iPhone6,2":                      return "iPhone 5s"
        case "iPhone7,2":                                   return "iPhone 6"
        case "iPhone7,1":                                   return "iPhone 6 Plus"
        case "iPhone8,1":                                   return "iPhone 6s"
        case "iPhone8,2":                                   return "iPhone 6s Plus"
        case "iPhone9,1", "iPhone9,3":                      return "iPhone 7"
        case "iPhone9,2", "iPhone9,4":                      return "iPhone 7 Plus"
        case "iPhone8,4":                                   return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                    return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                    return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                    return "iPhone X"
        case "iPad2,1", "iPad2,2", "iPad2,3", "iPad2,4":    return "iPad 2"
        case "iPad3,1", "iPad3,2", "iPad3,3":               return "iPad 3"
        case "iPad3,4", "iPad3,5", "iPad3,6":               return "iPad 4"
        case "iPad4,1", "iPad4,2", "iPad4,3":               return "iPad Air"
        case "iPad5,3", "iPad5,4":                          return "iPad Air 2"
        case "iPad6,11", "iPad6,12":                        return "iPad 5"
        case "iPad2,5", "iPad2,6", "iPad2,7":               return "iPad Mini"
        case "iPad4,4", "iPad4,5", "iPad4,6":               return "iPad Mini 2"
        case "iPad4,7", "iPad4,8", "iPad4,9":               return "iPad Mini 3"
        case "iPad5,1", "iPad5,2":                          return "iPad Mini 4"
        case "iPad6,3", "iPad6,4":                          return "iPad Pro 9.7 Inch"
        case "iPad6,7", "iPad6,8":                          return "iPad Pro 12.9 Inch"
        case "iPad7,1", "iPad7,2":                          return "iPad Pro 12.9 Inch 2. Generation"
        case "iPad7,3", "iPad7,4":                          return "iPad Pro 10.5 Inch"
        case "AppleTV5,3":                                  return "Apple TV"
        case "AppleTV6,2":                                  return "Apple TV 4K"
        case "AudioAccessory1,1":                           return "HomePod"
        case "i386", "x86_64":                              return "Simulator"
        default:                                            return identifier
        }
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
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = "\(Int(device.batteryLevel * 100))%"
        device.isBatteryMonitoringEnabled = false
        return level
    }
    
    static var batteryState: String {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let state: String = {
            switch device.batteryState {
            case .charging:     return "Charging"
            case .full:         return "Full"
            case .unknown:      return "Unknown"
            case .unplugged:    return "Unplugged"
            }
        }()
        device.isBatteryMonitoringEnabled = false
        return state
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
        return "\(Int(ProcessInfo().physicalMemory).bytesToMegaBytes()) MB"
    }
    
    static var memoryUsed: String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? "\(Int(info.resident_size).bytesToMegaBytes()) MB" : ""
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
        return "\(cap.bytesToGigaBytes()) GB"
    }
    
    static var diskUsed: String {
        guard let used = fileSystemAttributes?[.systemFreeSize] as? Int else { return  "" }
        return "\(used.bytesToGigaBytes()) GB"
    }
}

private extension Int {
    func bytesToMegaBytes() -> Float {
        let bytesInMegaBytes: Float  = 1048576
        return Float(self) / bytesInMegaBytes
    }
    
    func bytesToGigaBytes() -> Float {
        let bytesInGigaBytes: Float  = 1073741824
        return Float(self) / bytesInGigaBytes
    }
}
