//
//  Device.swift
//  Bugger
//
//  Created by Kyle McAlpine on 27/10/2017.
//  Copyright © 2017 Kyle McAlpine. All rights reserved.
//

import UIKit
import CoreTelephony

public typealias KeyValue = (key: String, value: String)

@MainActor
public struct Device {
    public static var meta: [KeyValue] {
        [
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
            (key: "Memory Capacity",        value: memoryCapacity),
            (key: "Memory Used",            value: memoryUsed),
            (key: "Disk Capacity",          value: diskCapacity),
            (key: "Disk Used",              value: diskUsed)
        ]
    }
    
    public static var bundleID: String {
        return Bundle.main.infoDictionary?[String(kCFBundleIdentifierKey)] as? String ?? ""
    }
    
    public static var appVersion: String {
        return Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
    }
    
    public static var appBuild: String {
        return Bundle.main.infoDictionary?[String(kCFBundleVersionKey)] as? String ?? ""
    }
    
    public static var systemName: String {
        return UIDevice.current.systemName
    }
    
    public static var systemVersion: String {
        return UIDevice.current.systemVersion
    }
    
    public static var deviceModel: String {
        var systemInfo = utsname()
        uname(&systemInfo)
        let machineMirror = Mirror(reflecting: systemInfo.machine)
        let identifier = machineMirror.children.reduce("") { identifier, element in
            guard let value = element.value as? Int8, value != 0 else { return identifier }
            return identifier + String(UnicodeScalar(UInt8(value)))
        }
        
        switch identifier {
        // iPhone
        case "iPhone8,4":                                   return "iPhone SE"
        case "iPhone10,1", "iPhone10,4":                    return "iPhone 8"
        case "iPhone10,2", "iPhone10,5":                    return "iPhone 8 Plus"
        case "iPhone10,3", "iPhone10,6":                    return "iPhone X"
        case "iPhone11,2":                                  return "iPhone XS"
        case "iPhone11,4", "iPhone11,6":                    return "iPhone XS Max"
        case "iPhone11,8":                                  return "iPhone XR"
        case "iPhone12,1":                                  return "iPhone 11"
        case "iPhone12,3":                                  return "iPhone 11 Pro"
        case "iPhone12,5":                                  return "iPhone 11 Pro Max"
        case "iPhone12,8":                                  return "iPhone SE (2nd generation)"
        case "iPhone13,1":                                  return "iPhone 12 mini"
        case "iPhone13,2":                                  return "iPhone 12"
        case "iPhone13,3":                                  return "iPhone 12 Pro"
        case "iPhone13,4":                                  return "iPhone 12 Pro Max"
        case "iPhone14,4":                                  return "iPhone 13 mini"
        case "iPhone14,5":                                  return "iPhone 13"
        case "iPhone14,2":                                  return "iPhone 13 Pro"
        case "iPhone14,3":                                  return "iPhone 13 Pro Max"
        case "iPhone14,6":                                  return "iPhone SE (3rd generation)"
        case "iPhone14,7":                                  return "iPhone 14"
        case "iPhone14,8":                                  return "iPhone 14 Plus"
        case "iPhone15,2":                                  return "iPhone 14 Pro"
        case "iPhone15,3":                                  return "iPhone 14 Pro Max"
        case "iPhone15,4":                                  return "iPhone 15"
        case "iPhone15,5":                                  return "iPhone 15 Plus"
        case "iPhone16,1":                                  return "iPhone 15 Pro"
        case "iPhone16,2":                                  return "iPhone 15 Pro Max"
        case "iPhone17,1":                                  return "iPhone 16 Pro"
        case "iPhone17,2":                                  return "iPhone 16 Pro Max"
        case "iPhone17,3":                                  return "iPhone 16"
        case "iPhone17,4":                                  return "iPhone 16 Plus"
        // iPad
        case "iPad7,11", "iPad7,12":                        return "iPad (7th generation)"
        case "iPad11,6", "iPad11,7":                        return "iPad (8th generation)"
        case "iPad12,1", "iPad12,2":                        return "iPad (9th generation)"
        case "iPad13,18", "iPad13,19":                      return "iPad (10th generation)"
        case "iPad11,1", "iPad11,2":                        return "iPad mini (5th generation)"
        case "iPad14,1", "iPad14,2":                        return "iPad mini (6th generation)"
        case "iPad11,3", "iPad11,4":                        return "iPad Air (3rd generation)"
        case "iPad13,1", "iPad13,2":                        return "iPad Air (4th generation)"
        case "iPad13,16", "iPad13,17":                      return "iPad Air (5th generation)"
        case "iPad14,8", "iPad14,9":                        return "iPad Air 11-inch (M2)"
        case "iPad14,10", "iPad14,11":                      return "iPad Air 13-inch (M2)"
        case "iPad8,1", "iPad8,2", "iPad8,3", "iPad8,4":    return "iPad Pro 11-inch"
        case "iPad8,9", "iPad8,10":                         return "iPad Pro 11-inch (2nd generation)"
        case "iPad13,4", "iPad13,5", "iPad13,6", "iPad13,7": return "iPad Pro 11-inch (3rd generation)"
        case "iPad14,3", "iPad14,4":                        return "iPad Pro 11-inch (4th generation)"
        case "iPad16,3", "iPad16,4":                        return "iPad Pro 11-inch (M4)"
        case "iPad8,5", "iPad8,6", "iPad8,7", "iPad8,8":    return "iPad Pro 12.9-inch (3rd generation)"
        case "iPad8,11", "iPad8,12":                        return "iPad Pro 12.9-inch (4th generation)"
        case "iPad13,8", "iPad13,9", "iPad13,10", "iPad13,11": return "iPad Pro 12.9-inch (5th generation)"
        case "iPad14,5", "iPad14,6":                        return "iPad Pro 12.9-inch (6th generation)"
        case "iPad16,5", "iPad16,6":                        return "iPad Pro 13-inch (M4)"
        // Apple TV
        case "AppleTV5,3":                                  return "Apple TV HD"
        case "AppleTV6,2":                                  return "Apple TV 4K"
        case "AppleTV11,1":                                 return "Apple TV 4K (2nd generation)"
        case "AppleTV14,1":                                 return "Apple TV 4K (3rd generation)"
        // Apple Silicon Macs (Catalyst)
        case "Mac14,2":                                     return "MacBook Air (M2, 2022)"
        case "Mac14,15":                                    return "MacBook Air (15-inch, M2, 2023)"
        case "Mac15,12":                                    return "MacBook Air (13-inch, M3, 2024)"
        case "Mac15,13":                                    return "MacBook Air (15-inch, M3, 2024)"
        case "Mac14,7":                                     return "MacBook Pro (13-inch, M2, 2022)"
        case "Mac14,5", "Mac14,9":                          return "MacBook Pro (14-inch, 2023)"
        case "Mac14,6", "Mac14,10":                         return "MacBook Pro (16-inch, 2023)"
        case "Mac15,3":                                     return "MacBook Pro (14-inch, M3, 2023)"
        case "Mac15,6", "Mac15,8", "Mac15,10":              return "MacBook Pro (14-inch, M3 Pro/Max, 2023)"
        case "Mac15,7", "Mac15,9", "Mac15,11":              return "MacBook Pro (16-inch, M3 Pro/Max, 2023)"
        case "Mac14,3":                                     return "Mac mini (M2, 2023)"
        case "Mac14,12":                                    return "Mac mini (M2 Pro, 2023)"
        case "Mac16,10", "Mac16,11":                        return "Mac mini (M4, 2024)"
        case "Mac14,13", "Mac14,14":                        return "Mac Studio (M2 Max/Ultra, 2023)"
        case "Mac13,1":                                     return "Mac Studio (M1 Max, 2022)"
        case "Mac13,2":                                     return "Mac Studio (M1 Ultra, 2022)"
        case "arm64":                                       return "Simulator (Apple Silicon)"
        case "i386", "x86_64":                              return "Simulator (Intel)"
        default:                                            return identifier
        }
    }
    
    public static var orientation: String {
        switch UIDevice.current.orientation {
        case .landscapeLeft:        return "Landscape Left"
        case .landscapeRight:       return "Landscape Right"
        case .portrait:             return "Portrait"
        case .portraitUpsideDown:   return "Portrait Upside Down"
        case .faceDown:             return "Face Down"
        case .faceUp:               return "Face Up"
        case .unknown:              fallthrough
        @unknown default:           return "Unknown"
        }
    }
    
    public static var locale: String {
        return Locale.current.description
    }
    
    public static var date: String {
        return String(describing: Date())
    }
    
    public static var batteryLevel: String {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let level = "\(Int(device.batteryLevel * 100))%"
        device.isBatteryMonitoringEnabled = false
        return level
    }
    
    public static var batteryState: String {
        let device = UIDevice.current
        device.isBatteryMonitoringEnabled = true
        let state: String = {
            switch device.batteryState {
            case .charging:     return "Charging"
            case .full:         return "Full"
            case .unplugged:    return "Unplugged"
            case .unknown:      fallthrough
            @unknown default:   return "Unknown"
            }
        }()
        device.isBatteryMonitoringEnabled = false
        return state
    }
    
    public static var screenSize: String {
        let screenSize = UIScreen.main.bounds.size
        return "\(screenSize.width) x \(screenSize.height)"
    }
    
    public static var screenDensity: String {
        return String(describing: UIScreen.main.scale)
    }
    
    public static var carrierName: String {
        return CTTelephonyNetworkInfo().serviceSubscriberCellularProviders?
            .values
            .map { $0.description }
            .joined(separator: ", ") ?? ""
    }
    
    public static var carrierConnectionType: String {
        return CTTelephonyNetworkInfo().serviceCurrentRadioAccessTechnology?
            .values
            .joined(separator: ", ") ?? ""
    }
    
    public static var memoryCapacity: String {
        return "\(Int(ProcessInfo().physicalMemory).bytesToMegaBytes()) MB"
    }
    
    public static var memoryUsed: String {
        var info = mach_task_basic_info()
        var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size) / 4
        let kerr: kern_return_t = withUnsafeMutablePointer(to: &info) {
            $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
            }
        }
        return kerr == KERN_SUCCESS ? "\(Int(info.resident_size).bytesToMegaBytes()) MB" : ""
    }
    
    public static var fileSystemAttributes: [FileAttributeKey : Any]? {
        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        guard let path = paths.last,
            let attrs = try? FileManager.default.attributesOfFileSystem(forPath: path)
            else { return nil }
        return attrs
    }
    
    public static var diskCapacity: String {
        guard let cap = fileSystemAttributes?[.systemSize] as? Int else { return  "" }
        return "\(cap.bytesToGigaBytes()) GB"
    }
    
    public static var diskUsed: String {
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
