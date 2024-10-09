//
// TableView.swift
// Proton Pass - Created on 27/09/2024.
// Copyright (c) 2024 Proton Technologies AG
//
// This file is part of Proton Pass.
//
// Proton Pass is free software: you can redistribute it and/or modify
// it under the terms of the GNU General Public License as published by
// the Free Software Foundation, either version 3 of the License, or
// (at your option) any later version.
//
// Proton Pass is distributed in the hope that it will be useful,
// but WITHOUT ANY WARRANTY; without even the implied warranty of
// MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
// GNU General Public License for more details.
//
// You should have received a copy of the GNU General Public License
// along with Proton Pass. If not, see https://www.gnu.org/licenses/.
//

import SwiftUI

private let kCellId = "cell"

public typealias HashableSendable = Hashable & Sendable

public final class PassDiffableDataSource<Section: HashableSendable, Item: HashableSendable>:
    UITableViewDiffableDataSource<Section, Item> {
    var sectionTitles: [String]?

    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        if let sectionTitles, sectionTitles.allSatisfy({ $0.count == 1 }) {
            sectionTitles
        } else {
            nil
        }
    }

    override public func tableView(_ tableView: UITableView,
                                   titleForHeaderInSection section: Int) -> String? {
        sectionTitles?[safeIndex: section]
    }
}

public struct TableView<Item: HashableSendable, ItemCell: View>: UIViewRepresentable {
    public struct Section {
        let title: String
        let items: [Item]

        public init(title: String, items: [Item]) {
            self.title = title
            self.items = items
        }
    }

    let sections: [Section]
    let itemCell: (Item) -> ItemCell

    public init(sections: [Section], itemCell: @escaping (Item) -> ItemCell) {
        self.sections = sections
        self.itemCell = itemCell
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView()
        tableView.sectionIndexColor = PassColor.interactionNorm
        tableView.backgroundColor = .clear
        tableView.separatorColor = .clear
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellId)
        context.coordinator.configureDataSource(for: tableView)
        return tableView
    }

    public func updateUIView(_ tableView: UITableView, context: Context) {
        context.coordinator.updateTable(with: sections)
    }

    public final class Coordinator: NSObject {
        var parent: TableView
        var dataSource: PassDiffableDataSource<String, Item>!

        init(_ parent: TableView) {
            self.parent = parent
        }

        func configureDataSource(for tableView: UITableView) {
            dataSource = PassDiffableDataSource<String,
                Item>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
                    let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    cell.contentConfiguration = UIHostingConfiguration {
                        self.parent.itemCell(item)
                    }
                    // A combination of minSize and magins to remove the vertical padding
                    .minSize(width: 0, height: 0)
                    .margins(.vertical, 0)
                    return cell
                }
            dataSource.defaultRowAnimation = .fade
        }

        func updateTable(with sections: [Section]) {
            var snapshot = NSDiffableDataSourceSnapshot<String, Item>()
            snapshot.appendSections(sections.map(\.title))
            for section in sections {
                snapshot.appendItems(section.items, toSection: section.title)
            }
            dataSource.sectionTitles = sections.map(\.title)
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}
