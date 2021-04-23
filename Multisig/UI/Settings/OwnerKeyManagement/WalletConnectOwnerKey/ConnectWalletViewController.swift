//
//  ConnectWalletViewController.swift
//  Multisig
//
//  Created by Andrey Scherbovich on 12.04.21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit
import WalletConnectSwift

fileprivate struct InstalledWallet {
    let name: String
    let imageName: String
    let scheme: String
    let universalLink: String

    init?(walletEntry: WalletEntry) {
        let scheme = walletEntry.mobile.native
        var universalLink = walletEntry.mobile.universal
        if universalLink.last == "/" {
            universalLink = String(universalLink.dropLast())
        }

        guard let schemeUrl = URL(string: scheme),
              UIApplication.shared.canOpenURL(schemeUrl),
              !universalLink.isEmpty else { return nil }

        self.name = walletEntry.name
        self.imageName = walletEntry.imageName
        self.scheme = scheme
        self.universalLink = universalLink
    }
}

class ConnectWalletViewController: UITableViewController {
    private var installedWallets = [InstalledWallet]()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Connect Wallet"

        installedWallets = WalletsDataSource.shared.wallets.compactMap {
            InstalledWallet(walletEntry: $0)
        }

        tableView.backgroundColor = .primaryBackground
        tableView.registerCell(DetailedCell.self)
        tableView.registerCell(BasicCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.rowHeight = DetailedCell.rowHeight

        NotificationCenter.default.addObserver(
            self, selector: #selector(walletConnectSessionCreated(_:)), name: .wcDidConnectClient, object: nil)
    }

    @objc private func walletConnectSessionCreated(_ notification: Notification) {
        guard let session = notification.object as? Session else { return }

        DispatchQueue.main.sync { [unowned self] in
            _ = PrivateKeyController.importKey(from: session)
            self.dismiss(animated: true, completion: nil)
        }
    }

    // MARK: - Table view data source

    override func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return installedWallets.count != 0 ? installedWallets.count : 1
        }
        return 1
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if indexPath.section == 0 {
            if installedWallets.count != 0 {
                let wallet = installedWallets[indexPath.row]
                return tableView.detailedCell(
                    imageUrl: nil,
                    header: wallet.name,
                    description: nil,
                    indexPath: indexPath,
                    canSelect: false,
                    placeholderImage: UIImage(named: wallet.imageName))
            } else {
                return tableView.basicCell(
                    name: "Known wallets not found", indexPath: indexPath, withDisclosure: false, canSelect: false)
            }
        } else {
            return tableView.detailedCell(
                imageUrl: nil,
                header: "Display QR Code",
                description: nil,
                indexPath: indexPath,
                canSelect: false,
                placeholderImage: UIImage(systemName: "qrcode"))
        }
    }

    // MARK: - Table view delegate

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        do {
            if indexPath.section == 0 {
                let wallet = installedWallets[indexPath.row]
                let connectionURL = try getConnectionURL(universalLink: wallet.universalLink)
                UIApplication.shared.open(connectionURL, options: [:], completionHandler: nil)
            } else {
                let connectionURI = try WalletConnectClientController.shared.connect().absoluteString
                show(WalletConnectQRCodeViewController.create(code: connectionURI), sender: nil)
            }
        } catch {
            App.shared.snackbar.show(
                error: GSError.error(description: "Could not create connection URL", error: error))
            return
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        view.setName(section == 0 ? "INSTALLED WALLETS" : "EXTERNAL DEVICE")
        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    /// https://docs.walletconnect.org/mobile-linking#for-ios
    private func getConnectionURL(universalLink: String) throws -> URL {
        let connectionUriString = try WalletConnectClientController.shared.connect().urlEncodedStr
        let urlStr = "\(universalLink)/wc?uri=\(connectionUriString)"
        return URL(string: urlStr)!
    }
}
