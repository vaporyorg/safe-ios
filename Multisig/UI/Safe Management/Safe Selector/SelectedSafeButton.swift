//
//  SelectedSafeButton.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 06.05.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import SwiftUI

struct SelectedSafeButton: View {

    @Binding var showsSafeInfo: Bool

    @FetchRequest(fetchRequest: Safe.fetchRequest().selected())
    var selected: FetchedResults<Safe>

    var body: some View {
        Button(action: { self.showsSafeInfo.toggle() }) {
            if selected.first == nil {
                notSelectedView
            } else {
                SafeCell(safe: selected.first!)
            }
        }
        .padding(.bottom)
        .disabled(selected.first == nil)
    }

    var notSelectedView: some View {
        HStack {
            Image("safe-selector-not-selected-icon")
                .resizable()
                .renderingMode(.original)
                .frame(width: 30, height: 30)

            Text("No Safe loaded")
                .font(Font.gnoBody.weight(.semibold))
                .foregroundColor(Color.gnoMediumGrey)
        }
    }

}

struct SelectedSafeButton_Previews: PreviewProvider {
    static var previews: some View {
        SelectedSafeButton(showsSafeInfo: .constant(false))
    }
}