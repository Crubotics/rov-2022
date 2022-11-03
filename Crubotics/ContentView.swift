//
//  ContentView.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/5/22.
//

import SwiftUI
import GameController

struct ContentView: View {
    @State var board: Board = Board.main
    var controller: GCController? {
        GCController.current
    }

    @State var motorOverrides: [Int:MotorDirectionOverride] = [:]

    private let queue = DispatchQueue(label: "motor-control", qos: .userInitiated)

    var body: some View {
        VStack {
            ArduinoStatusView()
                .padding()

            ControllerStatusView().padding()
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .toolbar {
            ToolbarItemGroup(placement: ToolbarItemPlacement.primaryAction) {
                ConnectionView(board: board)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    @StateObject static var board: Board = {
        let board = Board(interface: "/dev/cu.usbmodem144201", model: .mega)
        board.connectionState = .connected
        return board
    }()

    static var previews: some View {
        ContentView()
    }
}
