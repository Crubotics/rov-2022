//
//  Boards.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/6/22.
//

import Foundation
import SwiftUI

extension Notification.Name {
    static let boardDidConnect: Notification.Name = .init(rawValue: "boardDidConnect")
}

class Board: ObservableObject {
    public var serialPort: SerialPort
    public var model: BoardModel {
        didSet {
            setLayout()
        }
    }

    @Published public var commandedBaudRate: BaudRate
    @Published public var currentBaudRate: BaudRate? {
        didSet {
            if currentBaudRate != commandedBaudRate {
                print("[WARN] Commanded and current baud rates do not match.")
            }
        }
    }

    private var layout: BoardLayout?
    private var name: String?
    private var reading = false

    @Published public var selectedInterface: String
    @Published public var interface: String
    @Published public var connectionState: ConnectionState = .disconnected
    @Published public var firmwareVersion: (Int, Int)? = nil
    @Published public var firmwareName: String? = nil

    public var analog: [Pin] = []
    @Published public var digital: [Pin] = []
    public var digitalPorts: [Port] = []

    private var takenAnalogPins: Set<Int> = Set()
    private var takenDigitalPins: Set<Int> = Set()
    private var writing: Bool = false
    private var writeQueue: [Data] = []
    private var readData = false

    @ObservedObject public static var main = Board(interface: "/dev/cu.usbmodem146201", model: .mega)

    // time to wait after intializing serial
    static let setupWaitTime = 5

    // MARK: init
    init(interface: String, model: BoardModel, name: String? = nil) {
        print("Board @", interface)
        self.interface = interface.starts(with: "/dev/") ? interface : "/dev/\(interface)"
        self.selectedInterface = interface

        self.model = model
        self.name = name ?? interface

        self.serialPort = SerialPort(path: interface)

        commandedBaudRate = .baud9600
    }

    // MARK: setLayout
    func setLayout() {
        switch model {
        case .unknown(let layout):
            self.layout = layout
            autoSetup()
        default:
            self.layout = boards[model]
            setupLayout(layout: layout!)
        }
    }

    // MARK: connect
    func connect() {
        // if connectionState == .connected && interface == selectedInterface { return }
        if connectionState == .connected {
            serialPort.closePort()
            digital.removeAll()
            analog.removeAll()
            takenDigitalPins.removeAll()
            takenAnalogPins.removeAll()
        }

        connectionState = .connecting
        interface = selectedInterface.starts(with: "/dev/") ? selectedInterface : "/dev/\(selectedInterface)"

        print("Connecting to Arduino at \(selectedInterface) (\(commandedBaudRate.speedValue)bps)")

        currentBaudRate = commandedBaudRate

        serialPort = SerialPort(path: interface)
        serialPort.setSettings(receiveRate: commandedBaudRate, transmitRate: commandedBaudRate, minimumBytesToRead: 0, timeout: 1, sendTwoStopBits: true)

        do {
            try serialPort.openPort()
            print("Connected to serial port")
        } catch {
            print(error)
            connectionState = .disconnected
            return
        }

        DispatchQueue.main.asyncAfter(
            deadline: .now().advanced(by: .seconds(Board.setupWaitTime)),
            qos: .userInitiated) { [self] in
                setLayout()

                if layout != nil {
                    setupLayout(layout: layout!)
                } else {
                    autoSetup()
                }

                connectionState = .connected

                NotificationCenter.default.post(name: .boardDidConnect, object: nil)
            }
    }

    // MARK: setupLayout
    func setupLayout(layout: BoardLayout) {
        for pin in layout.analog {
            analog.append(Pin(board: self, pinNumber: UInt8(pin), port: nil))
        }

         for pin in stride(from: 0, to: layout.digital.count, by: 8) {
             let pinCount = UInt8(layout.digital[pin..<min((pin + 8), layout.digital.count)].count)
             let portNumber = UInt8(pin / 8)
             let port = Port(board: self, portNumber: portNumber, pinCount: pinCount)
             digitalPorts.append(port)
             digital.append(contentsOf: port.pins)
         }

        /*for pinNumber in layout.digital {
            let pin = Pin(board: self, pinNumber: UInt8(pinNumber), port: nil)
            digital.append(pin)
        }*/

        for pin in layout.pwm {
            digital[pin].pwmCapable = true
        }

        for pin in layout.disabled {
            try? digital[pin].setMode(mode: .unavailable)
        }

        iterate()
    }

    // MARK: autoSetup
    func autoSetup() {
        sendSysex(command: .capabilityQuery)
    }

    // MARK: getPin
    func getPin(_ pinNumber: Int, mode: PinMode = .output) -> Pin? {
        if pinNumber >= digital.count { return nil }
        let pin = digital[pinNumber]
        //takenDigitalPins.update(with: pinNumber)

        let setMode: (PinMode) -> Void = { mode in
            do {
                try pin.setMode(mode: mode)
            } catch {
                print("Failed to set mode:", error)
            }
        }

        if pin.mode != mode {
            setMode(mode)
        } else {
            try? pin.enableReporting()
        }

        return pin
    }

    // MARK: sendSysex
    func sendSysex(command: SysexCommands, data: Data = Data()) {
        var message = Data([FirmataCommands.startSysex.rawValue, command.rawValue])
        message.append(data)
        message.append(FirmataCommands.endSysex.rawValue)
        write(data: message)
    }

    // MARK: iterate
    @objc
    func iterate() {
        if !readData { return }

        let queue = DispatchQueue(label: "serial-read", qos: .userInitiated)
        reading = true

        queue.async { [weak self] in
            // if reference to self is "lost", stop
            guard let self = self else { return }

            while self.reading {
                do {
                    let firstByte = try self.serialPort.readByte()
                    // printByte("byte: \(String(firstByte, radix: 16))")

                    guard let type = FirmataCommands(rawValue: firstByte) else {
                        DispatchQueue.main.async {
                            print("Unknown message type:", String(firstByte, radix: 16))
                        }

                        return
                    }

                    switch type {
                    case .analogMessage:
                        break
                    case .digitalMessage:
                        break
                    case .reportAnalog:
                        break
                    case .reportDigital:
                        break
                    case .startSysex:
                        let byte = try self.serialPort.readByte()
                        guard let command = SysexCommands(rawValue: byte) else {
                            DispatchQueue.main.async { [byte] in
                                print("Unknown command:", String(byte, radix: 16))
                            }

                            return
                        }

                        switch command {
                        case .extendedID:
                            break
                        case .analogMappingQuery:
                            break
                        case .analogMappingResponse:
                            break
                        case .capabilityQuery:
                            break
                        case .capabilityResponse:
                            // read data to end
                            while byte != FirmataCommands.endSysex.rawValue {
                                var data = Data(capacity: 32)
                                var read: UInt8 = 0
                                while read != 0x7F {
                                    read = try self.serialPort.readByte()
                                    data.append(read)
                                }

                                DispatchQueue.main.sync { [data] in
                                    print("Read", data)
                                }
                            }
                        case .pinStateQuery:
                            break
                        case .pinStateResponse:
                            break
                        case .extendedAnalog:
                            break
                        case .stringData:
                            break
                        case .reportFirmware:
                            let majorVersion = try self.serialPort.readByte()
                            let minorVersion = try self.serialPort.readByte()

                            var lsb: UInt8 = 0
                            var msb: UInt8 = 0
                            var string = String()

                            repeat {
                                lsb = try self.serialPort.readByte()

                                if lsb == FirmataCommands.endSysex.rawValue {
                                    break
                                }

                                msb = try self.serialPort.readByte()

                                let char = Character(UnicodeScalar(msb << 8 | lsb))
                                string.append(char)
                            } while lsb != FirmataCommands.endSysex.rawValue

                            DispatchQueue.main.async {
                                self.firmwareName = string
                                self.firmwareVersion = (Int(majorVersion), Int(minorVersion))
                            }

                            break
                        case .samplingInterval:
                            break
                        case .sysexNonRealtime:
                            break
                        case .sysexRealtime:
                            break
                        }

                        break
                    case .setPinMode:
                        break
                    case .setDigitalPinValue:
                        break
                    case .endSysex:
                        // this should never be read here
                        DispatchQueue.main.sync {
                            print("Read end of sysex (should not happen)")
                        }
                    case .reportVersion:
                        let majorVersion = try self.serialPort.readByte()
                        let minorVersion = try self.serialPort.readByte()

                        DispatchQueue.main.async { [self] in
                            self.firmwareVersion = (Int(majorVersion), Int(minorVersion))
                            print("Firmata version:", self.firmwareVersion ?? (-1, -1))
                        }
                    case .systemReset:
                        break
                    case .string:
                        break
                    case .firmwareMessage:
                        break
                    }
                } catch {
                    DispatchQueue.main.async { [error] in
                        print("Reading failed:", error)
                        self.reading = false
                    }
                }
            }
        }
    }

    // MARK: servoConfig
    func servoConfig(pin: UInt8, minPulse: Int = 544, maxPulse: Int = 2400, angle: UInt8 = 0) throws {
        if pin > digital.count || digital[Int(pin)].mode == .unavailable {
            throw FirmataError.ioError("Pin \(pin) is not a valid servo pin")
        }

        var message = Data([pin])
        message.append(try! minPulse.asTwoBytes())
        message.append(try! maxPulse.asTwoBytes())
        // sendSysex(command: .servoConfig, data: message)

        try? digital[Int(pin)].setMode(mode: .servo)
        try? digital[Int(pin)].write(angle)
    }

    // MARK: exit
    func exit() {
        for pin in digital where pin.mode == .servo {
            try? pin.setMode(mode: .output)
        }

        serialPort.closePort()
        connectionState = .disconnected
    }

    func write(data: Data) {
        writeQueue.append(data)
        if writing { return }

        writing = true
        while !writeQueue.isEmpty {
            _ = try? serialPort.writeData(writeQueue.removeFirst())
        }
        writing = false
    }

    // MARK: static getDevices
    static func getDevices() -> [String]? {
        do {
            return try FileManager.default.contentsOfDirectory(atPath: "/dev/")
                .filter { $0.starts(with: "cu.usbmodem") }
        } catch {
            print(error)
            return nil
        }
    }
}
