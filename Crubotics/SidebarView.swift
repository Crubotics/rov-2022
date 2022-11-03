//
//  SidebarView.swift
//  Crubotics
//
//  Created by Quentin Wright on 6/14/22.
//

import SwiftUI
import GameController

enum SidebarSelection {
    case arduino
    case controller
    case motors
}

fileprivate struct SidebarViewItem: View {
    public let image: String
    public let primaryLabel: String
    public let secondaryLabel: String

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: image)
                .font(.title2)
                .frame(width: 25, height: 25)

            VStack(alignment: .leading) {
                Text(primaryLabel).font(.title2)

                Text(secondaryLabel)
            }
        }
        .padding(5.0)
    }
}

struct SidebarView: View {
    @ObservedObject var controllerOptions = ControllerOptions.shared
    @Binding var isLaserOn: Bool
    @Binding var selectedView: SidebarSelection?
    @Binding var connectionState: ConnectionState

    init(selectedView: Binding<SidebarSelection?>) {
        _isLaserOn = ControllerOptions.$shared.isLaserOn
        _selectedView = selectedView
        _connectionState = Board.$main.connectionState
    }

    var body: some View {
        List {
            NavigationLink(
                destination: ArduinoStatusView(),
                tag: SidebarSelection.arduino,
                selection: $selectedView
            ) {
                SidebarViewItem(image: "cable.connector", primaryLabel: "Arduino", secondaryLabel: connectionState.rawValue)
            }

            NavigationLink(
                destination: ControllerStatusView(),
                tag: SidebarSelection.controller,
                selection: $selectedView
            ) {
                SidebarViewItem(image: "gamecontroller.fill", primaryLabel: "Controller", secondaryLabel: controllerOptions.controller == nil ? "Disconnected" : "Connected")
            }

            NavigationLink(
                destination: MotorControlView(),
                tag: SidebarSelection.motors,
                selection: $selectedView
            ) {
                SidebarViewItem(image: "fanblades.fill", primaryLabel: "Motors", secondaryLabel: "6 connected")
            }

            SidebarViewItem(image: isLaserOn ? "flashlight.on.fill" : "flashlight.off.fill", primaryLabel: "Lasers", secondaryLabel: isLaserOn ? "On" : "Off")
                .contextMenu {
                    Button(isLaserOn ? "Turn Off" : "Turn On") {
                        ControllerOptions.shared.setLaserState(.toggle)
                    }
                }
        }
        .frame(minWidth: 175)
        .listStyle(.sidebar)
    }
}

struct SidebarView_Previews: PreviewProvider {
    static var previews: some View {
        SidebarView(selectedView: .constant(.arduino))
    }
}
