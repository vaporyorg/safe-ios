//
//  Address.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.04.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Web3

typealias Address = EthereumAddress

extension Address.Error: LocalizedError {
    public var errorDescription: String? {
        switch self {
        case .addressMalformed:
            return "The address is malformed. Please provide an Ethereum address."
        case .checksumWrong:
            return "The address is typed incorrectly. Please double-check it."
        }
    }
}

extension Address {

    static let zero = try! Address(Bytes(repeating: 0, count: 20))

    var isZero: Bool {
        self == .zero
    }

    var checksummed: String {
        hex(eip55: true)
    }

    var hexadecimal: String {
        hex(eip55: false)
    }

    var data: Data {
        Data(rawAddress)
    }

    init(_ value: UInt256) {
        let data = Data(ethHex: String(value, radix: 16)).endTruncated(to: 20).leftPadded(to: 20)
        try! self.init(hex: data.toHexStringWithPrefix(), eip55: false)
    }

    init?(_ value: String) {
        try? self.init(hex: value, eip55: false)
    }

    init(_ value: String, isERC681: Bool) throws {
        var addressString = value
        if isERC681 {
            addressString = Address.addressFromERC681(addressString)
        }

        try self.init(hex: addressString, eip55: false)
    }

    // https://github.com/ethereum/EIPs/blob/master/EIPS/eip-681.md
    private static func addressFromERC681(_ address: String) -> String {
        let hexPrefix = "0x"
        let withoutScheme = address.replacingOccurrences(of: "ethereum:pay-", with: "").replacingOccurrences(of: "ethereum:", with: "")
        let hasPrefix = withoutScheme.hasPrefix(hexPrefix)
        let withoutPrefix = hasPrefix ? String(withoutScheme.dropFirst(hexPrefix.count)) : withoutScheme
        let leadingHexChars = withoutPrefix.filter { (c) -> Bool in
            return !c.unicodeScalars.contains(where: { !CharacterSet.hexadecimals.contains($0)})
        }

        return hexPrefix + leadingHexChars
    }
}

extension Address: ExpressibleByStringLiteral {
    public init(stringLiteral value: String) {
        if let v = Address(value) {
            self = v
        } else {
            assertionFailure("Invalid literal address: \(value)")
            self = .zero
        }
    }
}

extension Address: CustomStringConvertible {
    public var description: String {
        checksummed
    }
}

enum AddressRegistry {
    static let ether = Address.zero
}
