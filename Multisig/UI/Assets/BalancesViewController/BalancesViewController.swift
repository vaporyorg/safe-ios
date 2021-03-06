//
//  BalancesViewController.swift
//  Multisig
//
//  Created by Dmitry Bespalov on 22.10.20.
//  Copyright © 2020 Gnosis Ltd. All rights reserved.
//

import UIKit

// Loads and displays balances
class BalancesViewController: LoadableViewController, UITableViewDelegate, UITableViewDataSource {

    private enum Section {
        case importKeyBanner
        case passcodeBanner
        case total(text: String)
        case balances(items: [TokenBalance])
    }

    var clientGatewayService = App.shared.clientGatewayService

    override var isEmpty: Bool { sections.isEmpty }

    private var currentDataTask: URLSessionTask?

    private var sections: [Section] = []

    private let tableBackgroundColor: UIColor = .primaryBackground

    @UserDefault(key: "io.gnosis.multisig.importKeyBannerWasShown")
    private var importKeyBannerWasShown: Bool?

    private var shouldShowImportKeyBanner: Bool {
        importKeyBannerWasShown != true
    }

    private var shouldShowPasscodeBanner: Bool {
        PrivateKeyController.hasPrivateKey &&
            !(AppSettings.passcodeBannerDismissed || AppSettings.passcodeWasSetAtLeastOnce)
    }

    convenience init() {
        self.init(namedClass: Self.superclass())
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.registerCell(BalanceTableViewCell.self)
        tableView.registerCell(TotalBalanceTableViewCell.self)
        tableView.registerCell(BannerTableViewCell.self)

        tableView.allowsSelection = false
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60
        tableView.backgroundColor = tableBackgroundColor

        tableView.delegate = self
        tableView.dataSource = self

        if importKeyBannerWasShown != true && PrivateKeyController.hasPrivateKey {
            importKeyBannerWasShown = true
        }

        emptyView.setText("Balances will appear here")

        NotificationCenter.default.addObserver(
            self, selector: #selector(ownerKeyImported), name: .ownerKeyImported, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(updatePasscodeBanner), name: .passcodeCreated, object: nil)

        NotificationCenter.default.addObserver(
            self, selector: #selector(lazyReloadData), name: .selectedFiatCurrencyChanged, object: nil)

        recreateSectionsWithCurrentItems()
    }

    @objc private func ownerKeyImported() {
        importKeyBannerWasShown = true
        recreateSectionsWithCurrentItems()
    }

    @objc private func updatePasscodeBanner() {
        recreateSectionsWithCurrentItems()
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.assetsCoins)
    }

    override func reloadData() {
        super.reloadData()
        currentDataTask?.cancel()
        do {
            let safe = try Safe.getSelected()!
            let address = try Address(from: safe.address!)

            currentDataTask = clientGatewayService.asyncBalances(address: address) { [weak self] result in
                guard let `self` = self else { return }
                switch result {
                case .failure(let error):
                    DispatchQueue.main.async { [weak self] in
                        guard let `self` = self else { return }
                        // ignore cancellation error due to cancelling the
                        // currently running task. Otherwise user will see
                        // meaningless message.
                        if (error as NSError).code == URLError.cancelled.rawValue &&
                            (error as NSError).domain == NSURLErrorDomain {
                            return
                        }
                        self.onError(GSError.error(description: "Failed to load balances", error: error))
                    }
                case .success(let summary):
                    DispatchQueue.main.async { [weak self] in
                        let results = summary.items.map { TokenBalance($0, code: AppSettings.selectedFiatCode) }
                        let total = TokenBalance.displayCurrency(from: summary.fiatTotal, code: AppSettings.selectedFiatCode)
                        guard let `self` = self else { return }
                        self.sections = self.makeSections(items: results, total: total)
                        self.onSuccess()
                    }
                }
            }
        } catch {
            onError(GSError.error(description: "Failed to load balances", error: error))
        }
    }

    private func makeSections(items: [TokenBalance], total: String) -> [Section] {
        guard !items.isEmpty else { return [] }

        var sections = [Section]()
        if shouldShowImportKeyBanner {
            sections.append(.importKeyBanner)
        } else if shouldShowPasscodeBanner {
            sections.append(.passcodeBanner)
        }
        sections.append(.total(text: total))
        sections.append(.balances(items: items))
        return sections
    }

    func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        switch sections[section] {
        case .importKeyBanner, .passcodeBanner, .total: return 1
        case .balances(items: let items): return items.count
        }
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        switch sections[indexPath.section] {
        case .importKeyBanner:
            return importKeyBanner(indexPath: indexPath)
        case .passcodeBanner:
            return createPasscodeBanner(indexPath: indexPath)
        case .total(text: let text):
            let cell = tableView.dequeueCell(TotalBalanceTableViewCell.self, for: indexPath)
            cell.setMainText("Total")
            cell.setDetailText(text)
            return cell
        case .balances(items: let items):
            let item = items[indexPath.row]
            let cell = tableView.dequeueCell(BalanceTableViewCell.self, for: indexPath)
            cell.setMainText(item.symbol)
            cell.setDetailText(item.balance)
            cell.setSubDetailText(item.fiatBalance)
            if let image = item.image {
                cell.setImage(image)
            } else {
                cell.setImage(with: item.imageURL, placeholder: UIImage(named: "ico-token-placeholder")!)
            }
            return cell
        }
    }

    private func importKeyBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader("Import owner key")
        cell.setBody("We added signing support to the app! Now you can import your owner key and sign transactions on the go.")
        cell.setButton("Import owner key now")
        cell.onClose = { [unowned self] in
            importKeyBannerWasShown = true

            recreateSectionsWithCurrentItems()

            trackEvent(.bannerImportOwnerKeySkipped)
        }
        cell.onImport = { [unowned self] in
            importKeyBannerWasShown = true

            recreateSectionsWithCurrentItems()

            let vc = ViewControllerFactory.addOwnerViewController(presenter: self)
            present(vc, animated: true)
            trackEvent(.bannerImportOwnerKeyImported)
        }
        return cell
    }

    private func createPasscodeBanner(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BannerTableViewCell.self, for: indexPath)
        cell.setHeader("Create passcode")
        cell.setBody("Secure your owner keys by setting up a passcode. The passcode will be needed to open the app and sign transactions.")
        cell.setButton("Create passcode now")
        cell.onClose = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            recreateSectionsWithCurrentItems()
        }
        cell.onImport = { [unowned self] in
            AppSettings.passcodeBannerDismissed = true
            recreateSectionsWithCurrentItems()

            let vc = CreatePasscodeViewController { [weak self] in
                self?.recreateSectionsWithCurrentItems()
            }
            let nav = UINavigationController(rootViewController: vc)
            present(nav, animated: true)
        }
        return cell
    }

    private func recreateSectionsWithCurrentItems() {
        var items = [TokenBalance]()
        var total = ""
        for section in sections {
            switch section {
            case .balances(items: let balances): items = balances
            case .total(text: let text): total = text
            default: continue
            }
        }
        sections = makeSections(items: items, total: total)
        tableView.reloadData()
    }
}
