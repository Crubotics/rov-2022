//
//  Commands.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/8/22.
//

import Foundation
import SwiftUI

struct CruboticsCommands: Commands {
    @ObservedObject var board: Board = Board.main

    private var connectButtonLabel: String {
        get {
            switch board.connectionState {
            case .disconnected:
                return "Connect"
            case .connecting:
                return "Connecting..."
            case .connected:
                return "Connected"
            }
        }
    }

    var body: some Commands {
        CommandMenu("Board") {
            Button(connectButtonLabel) {
                board.connect()
            }.disabled(board.connectionState != .disconnected)

            Picker("Port", selection: $board.selectedInterface) {
                ForEach(Board.getDevices() ?? [], id: \.self) { device in
                    Text(device).tag(device)
                }
            }
        }
    }
}
