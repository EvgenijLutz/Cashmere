//
//  Button.swift
//  Cashmere
//
//  Created by Evgenij Lutz on 13.03.25.
//

import SwiftUI


public struct ListButtonStyle: ButtonStyle {
    let normalColor: Color
    let pressedColor: Color
    
    
    public init(normal: Color = .clear, pressed: Color = Color.gray.opacity(0.3)) {
        normalColor = normal
        pressedColor = pressed
    }
    
    
    public func makeBody(configuration: Self.Configuration) -> some View {
        if #available(iOS 15.0, *) {
            configuration.label
                .background {
                    if configuration.isPressed {
                        pressedColor
                    }
                    else {
                        normalColor
                    }
                }
        } else {
            configuration.label
                .background(configuration.isPressed ? pressedColor : normalColor)
        }
    }
    
}
