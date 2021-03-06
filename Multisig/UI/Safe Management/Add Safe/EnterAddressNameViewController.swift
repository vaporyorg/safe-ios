//
//  EnterSafeNameViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 15.12.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

class EnterAddressNameViewController: UIViewController {
    var address: Address!
    var name: String?
    var trackingEvent: TrackingEvent!
    var screenTitle: String?
    var actionTitle: String!
    var placeholder: String!
    var descriptionText: String!
    var completion: (String) -> Void = { _ in }

    private var nextButton: UIBarButtonItem!
    private var debounceTimer: Timer!
    private let debounceDuration: TimeInterval = 0.250

    @IBOutlet private weak var identiconView: UIImageView!
    @IBOutlet private weak var addressLabel: UILabel!
    @IBOutlet private weak var descriptionLabel: UILabel!
    @IBOutlet private weak var textField: GNOTextField!

    override func viewDidLoad() {
        super.viewDidLoad()
        assert(address != nil, "Developer error: expect to have an address")
        assert(descriptionText?.isEmpty == false, "Developer error: expect to have a description")
        assert(actionTitle?.isEmpty == false, "Developer error: expect to have an action title")
        assert(placeholder?.isEmpty == false, "Developer error: expect to have a placeholder")
        assert(trackingEvent != nil, "Developer error: expect to have a tracking event")

        identiconView.setAddress(address.hexadecimal)
        addressLabel.attributedText = address.highlighted
        descriptionLabel.setStyle(.primary)
        descriptionLabel.text = descriptionText

        textField.setPlaceholder(placeholder)
        textField.textField.delegate = self
        textField.textField.becomeFirstResponder()

        navigationItem.title = screenTitle

        nextButton = UIBarButtonItem(title: actionTitle, style: .done, target: self, action: #selector(didTapNextButton))
        nextButton.isEnabled = false
        navigationItem.rightBarButtonItem = nextButton
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(trackingEvent)
    }

    @objc private func didTapNextButton() {
        guard let name = name else { return }
        completion(name)
    }

    fileprivate func validateName() {
        nextButton.isEnabled = false
        guard let text = textField.textField.text?.trimmingCharacters(in: .whitespacesAndNewlines),
              !text.isEmpty else {
            return
        }
        self.name = text
        nextButton.isEnabled = true
    }
}

extension EnterAddressNameViewController: UITextFieldDelegate {
    func textField(_ textField: UITextField, shouldChangeCharactersIn range: NSRange, replacementString string: String) -> Bool {
        debounceTimer?.invalidate()
        debounceTimer = Timer.scheduledTimer(withTimeInterval: debounceDuration, repeats: false, block: { [weak self] _ in
            self?.validateName()
        })
        return true
    }
}
