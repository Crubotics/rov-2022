//
//  CruboticsApp.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/5/22.
//

import SwiftUI
import AVFoundation
import GameKit

let frontLeft = (23, 22)
let backLeft = (24, 25)
let backVertical = (26, 27)
let frontVertical = (28, 29)
let frontRight = (30, 31)
let backRight = (33, 32)

enum MotorCommandOverride {
    case none
    case force(MotorCommands)
}

struct Motors {
    public static let frontLeft = Motor(id: 1, label: "Front Left", pins: (22, 23), reversed: true)
    public static let backLeft = Motor(id: 2, label: "Back Left", pins: (24, 25), reversed: false)
    public static let frontRight = Motor(id: 3, label: "Front Right", pins: (30, 31), reversed: false)
    public static let backRight = Motor(id: 4, label: "Back Right", pins: (32, 33), reversed: false)

    public static let frontVertical = Motor(id: 5, label: "Front Vertical", pins: (28, 29), reversed: true)
    public static let backVertical = Motor(id: 6, label: "Back Vertical", pins: (26, 27), reversed: false)

    public static var commandOverride: MotorCommandOverride = .none

    public static let allMotors = [frontLeft, backLeft, frontRight, backRight, frontVertical, backVertical]

    public static func setOverride(_ command: MotorCommandOverride) {
        switch command {
        case .none:
            commandOverride = .none
            self.command(.stopHorizontal)
            break
        case .force(let motorCommand):
            commandOverride = command
            self.command(motorCommand)
            break
        }
    }

    public static func command(_ command: MotorCommands) {
        switch commandOverride {
        // if there is no command override, continue
        case .none:
            break
        case .force(let motorCommand):
            // if the command is the same as the forced command, continue
            if motorCommand != command { return }
        }

        switch command {
        case .strafeRight:
            frontLeft.setDirection(.forward)
            frontRight.setDirection(.reverse)
            backLeft.setDirection(.forward)
            backRight.setDirection(.reverse)
            break
        case .strafeLeft:
            frontLeft.setDirection(.reverse)
            frontRight.setDirection(.forward)
            backLeft.setDirection(.reverse)
            backRight.setDirection(.forward)
            break
        case .forward:
            frontLeft.setDirection(.forward)
            frontRight.setDirection(.forward)
            backLeft.setDirection(.reverse)
            backRight.setDirection(.reverse)
            break
        case .backward:
            frontLeft.setDirection(.reverse)
            frontRight.setDirection(.reverse)
            backLeft.setDirection(.forward)
            backRight.setDirection(.forward)
            break
        case .rotateClockwise:
            frontLeft.setDirection(.forward)
            frontRight.setDirection(.reverse)
            backLeft.setDirection(.reverse)
            backRight.setDirection(.forward)
            break
        case .rotateCounterclockwise:
            frontLeft.setDirection(.reverse)
            frontRight.setDirection(.forward)
            backLeft.setDirection(.forward)
            backRight.setDirection(.reverse)
            break
        case .frontUp:
            frontVertical.setDirection(.forward)
            break
        case .frontDown:
            frontVertical.setDirection(.reverse)
            break
        case .stopFrontVertical:
            frontVertical.setDirection(.stopped)
            break
        case .backUp:
            backVertical.setDirection(.forward)
            break
        case .backDown:
            backVertical.setDirection(.reverse)
            break
        case .stopBackVertical:
            backVertical.setDirection(.stopped)
            break
        case .stopHorizontal:
            frontLeft.setDirection(.stopped)
            frontRight.setDirection(.stopped)
            backLeft.setDirection(.stopped)
            backRight.setDirection(.stopped)
            break
        }
    }
}

enum LaserState {
    case toggle
    case constant(Bool)
}

class ControllerOptions: ObservableObject {
    @Published var deadzone: Float = 0.5
    @Published var dockingDuration: Float = 3.0
    @Published var controller: GCController?
    @Published var isLaserOn: Bool = false

    @ObservedObject static var shared = ControllerOptions()

    func setLaserState(_ state: LaserState) {
        if Board.main.connectionState != .connected { return }

        var newState: Bool = false

        switch state {
        case .constant(let on):
            newState = on
            break
        case .toggle:
            newState = !isLaserOn
            break
        }

        isLaserOn = newState
        try? Board.main.getPin(12, mode: .output)?.write(isLaserOn ? 1 : 0)
    }
}

class VideoCaptureDelegate: NSObject, AVCaptureFileOutputRecordingDelegate {
    public static let shared = VideoCaptureDelegate()

    private let captureSession = AVCaptureSession()

    func beginCaptureSession() {
        captureSession.beginConfiguration()

        if captureSession.canSetSessionPreset(.hd1920x1080) {
            captureSession.sessionPreset = .hd1920x1080
            print("Set session preset to \(captureSession.sessionPreset)")
        } else {
            print("Cannot set session preset to \(AVCaptureSession.Preset.hd1920x1080)")
        }

        let videoDevice = AVCaptureDevice.default(for: .video)!

        guard
            let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
            captureSession.canAddInput(videoDeviceInput)
        else { return }
        captureSession.addInput(videoDeviceInput)

        if let audioDevice = AVCaptureDevice.default(for: .audio) {
            guard let audioDeviceInput = try? AVCaptureDeviceInput(device: audioDevice),
                  captureSession.canAddInput(audioDeviceInput)
            else {
                print("Audio device input cannot be added to session")
                return
            }
            captureSession.addInput(audioDeviceInput)
        } else {
            print("No default audio device")
        }

        if let videoDevice = AVCaptureDevice.default(for: .video) {
            guard let videoDeviceInput = try? AVCaptureDeviceInput(device: videoDevice),
                  captureSession.canAddInput(videoDeviceInput)
            else {
                print("Video device input cannot be added to session")
                return
            }
            captureSession.addInput(videoDeviceInput)
        } else {
            print("No default video device")
        }

        let output = AVCaptureMovieFileOutput()
        if captureSession.canAddOutput(output) {
            captureSession.addOutput(output)
        } else {
            print("Capture output cannot be added to session")
        }

        //let videoConnection = AVCaptureConnection(inputPorts: videoDeviceInput.ports, output: output)

        //if captureSession.canAddConnection(videoConnection) {
        //    captureSession.addConnection(videoConnection)
        //} else {
        //    print("Cannot add video connection:", videoConnection)
        //}

//        let audioConnection = AVCaptureConnection(inputPorts: audioDeviceInput.ports, output: output)
//        captureSession.addConnection(audioConnection)

        //videoConnection.

        captureSession.commitConfiguration()

        captureSession.startRunning()

        if let url = URL(string: "file:///Users/wrightq00/Desktop/test2.mp4") {
            output.startRecording(to: url, recordingDelegate: self)
            print("Recording started")
        } else {
            print("Invalid URL")
        }

        DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .seconds(2))) {
            output.stopRecording()
            print("Stopping recording")
        }

    }

    func fileOutput(_ output: AVCaptureFileOutput, didFinishRecordingTo outputFileURL: URL, from connections: [AVCaptureConnection], error: Error?) {
        print("Finished recording: \(String(describing: error))")
    }

    func processCameraPermission() {
        var audioGranted = false
        var videoGranted = false

        switch AVCaptureDevice.authorizationStatus(for: .audio) {
        case .authorized:
            print("Authorized")
            return
        case .notDetermined:
            print("Not determined")
            AVCaptureDevice.requestAccess(for: .audio) { [self] granted in
                audioGranted = true
                if videoGranted {
                    beginCaptureSession()
                }
            }

        case .denied:
            print("Denied")
            return

        case .restricted:
            return

        @unknown default:
            return
        }

        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            print("Authorized")
            beginCaptureSession()
            return
        case .notDetermined:
            print("Not determined")
            AVCaptureDevice.requestAccess(for: .video) { [self] granted in
                videoGranted = true
                if audioGranted {
                    beginCaptureSession()
                }
            }

        case .denied:
            print("Denied")
            return

        case .restricted:
            return

        @unknown default:
            return
        }
    }
}

@main
struct CruboticsApp: App {
    @State var controller: GCController?
    var gamepad: GCExtendedGamepad? {
        controller?.extendedGamepad
    }

    @State private var updateTimer: Timer?

    private func rightShoulderDidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        Motors.command(pressed ? .frontUp : .stopFrontVertical)
    }

    private func leftShoulderDidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        Motors.command(pressed ? .backUp : .stopBackVertical)
    }

    private func rightTriggerDidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        Motors.command(pressed ? .frontDown : .stopFrontVertical)
    }

    private func leftTriggerDidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        Motors.command(pressed ? .backDown : .stopBackVertical)
    }

    private func buttonADidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        if pressed { return }

        ControllerOptions.shared.setLaserState(.toggle)
    }

    private func buttonBDidPressChange(button: GCControllerButtonInput, value: Float, pressed: Bool) {
        if pressed {
            Motors.command(.stopFrontVertical)
            Motors.command(.stopBackVertical)
            Motors.command(.stopHorizontal)
        }
    }

    private func triggerValueChangedHandler() {
        guard let gamepad = gamepad else { return }

        let deadzone = ControllerOptions.shared.deadzone

        if gamepad.leftThumbstick.xAxis.value > deadzone {
            Motors.command(.strafeRight)
        } else if gamepad.leftThumbstick.xAxis.value < -deadzone {
            Motors.command(.strafeLeft)
        } else if gamepad.leftThumbstick.yAxis.value > deadzone {
            Motors.command(.forward)
        } else if gamepad.leftThumbstick.yAxis.value < -deadzone {
            Motors.command(.backward)
        } else if gamepad.rightThumbstick.xAxis.value > deadzone {
            Motors.command(.rotateClockwise)
        } else if gamepad.rightThumbstick.xAxis.value < -deadzone {
            Motors.command(.rotateCounterclockwise)
        } else {
            Motors.command(.stopHorizontal)
        }

        if gamepad.rightThumbstick.yAxis.value < -deadzone {
            Motors.command(.frontUp)
        } else if gamepad.rightThumbstick.yAxis.value > deadzone {
            Motors.command(.frontDown)
        } else if
            gamepad.rightTrigger.value == 0
                && gamepad.leftTrigger.value == 0
                && gamepad.rightShoulder.value == 0
                && gamepad.leftShoulder.value == 0 {
            Motors.command(.stopFrontVertical)
        }
    }

    @State private var isMovingForward = false

    private func dPadValueChangedHandler(axis: GCControllerDirectionPad, xValue: Float, yValue: Float) {
        if yValue == 1.0 {
            if isMovingForward {
                isMovingForward = false
                Motors.setOverride(.none)
                return
            }

            isMovingForward = true
            Motors.setOverride(.force(.forward))

            DispatchQueue.main.asyncAfter(deadline: .now().advanced(by: .milliseconds(Int(ControllerOptions.shared.dockingDuration * 1000)))) {
                if !isMovingForward { return }
                Motors.setOverride(.none)
            }
        }
    }

    private func controllerDidConnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        print("Controller connected:", controller.vendorName ?? "[no name]")
        self.controller = controller

        guard let gamepad = controller.extendedGamepad else { return }
        ControllerOptions.shared.controller = controller

        gamepad.rightShoulder.pressedChangedHandler = rightShoulderDidPressChange
        gamepad.leftShoulder.pressedChangedHandler = leftShoulderDidPressChange

        gamepad.rightTrigger.pressedChangedHandler = rightTriggerDidPressChange
        gamepad.leftTrigger.pressedChangedHandler = leftTriggerDidPressChange

        gamepad.buttonA.valueChangedHandler = buttonADidPressChange
        gamepad.buttonB.valueChangedHandler = buttonBDidPressChange

        gamepad.dpad.valueChangedHandler = dPadValueChangedHandler
    }

    private func controllerDidDisconnect(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        ControllerOptions.shared.controller = nil

        print("Controller disconnected:", controller.vendorName ?? "[no name]")
        if self.controller == controller { self.controller = nil }
        updateTimer?.invalidate()
    }

    private func controllerDidBecomeCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        print("Controller became current:", controller.vendorName ?? "[no name]")
        if self.controller == nil { self.controller = controller }
    }

    private func controllerDidStopBeingCurrent(_ notification: Notification) {
        guard let controller = notification.object as? GCController else {
            return
        }

        print("Controller stopped being current:", controller.vendorName ?? "[no name]")
    }

    @State var selectedView: SidebarSelection? = .arduino

    var body: some Scene {
        WindowGroup("Crubotics") {
            NavigationView {
                SidebarView(selectedView: $selectedView)
            }
            .toolbar {
                ToolbarItemGroup(placement: ToolbarItemPlacement.primaryAction) {
                    ConnectionView()
                }
            }
                .onAppear {
                    GCController.startWirelessControllerDiscovery {
                        print("Completion hander:startWirelessControllerDisvocery")
                        let controllers = GCController.controllers()
                        print(controllers)
                    }

                    // VideoCaptureDelegate.shared.processCameraPermission()

                    NotificationCenter.default.addObserver(forName: .GCControllerDidConnect, object: nil, queue: .main, using: controllerDidConnect)
                    NotificationCenter.default.addObserver(forName: .GCControllerDidDisconnect, object: nil, queue: .main, using: controllerDidDisconnect)
                    NotificationCenter.default.addObserver(forName: .GCControllerDidBecomeCurrent, object: nil, queue: .main, using: controllerDidBecomeCurrent)
                    NotificationCenter.default.addObserver(forName: .GCControllerDidStopBeingCurrent, object: nil, queue: .main, using: controllerDidStopBeingCurrent)

                    Timer.scheduledTimer(withTimeInterval: 1.0 / 20, repeats: true) { timer in
                        if ControllerOptions.shared.controller == nil { return }
                        triggerValueChangedHandler()
                    }
                }
                .onDisappear {
                    NotificationCenter.default.removeObserver(controllerDidConnect)
                    NotificationCenter.default.removeObserver(controllerDidDisconnect)
                    NotificationCenter.default.removeObserver(controllerDidBecomeCurrent)
                    NotificationCenter.default.removeObserver(controllerDidStopBeingCurrent)
                }
            }
            .commands {
                CruboticsCommands(board: Board.main)
            }
    }
}
