//
//  Port.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/6/22.
//

import Foundation

class Port {
    private let board: Board
    public let portNumber: UInt8
    public var pins: [Pin] = []
    private var reporting: Bool = false

    init(board: Board, portNumber: UInt8, pinCount: UInt8 = 8) {
        self.board = board
        self.portNumber = portNumber

        for pin in 0..<pinCount {
            let pinNumber = pin + portNumber * 8
            let pin = Pin(board: self.board, pinNumber: pinNumber, type: .input, port: self)
            pins.append(pin)
        }
    }

    func enableReporting() {
        reporting = true
        let message = Data([UInt8(FirmataCommands.reportDigital.rawValue + portNumber), 1])
        Board.main.write(data: message)

        for pin in pins {
            if pin.mode == .input {
                pin.reporting = true
            }
        }
    }

    func disableReporting() {
        reporting = false
        let message = Data([UInt8(FirmataCommands.reportDigital.rawValue + portNumber), 0])
        Board.main.write(data: message)
    }

    func write() {
        var mask = 0
        for pin in pins {
            if pin.mode == .output && pin.value == 1 {
                let pinNumber = pin.pinNumber - portNumber * 8
                mask |= 1 << pinNumber
            }
        }

        let message = Data([UInt8(FirmataCommands.digitalMessage.rawValue + portNumber), UInt8(mask % 128), UInt8(mask >> 7)])
        Board.main.write(data: message)
    }

    func update(mask: Int) {
        if reporting {
            for pin in pins {
                if pin.mode == .input {
                    let pinNumber = pin.pinNumber - portNumber * 8
                    pin.value = (mask & (1 << pinNumber)) > 0 ? 1 : 0
                }
            }
        }
    }
}
