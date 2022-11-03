//
//  Util.swift
//  Crubotics
//
//  Created by Quentin Wright on 5/6/22.
//

import Foundation

extension Int {
    func asTwoBytes() throws -> Data {
        if self > 32767 {
            throw FirmataError.integerTooLarge(self)
        }

        return Data([UInt8(self % 128), UInt8(self >> 7)])
    }

    static func fromTwoBytes(_ data: Data) -> Int {
        let lsb = data[0]
        let msb = data[1]
        return Int(msb << 7 | lsb)
    }
}
