//
//  ControllerStatusView.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/14/22.
//

import SwiftUI
import GameController

extension Float {
    func rounded(to: Int) -> String {
        return String(format: "%.\(to)f", self)
    }
}

struct ControllerStatusView: View {
    @ObservedObject private var options = ControllerOptions.shared

    private var gamepad: GCExtendedGamepad? {
        get {
            return options.controller?.extendedGamepad
        }
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "gamecontroller.fill")
                .symbolRenderingMode(.multicolor)
                .font(Font.title)

            VStack(alignment: .leading) {
                Text(options.controller?.vendorName ?? "Disconnected").font(Font.title)
                if options.controller != nil {
                    if gamepad != nil {
                        Text("Supports extended gamepad")
                    } else {
                        Text("Does not support extended gamepad")
                    }
                }

                Text("Deadzone: \(options.deadzone.rounded(to: 2))")
                Slider(value: .init(get: {
                    return Double(options.deadzone)
                }, set: { newValue in
                    options.deadzone = Float(newValue)
                }), in: 0.0...1.0).frame(maxWidth: 200)

                Text("Docking time: \(options.dockingDuration.rounded(to: 2))")
                Slider(value: .init(get: {
                    return Double(options.dockingDuration)
                }, set: { newValue in
                    options.dockingDuration = Float(newValue)
                }), in: 0.0...10.0).frame(maxWidth: 200)
            }
        }
    }
}

struct ControllerStatusView_Previews: PreviewProvider {
    @State static var deadzone: Double = 0.5

    static var previews: some View {
        ControllerStatusView()
    }
}
