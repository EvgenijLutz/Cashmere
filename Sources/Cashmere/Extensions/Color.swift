//
//  Color.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 04.03.25.
//

import CMPlatform


extension PlatformColor {
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
}


extension PlatformColor {
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


extension PlatformColor {
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
