//
//  ArduinoStatusView.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/15/22.
//

import SwiftUI

struct ArduinoStatusView: View {
    @ObservedObject var board: Board = Board.main

    var devices: [String] {
        Board.getDevices() ?? []
    }

    var body: some View {
        HStack(alignment: .top) {
            Image(systemName: "cable.connector").font(Font.title)

            VStack(alignment: .leading) {
                Text({
                    if board.connectionState == .disconnected { return "Disconnected" }
                    switch board.model {
                    case .dué:
                        return "Arduino Dué"
                    case .mega:
                        return "Arduino Mega"
                    case .nano:
                        return "Arduino Nano"
                    case .uno:
                        return "Arduino Uno"
                    case .unknown(_):
                        return "Arduino"
                    }
                }() as String).font(Font.title)

                Group {
                    Picker("Port", selection: $board.selectedInterface) {
                        ForEach(devices, id: \.self) { device in
                            Text(device).tag(device)
                        }
                    }

                    Picker("Model", selection: $board.model) {
                        Text("Uno").tag(BoardModel.uno)
                        Text("Dué").tag(BoardModel.dué)
                        Text("Mega").tag(BoardModel.mega)
                        Text("Nano").tag(BoardModel.nano)
                        Text("Auto").tag(BoardModel.unknown(nil)).disabled(true)
                    }
                }
                .frame(maxWidth: 200)

                Text("Baud rate: \(board.commandedBaudRate.speedValue) bps")

                Button(action: board.connect) {
                    Text(board.connectionState == .disconnected ? "Connect" : "Reconnect")
                }
            }
        }
    }
}

struct ArduinoStatusView_Previews: PreviewProvider {
    @StateObject static var board = Board(interface: "/dev/cu.usbmodem146201", model: .mega)

    static var previews: some View {
        ArduinoStatusView()
    }
}
