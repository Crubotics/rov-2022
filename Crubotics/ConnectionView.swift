//
//  ConnectionView.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/5/22.
//

import SwiftUI

extension Circle {
    static func forState(_ state: ConnectionState) -> some View {
        return Circle()
            .fill({
                switch state {
                case .disconnected:
                    return Color.red
                case .connecting:
                    return Color.orange
                case .connected:
                    return Color.green
                }
            }() as Color)
            .frame(width: 10, height: 10)
            .help(state.rawValue)
    }

    static func forState(enabled: Bool) -> some View {
        return forState(enabled ? ConnectionState.connected : ConnectionState.disconnected)
    }
}

struct ConnectionView: View {
    @ObservedObject var board: Board = Board.main

     private var devices: [String] {
        Board.getDevices() ?? []
    }

    private var connectButton: Button<Text> {
        get {
            Button(action: {
                board.connect()
            }) {
                Text("Connect")
            }
        }
    }

    var body: some View {
        HStack {
            Circle.forState(board.connectionState)

            Picker("Model", selection: $board.model) {
                Text("Uno").tag(BoardModel.uno)
                Text("Dué").tag(BoardModel.dué)
                Text("Mega").tag(BoardModel.mega)
                Text("Nano").tag(BoardModel.nano)
                Text("Auto").tag(BoardModel.unknown(nil))
            }.frame(width: 150)

            Picker("Port", selection: $board.selectedInterface) {
                ForEach(devices, id: \.self) { path in
                    Text(path).tag(path)
                }
            }.frame(width: 200)

            connectButton
        }.touchBar {
            connectButton.touchBarItemPrincipal(true)
        }
    }
}

struct ConnectionView_Previews: PreviewProvider {
    static var previews: some View {
        Group {
            ConnectionView()
                .previewLayout(.sizeThatFits)
        }
    }
}
