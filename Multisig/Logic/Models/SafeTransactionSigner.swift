//
//  TransactionSigner.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 23.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import Foundation
import Web3

class SafeTransactionSigner {
    func sign(_ transaction: Transaction, by safeAddress: Address, keyInfo: KeyInfo) throws -> Signature {
        let hashToSign = Data(ethHex: transaction.safeTxHash!.description)
        let data = transaction.encodeTransactionData(for: AddressString(safeAddress))
        guard let key = try keyInfo.privateKey() else {
            throw GSError.MissingPrivateKeyError()
        }
        guard EthHasher.hash(data) == hashToSign else {
            throw GSError.TransactionSigningError()            
        }

        return try key.sign(hash: hashToSign)
    }
}
