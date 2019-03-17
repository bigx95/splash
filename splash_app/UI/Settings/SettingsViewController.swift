//
//  SettingsViewController.swift
//  splash
//
//  Created by Gonzo Fialho on 17/03/19.
//  Copyright © 2019 Gonzo Fialho. All rights reserved.
//

import UIKit

class SettingsNavigationController: UINavigationController {

    init() {
        super.init(rootViewController: SettingsViewController())
    }

    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }

    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}
}

protocol CellConfigurator {
    var cellIdentifier: String {get}
    var cellClass: UITableViewCell.Type {get}

    func configure(_ cell: UITableViewCell, at indexPath: IndexPath, in viewController: SettingsViewController)
    func action(`for` indexPath: IndexPath) -> ((SettingsViewController) -> Void)?
}

protocol AppearanceAdjustable {
    func setupAppearance()
}

class SettingsViewController: UITableViewController {
    struct Section {
        let title: String?
        let rows: [CellConfigurator]
    }

    let items: [Section] = [
        Section(title: "Resources",
                rows: [
                    Link(name: "GitHub repo", url: URL(string: "https://github.com/gonzula/splash")!)
            ]),
        Section(title: "Appearance Settings",
                rows: [
                    Theme(),
                    FontSize()
            ])
    ]

    var observers = [Any]()

    init() {
        super.init(style: .grouped)
        tableView.rowHeight = 44

        self.items
            .flatMap {$0.rows}
            .reduce(into: [String: UITableViewCell.Type]()) {$0[$1.cellIdentifier] = $1.cellClass}
            .forEach {tableView.register($1, forCellReuseIdentifier: $0)}
    }

    required init?(coder aDecoder: NSCoder) {fatalError("init(coder:) has not been implemented")}

    override func viewDidLoad() {
        super.viewDidLoad()

        navigationItem.leftBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(self.doneTouched))

        observers.append(  // swiftlint:disable:next discarded_notification_center_observer
            NotificationCenter.default.addObserver(forName: .themeChanged,
                                                   object: nil,
                                                   queue: nil,
                                                   using: { [weak self] _ in
                                                    self?.setupAppearance()
            })
        )
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)

        setupAppearance()
    }

    private func setupAppearance() {
        let theme = ThemeManager.shared.theme
        navigationController?.navigationBar.barStyle = theme.navigationBarStyle
        view.backgroundColor = theme.tableViewBackgroundColor
        tableView.reloadData()
    }

    private func section(at index: Int) -> Section {
        return items[index]
    }

    private func item(at indexPath: IndexPath) -> CellConfigurator {
        return section(at: indexPath.section).rows[indexPath.row]
    }

    override func numberOfSections(in tableView: UITableView) -> Int {
        return self.items.count
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.section(at: section).rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let item = self.item(at: indexPath)
        let cell = tableView.dequeueReusableCell(withIdentifier: item.cellIdentifier, for: indexPath)
        item.configure(cell, at: indexPath, in: self)

        return cell
    }

    override func tableView(_ tableView: UITableView, titleForHeaderInSection section: Int) -> String? {
        return self.section(at: section).title
    }

    override func tableView(_ tableView: UITableView,
                            willDisplay cell: UITableViewCell,
                            forRowAt indexPath: IndexPath) {
        (cell as? AppearanceAdjustable)?.setupAppearance()
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        self.item(at: indexPath).action(for: indexPath)?(self)
    }

    // MARK: - User Interaction

    @objc
    func doneTouched() {
        dismiss(animated: true)
    }
}
