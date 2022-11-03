//
//  Constants.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/7/22.
//

import Foundation

enum FirmataCommands: UInt8 {
    case analogMessage = 0xE0 // send data for an analog pin (or PWM)
    case digitalMessage = 0x90 // send data fora digital pin
    case reportAnalog = 0xC0 // enable analog input by pin number
    case reportDigital = 0xD0 // enable digital input by port pair
    case startSysex = 0xF0 // start a MIDI sysex message
    case setPinMode = 0xF4 // set a pin to input/output/pwm/etc.
    case setDigitalPinValue = 0xF5 // turn a digital pin on or off
    case endSysex = 0xF7 // end a MIDI sysex message
    case reportVersion = 0xF9 // report firmware version
    case systemReset = 0xFF // reset from MIDI

    // extended command set
    case string = 0x71
    case firmwareMessage = 0x79 // query or report the firmware name

    // extended command set using sysex (0-127/0x00-0x7F)
    // 0x00-0x0F reserved for user-defined commands

    // case servoConfig = 0x70 // set max angle, minPulse, maxPulse, freq
    // case stringData = 0x71 // send a string message with 14-bit characters
    // case shiftData = 0x75 // a bitfrom to/form a shift register
    // case i2cRequest = 0x76 // send an I2C read/write request
    // case i2cReply = 0x77 // a reply to an I2C read request
    // case i2cConfig = 0x78 // configure I2C settings (delay times and power pins)
}

enum SysexCommands: UInt8 {
    case extendedID = 0x00
    // reserved 0x01 - 0x0f
    case analogMappingQuery = 0x69
    case analogMappingResponse = 0x6A
    case capabilityQuery = 0x6B
    case capabilityResponse = 0x6C
    case pinStateQuery = 0x6D
    case pinStateResponse = 0x6E
    case extendedAnalog = 0x6F // analog write (pwm, servo, etc) to any pin
    case stringData = 0x71
    case reportFirmware = 0x79
    case samplingInterval = 0x7A
    case sysexNonRealtime = 0x7E
    case sysexRealtime = 0x7F
}

enum PinMode: UInt8 {
    // used internally to disable pins that can't be reasonably used
    case unavailable = 255

    case input = 0
    case output = 1
    case analog = 2
    case pwm = 3
    case servo = 4
    case i2c = 5
    case onewire = 6
    case stepper = 7
    case encoder = 8
    case serial = 9
    case pullup = 10
}

enum FirmataError: Error {
    case ioError(String)
    case pinAlreadyTaken
    case invalidPinDefinition
    case noInputWarning
    case integerTooLarge(Int)
}

enum ConnectionState: String, CaseIterable, Identifiable {
    case disconnected = "Disconnected"
    case connecting = "Connecting"
    case connected = "Connected"

    var id: Self { self }
}

struct BoardLayout: Hashable {
    let digital: [Int]
    let analog: [Int]
    let pwm: [Int]
    let usePorts: Bool
    let disabled: [Int] // Ports with firmata control disabled (rx and tx, typically)
}

enum BoardModel: Hashable, Identifiable {
    case dué
    case mega
    case nano
    case uno
    case unknown(BoardLayout?)

    var id: Self { self }
}

// MARK: Board layouts
let boards: [BoardModel: BoardLayout] = [
    BoardModel.dué: BoardLayout(
        digital: Array(0..<54),
        analog: Array(0..<12),
        pwm: Array(2..<14),
        usePorts: true,
        disabled: [0, 1]),

    BoardModel.mega: BoardLayout(
        digital: Array(0..<54),
        analog: Array(0..<16),
        pwm: Array(2..<14),
        usePorts: true,
        disabled: [0, 1]),

    BoardModel.nano: BoardLayout(
        digital: Array(0..<14),
        analog: Array(0..<8),
        pwm: [3, 5, 6, 9, 10, 11],
        usePorts: true,
        disabled: [0, 1]),

    BoardModel.uno: BoardLayout(
        digital: Array(0..<14),
        analog: Array(0..<6),
        pwm: [3, 5, 6, 9, 10, 11],
        usePorts: true,
        disabled: [0, 1]),
]
