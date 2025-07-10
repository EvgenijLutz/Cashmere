//
//  Color.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 04.03.25.
//

import CMPlatform


public extension PlatformColor {
    static func dynamic(_ regular: PlatformColor, _ dark: PlatformColor) -> PlatformColor {
#if os(macOS)
        return PlatformColor(name: nil) { appearance in
            switch appearance.name {
            case .aqua, .vibrantLight, .accessibilityHighContrastAqua, .accessibilityHighContrastVibrantLight:
                return regular
                
            default:
                return dark
            }
        }
#else
        return .init { collection in
            if collection.userInterfaceStyle == .dark {
                return dark
            }
            
            return regular
        }
#endif
    }
    
    
    static func dynamic(_ regularHex: String, _ darkHex: String) -> PlatformColor {
        .dynamic(.hex(regularHex), .hex(darkHex))
    }
    
}


public extension PlatformColor {
    static var invalid: PlatformColor {
        .rgba(1, 0, 1, 1)
    }
    
    
    static func hex(_ hex: String) -> PlatformColor {
        switch hex.lowercased() {
        case "none": return .invalid
        case "gray": return .rgba(0.5, 0.5, 0.5, 1)
        default: break
        }
        
        if hex.hasPrefix("#") {
            // #deadbeef
            let r, g, b, a: CGFloat
            
            let start = hex.index(hex.startIndex, offsetBy: 1)
            let hexColor = String(hex[start...])
            
            if hexColor.count == 8 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff000000) >> 24) / 255
                    g = CGFloat((hexNumber & 0x00ff0000) >> 16) / 255
                    b = CGFloat((hexNumber & 0x0000ff00) >> 8) / 255
                    a = CGFloat((hexNumber & 0x000000ff) >> 0) / 255
                    
                    return .rgba(r, g, b, a)
                }
            }
            else if hexColor.count == 6 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xff0000) >> 16) / 255
                    g = CGFloat((hexNumber & 0x00ff00) >> 8) / 255
                    b = CGFloat((hexNumber & 0x0000ff) >> 0) / 255
                    a = CGFloat(1)
                    
                    return .rgba(r, g, b, a)
                }
            }
            else if hexColor.count == 4 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xf000) >> 12) / 15
                    g = CGFloat((hexNumber & 0x0f00) >> 8) / 15
                    b = CGFloat((hexNumber & 0x00f0) >> 4) / 15
                    a = CGFloat((hexNumber & 0x000f) >> 0) / 15
                    
                    return .rgba(r, g, b, a)
                }
            }
            else if hexColor.count == 3 {
                let scanner = Scanner(string: hexColor)
                var hexNumber: UInt64 = 0
                
                if scanner.scanHexInt64(&hexNumber) {
                    r = CGFloat((hexNumber & 0xf00) >> 8) / 15
                    g = CGFloat((hexNumber & 0x0f0) >> 4) / 15
                    b = CGFloat((hexNumber & 0x00f) >> 0) / 15
                    a = CGFloat(1)
                    
                    return .rgba(r, g, b, a)
                }
            }
        }
        
        print("⚠️ Unknown color: \(hex)")
        return .invalid
    }
}


// I have loved you for the last time


public extension PlatformColor {
    static func rgba(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat, _ alpha: CGFloat) -> PlatformColor {
        return .init(red: red, green: green, blue: blue, alpha: alpha)
    }
    
    static func rgba(_ lightRed: CGFloat, _ lightGreen: CGFloat, _ lightBlue: CGFloat, _ lightAlpha: CGFloat,
                     _ darkRed: CGFloat, _ darkGreen: CGFloat, _ darkBlue: CGFloat, _ darkAlpha: CGFloat) -> PlatformColor {
        let light = PlatformColor.rgba(lightRed, lightGreen, lightBlue, lightAlpha)
        let dark = PlatformColor.rgba(darkRed, darkGreen, darkBlue, darkAlpha)
        
        return .adaptive(light, dark)
    }
    
    static func adaptive(_ light: PlatformColor, _ dark: PlatformColor) -> PlatformColor {
#if os(macOS)
        return PlatformColor(name: nil) { appearance in
            switch appearance.name {
            case .aqua,.vibrantLight, .accessibilityHighContrastAqua, .accessibilityHighContrastVibrantLight:
                light
            default: dark
            }
        }
#elseif os(iOS)
        return PlatformColor { traitCollection in
            if traitCollection.userInterfaceStyle == .light {
                light
            }
            else {
                dark
            }
        }
#endif
    }
}


public extension PlatformColor {
    func darken(by component: CGFloat) -> PlatformColor {
#if os(macOS)
        if let srgb = self.usingColorSpace(.sRGB) {
            var red = CGFloat(0)
            var green = CGFloat(0)
            var blue = CGFloat(0)
            var alpha = CGFloat(0)
            srgb.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
            
            let darkenedColor = PlatformColor(red: red * component, green: green * component, blue: blue * component, alpha: alpha)
            if let modified = darkenedColor.usingColorSpace(colorSpace) {
                return modified
            }
            return darkenedColor
        }
        
        print("⚠️ Warning: Could not convert \(self) to sRGB color space to darken it.")
        
        return .black
#else
        var red = CGFloat(0)
        var green = CGFloat(0)
        var blue = CGFloat(0)
        var alpha = CGFloat(0)
        getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        return .init(red: red * component, green: green * component, blue: blue * component, alpha: alpha)
#endif
    }
}
