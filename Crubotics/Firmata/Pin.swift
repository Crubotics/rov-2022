//
//  Pin.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/6/22.
//

import Foundation

class Pin: ObservableObject {
    private let board: Board
    public let pinNumber: UInt8
    private let type: PinMode
    public let port: Port?
    public var pwmCapable: Bool = false
    public var mode: PinMode
    public var reporting: Bool = false
    @Published public var value: UInt8 = 0

    init(board: Board, pinNumber: UInt8, type: PinMode = PinMode.analog, port: Port? = nil) {
        self.board = board
        self.pinNumber = pinNumber
        self.type = type
        self.port = port
        self.mode = type == .output ? .output : .input
    }

    func setMode(mode: PinMode) throws {
        if mode == .unavailable {
            self.mode = .unavailable
            return
        }

        if self.mode == .unavailable {
            throw FirmataError.ioError("\(self) cannot be used through Firmata")
        }

        if mode == .pwm && !pwmCapable {
            throw FirmataError.ioError("\(self) does not have PWM capabilities")
        }

        if mode == .servo {
            if type != .output {
                throw FirmataError.ioError("Only digital pins can drive servos1 \(self) is not digital")
            }

            self.mode = .servo
            try? Board.main.servoConfig(pin: pinNumber)
        }

        self.mode = mode
        let message = Data([FirmataCommands.setPinMode.rawValue, pinNumber, UInt8(mode.rawValue)])
        Board.main.write(data: message)
    
        if mode == .input {
            try? enableReporting()
        }
    }

    func enableReporting() throws {
        if mode != .input {
            throw FirmataError.ioError("\(self) is not an input and therefore cannot report")
        }

        if type == .analog {
            reporting = true
            let message = Data([UInt8(FirmataCommands.reportAnalog.rawValue + pinNumber), 1])
            Board.main.write(data: message)
        } else {
            port?.enableReporting()
        }
    }

    func disableReporting() {
        if type == .analog {
            reporting = false
            let message = Data([UInt8(FirmataCommands.reportAnalog.rawValue + pinNumber), 0])
            Board.main.write(data: message)
        } else {
            port?.disableReporting()
        }
    }

    func read() throws -> UInt8 {
        if mode == .unavailable {
            throw FirmataError.ioError("Cannot read pin \(pinNumber)")
        }

        return value
    }

    func write(_ newValue: UInt8, force: Bool = false, skipPort: Bool = false) throws {
        if mode == .unavailable {
            throw FirmataError.ioError("\(self) cannot be used through Firmata")
        }

        if mode == .input {
            throw FirmataError.ioError("\(self) is setup as input can cannot be written to")
        }

        if self.value != newValue || force {
            self.value = newValue
            if mode == .output {
                if let port = self.port {
                    if !skipPort {
                        port.write()
                    }
                } else {
                    let message = Data([FirmataCommands.setDigitalPinValue.rawValue, pinNumber, newValue])
                    Board.main.write(data: message)
                }
            } else if mode == .pwm {
                let message = Data([FirmataCommands.analogMessage.rawValue + self.pinNumber, newValue % 128, newValue >> 7])
                Board.main.write(data: message)
            } else if mode == .servo {
                let message = Data([FirmataCommands.analogMessage.rawValue + pinNumber, newValue % 128, newValue >> 7])
                Board.main.write(data: message)
            }
        }
    }
}
