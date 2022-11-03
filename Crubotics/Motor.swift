//
//  Motor.swift
//  Crubotics
//
//  Created by Quentin Wright on 6/3/22.
//

import Foundation

enum MotorCommands {
    case strafeRight
    case strafeLeft

    case forward
    case backward

    case rotateClockwise
    case rotateCounterclockwise

    case frontUp
    case frontDown
    case stopFrontVertical

    case backUp
    case backDown
    case stopBackVertical

    case stopHorizontal
}

enum MotorDirection {
    case forward, reverse, stopped
}

enum MotorDirectionOverride {
    case none
    case force(MotorDirection)
}

class Motor: Identifiable, ObservableObject {
    public let id: Int
    public let label: String
    public let pins: (Int, Int)
    public let reversed: Bool

    @Published public var commandedDirection: MotorDirection = .stopped
    @Published public var currentDirection: MotorDirection = .stopped
    @Published public var directionOverride: MotorDirectionOverride = .none

    private var board: Board {
        Board.main
    }

    public init(id: Int, label: String, pins: (Int, Int), reversed: Bool) {
        self.id = id
        self.label = label
        self.pins = pins
        self.reversed = reversed

        if board.connectionState == .connected {
            setDirection(.stopped, force: true)
        } else {
            NotificationCenter.default.addObserver(forName: .boardDidConnect, object: nil, queue: .main) { [self] _ in
                setDirection(.stopped, force: true)
            }
        }
    }

    public func setOverride(_ direction: MotorDirectionOverride) {
        switch direction {
        case .none:
            directionOverride = .none
            setDirection(.stopped)
            break
        case .force(let motorDirection):
            directionOverride = direction
            setDirection(motorDirection)
            break
        }
    }

    public func setDirection(_ direction: MotorDirection, force: Bool = false, isRetry: Bool = false) {
        switch directionOverride {
        // if there is no direction override, continue
        case .none:
            break
        case .force(let motorDirection):
            // if the direction is the same as the forced direction
            if motorDirection != direction { return }
        }

        commandedDirection = direction

        if board.connectionState == .connected {
            guard let pin1 = board.getPin(pins.0),
                  let pin2 = board.getPin(pins.1) else {
                print("Could not resolve pins: \(pins)")
                return
            }

            do {
                switch direction {
                case .forward:
                    try pin1.write(reversed ? 0 : 1, force: force, skipPort: true)
                    try pin2.write(reversed ? 1 : 0, force: force, skipPort: true)
                    break
                case .reverse:
                    try pin1.write(reversed ? 1 : 0, force: force, skipPort: true)
                    try pin2.write(reversed ? 0 : 1, force: force, skipPort: true)
                    break
                case .stopped:
                    try pin1.write(1, force: force, skipPort: true)
                    try pin2.write(1, force: force, skipPort: true)
                    break
                }

                // write the first (and possibly second) pin's port state
                pin1.port?.write()

                // if pin1 and pin2 are on different ports, write the second pin's port state
                if pin1.port?.portNumber != pin2.port?.portNumber {
                    pin2.port?.write()
                }

                currentDirection = direction
            } catch {
                print("Could not write to pins: \(pins) \(error)")
            }
        } else {
            
            return
            // if this is the second attempt at setting direction
            /*if isRetry {
                print("Could not set initial motor direction after retry")
                return
            }

            var observer: (Notification) -> Void = { _ in }

            observer = { [self] _ in
                setDirection(direction, force: force, isRetry: true)
                NotificationCenter.default.removeObserver(observer)
            }

            // wait until board connects to set direction
            NotificationCenter.default.addObserver(forName: .boardDidConnect, object: nil, queue: .main, using: observer)*/
        }
    }
}
