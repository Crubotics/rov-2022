//
//  MotorControlView.swift
//  Crubotics
//
//  Created by Quentin Wright on 6/14/22.
//

import SwiftUI

struct MotorControlView: View {
    @State private var motorOverrides: [Int:MotorDirectionOverride] = [:]

    var body: some View {
        VStack {
            ForEach(Motors.allMotors) { motor in
                HStack {
                    Text(motor.label).frame(width: 85)
                    Button("Forward") {
                        motorOverrides[motor.id] = .force(.forward)

                        motor.setOverride(.force(.forward))
                    }

                    Button("Reverse") {
                        motorOverrides[motor.id] = .force(.reverse)

                        motor.setOverride(.force(.reverse))
                    }

                    Button("Stopped") {
                        motorOverrides[motor.id] = .force(.stopped)

                        motor.setOverride(.force(.stopped))
                    }

                    Button("Auto") {
                        motorOverrides[motor.id] = MotorDirectionOverride.none

                        motor.setOverride(.none)
                    }

                    Circle()
                        .fill({
                            switch (motorOverrides[motor.id] ?? .none) {
                            case .force(let direction):
                                switch direction {
                                case .forward:
                                    return .green
                                case .reverse:
                                    return .orange
                                case .stopped:
                                    return .red
                                }
                            case .none:
                                return .white
                            }
                        }() as Color)
                        .frame(width: 10, height: 10)
                }
            }
        }.frame(width: 450, height: 200)
    }
}

struct MotorControlView_Previews: PreviewProvider {
    static var previews: some View {
        MotorControlView()
    }
}
