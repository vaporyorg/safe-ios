//
//  ConfirmationsView.swift
//  Multisig
//
//  Created by Moaaz on 6/10/20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct TransactionConfirmationsView: View {
    let transaction: TransactionViewModel
    let safe: Safe

    var body: some View {
        VStack(alignment: .leading, spacing: 1) {
            TransactionConfiramtionStatusView(style: .created)
            VerticalBarView()

            ForEach(transaction.confirmations ?? [], id: \.address) { confirmation in
                TransactionConfirmationCell(address: confirmation.address, style: .confirmed)
            }

            if transaction.status == .success {
                if transaction.executor != nil {
                    TransactionConfirmationCell(address: transaction.executor!, style: .executed)
                } else {
                    TransactionConfiramtionStatusView(style: .executed)
                }
            } else {
                actionsView
            }
        }
    }

    var actionsView: some View {
        VStack (alignment: .leading, spacing: 1) {
            if style != nil {
                TransactionConfiramtionStatusView(style: style!)
            }

            if transaction.status == .waitingConfirmation {
                if !transaction.hasConfirmations {
                    VerticalBarView()
                }

                TransactionConfiramtionStatusView(style: .waitingConfirmations(transaction.remainingConfirmationsRequired))
            }
        }.fixedSize()
    }

    var style: TransactionConfiramtionStatusViewStyle? {
        let status = transaction.status
        if transaction.status == .canceled {
            return .canceled
        } else if transaction.status == .failed {
            return .failed
        } else if status == .waitingConfirmation {
            return transaction.hasConfirmations ? nil : .confirm
        } else if status == .waitingExecution {
            return .execute
        }

        return nil
    }
}