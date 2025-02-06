//
//  UUIDShortener.swift
//  MelodicStamp
//
//  Created by KrLite on 2025/1/28.
//

import Foundation

enum UUIDShortener {
    static let baseCharacters = "0123456789abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ_-#@&$%;:+="
    static let base = baseCharacters.count

    static func shorten(uuid: UUID) -> String {
        // Access the UUID as an array of bytes
        let bytes = withUnsafeBytes(of: uuid.uuid) { Array($0) }

        // Convert the bytes to a single encoded string
        return encode(bytes)
    }

    static func expand(shortened: String) -> UUID? {
        // Decode the shortened string back into bytes
        guard let bytes = decode(shortened), bytes.count == 16 else { return nil }

        // Convert the bytes back into a UUID
        let uuid = bytes.withUnsafeBytes { UUID(uuid: $0.load(as: uuid_t.self)) }
        return uuid
    }

    private static func encode(_ bytes: [UInt8]) -> String {
        var result = ""
        var value: UInt = 0
        var bits = 0

        for byte in bytes {
            value = (value << 8) | UInt(byte)
            bits += 8

            while bits >= 6 {
                bits -= 6
                let index = Int((value >> bits) & 0b111111) // Extract 6 bits
                result.append(baseCharacters[baseCharacters.index(baseCharacters.startIndex, offsetBy: index)])
            }
        }

        if bits > 0 {
            let index = Int((value << (6 - bits)) & 0b111111) // Pad remaining bits
            result.append(baseCharacters[baseCharacters.index(baseCharacters.startIndex, offsetBy: index)])
        }

        return result
    }

    private static func decode(_ string: String) -> [UInt8]? {
        var bytes: [UInt8] = []
        var value: UInt = 0
        var bits = 0

        for char in string {
            guard let index = baseCharacters.firstIndex(of: char)?.utf16Offset(in: baseCharacters) else { return nil }

            value = (value << 6) | UInt(index)
            bits += 6

            if bits >= 8 {
                bits -= 8
                let byte = UInt8((value >> bits) & 0xFF)
                bytes.append(byte)
            }
        }

        return bytes
    }
}
