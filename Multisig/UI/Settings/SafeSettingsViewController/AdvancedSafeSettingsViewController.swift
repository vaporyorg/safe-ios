//
//  AdvancedSafeSettingsViewController.swift
//  Multisig
//
//  Created by Moaaz on 2/3/21.
//  Copyright © 2021 Gnosis Ltd. All rights reserved.
//

import UIKit

fileprivate protocol SectionItem {}

class AdvancedSafeSettingsViewController: UITableViewController {    
    private typealias SectionItems = (section: Section, items: [SectionItem])

    private var safe: Safe!
    private var sections = [SectionItems]()

    var namingPolicy = DefaultAddressNamingPolicy()

    enum Section {
        case fallbackHandler(String)
        case nonce(String)
        case modules(String)

        enum FallbackHandler: SectionItem {
            case fallbackHandler(AddressInfo?)
            case fallbackHandlerHelpLink
        }

        enum Nonce: SectionItem {
            case nonce(String)
        }

        enum Module: SectionItem {
            case module(AddressInfo)
        }

    }

    override func viewDidLoad() {
        super.viewDidLoad()

        do {
            safe = try Safe.getSelected()!
            buildSections()
        } catch {
            fatalError()
        }

        navigationItem.title = "Advanced"
        tableView.registerCell(BasicCell.self)
        tableView.registerCell(DetailAccountCell.self)
        tableView.registerCell(HelpLinkTableViewCell.self)
        tableView.registerHeaderFooterView(BasicHeaderView.self)
        tableView.backgroundColor = .secondaryBackground
    }

    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        trackEvent(.settingsSafeAdvanced)
    }

    private func buildSections() {
        sections = [
            (section: .fallbackHandler("FALLBACK HANDLER"),
             items: [Section.FallbackHandler.fallbackHandler(App.shared.gnosisSafe.fallbackHandlerInfo(safe.fallbackHandlerInfo)),
                     Section.FallbackHandler.fallbackHandlerHelpLink]),

            (section: .nonce("NONCE"),
             items: [Section.Nonce.nonce(safe.nonce?.description ?? "0")]),
        ]

        if let modules = safe.modulesInfo, !modules.isEmpty {
            sections += [
                (section: .modules("ADDRESSES OF ENABLED MODULES"),
                 items: modules.map { Section.Module.module($0) })
            ]
        }
    }
}

extension AdvancedSafeSettingsViewController {
    override func numberOfSections(in tableView: UITableView) -> Int {
        sections.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        sections[section].items.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.FallbackHandler.fallbackHandler(let info):
            if let info = info {
                return addressDetailsCell(address: info.address, title: namingPolicy.name(info: info), imageUri: info.logoUri, indexPath: indexPath)
            } else {
                return basicCell(name: "Not set", indexPath: indexPath)
            }
        case Section.FallbackHandler.fallbackHandlerHelpLink:
            return fallbackHandlerHelpLinkCell(indexPath: indexPath)
        case Section.Nonce.nonce(let nonce):
            return basicCell(name: nonce, indexPath: indexPath)
        case Section.Module.module(let info):
            return addressDetailsCell(address: info.address, title: namingPolicy.name(info: info), imageUri: info.logoUri, indexPath: indexPath)
        default:
            return UITableViewCell()
        }
    }

    override func tableView(_ tableView: UITableView, viewForHeaderInSection _section: Int) -> UIView? {
        let section = sections[_section].section
        let view = tableView.dequeueHeaderFooterView(BasicHeaderView.self)
        switch section {
        case Section.fallbackHandler(let name):
            view.setName(name)

        case Section.nonce(let name):
            view.setName(name)

        case Section.modules(let name):
            view.setName(name)
        }

        return view
    }

    override func tableView(_ tableView: UITableView, heightForHeaderInSection _section: Int) -> CGFloat {
        return BasicHeaderView.headerHeight
    }

    override func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        let item = sections[indexPath.section].items[indexPath.row]
        switch item {
        case Section.FallbackHandler.fallbackHandler(let info):
            if info == nil {
                return BasicCell.rowHeight
            }
        case Section.Nonce.nonce:
            return BasicCell.rowHeight
        default:
            break
        }
        return UITableView.automaticDimension
    }

    override func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        BasicCell.rowHeight
    }

    private func basicCell(name: String, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(BasicCell.self, for: indexPath)
        cell.setTitle(name)
        cell.setDisclosureImage(nil)
        cell.selectionStyle = .none
        return cell
    }

    private func addressDetailsCell(address: Address, title: String?, imageUri: URL?, indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(DetailAccountCell.self, for: indexPath)
        cell.setAccount(address: address, label: title, imageUri: imageUri)
        return cell
    }

    private func fallbackHandlerHelpLinkCell(indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueCell(HelpLinkTableViewCell.self, for: indexPath)
        return cell
    }
}
