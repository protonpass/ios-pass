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

private let kHeaderId = "header"
private let kCellId = "cell"

public final class PassDiffableDataSource<Section: Hashable, Item: TableViewItemConformance>:
    UITableViewDiffableDataSource<Section, Item> {
    var sectionTitles: [String]?
    var showSectionIndexTitles = false
    var lastId: Int?

    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        showSectionIndexTitles ? sectionTitles : nil
    }

    override public func tableView(_ tableView: UITableView,
                                   titleForHeaderInSection section: Int) -> String? {
        sectionTitles?[safeIndex: section]
    }
}

public struct TableViewConfiguration {
    let showSectionIndexTitles: Bool
    let rowSpacing: CGFloat
    let sectionIndexColor: UIColor
    let backgroundColor: UIColor
    let separatorColor: UIColor

    public init(showSectionIndexTitles: Bool = false,
                rowSpacing: CGFloat = 0,
                sectionIndexColor: UIColor = PassColor.interactionNorm,
                backgroundColor: UIColor = .clear,
                separatorColor: UIColor = .clear) {
        self.showSectionIndexTitles = showSectionIndexTitles
        self.rowSpacing = rowSpacing
        self.sectionIndexColor = sectionIndexColor
        self.backgroundColor = backgroundColor
        self.separatorColor = separatorColor
    }
}

public typealias TableViewItemConformance = Hashable & Sendable

public struct TableView<Item: TableViewItemConformance, ItemView: View, HeaderView: View>: UIViewRepresentable {
    public struct Section: Hashable, Equatable {
        public let type: AnyHashable
        public let title: String
        public let items: [Item]

        public init(type: AnyHashable,
                    title: String,
                    items: [Item]) {
            self.type = type
            self.title = title
            self.items = items
        }
    }

    let sections: [Section]
    let configuration: TableViewConfiguration
    let itemView: (Item) -> ItemView
    /// Custom header view, pass `nil` to use the default text header
    let headerView: (_ sectionIndex: Int) -> HeaderView?

    /// Set `id` to force refreshing the table because relying on `UITableViewDiffableDataSource`
    /// is not enough in some cases, e.g 2 snapshots may be completely different but the first visible items are
    /// the same
    ///
    /// Practical example:
    /// When listing all items,  switching between `All accounts` and precise account might result
    /// in the same visible first items but we want to render the items differently (show or not show user's email)
    /// So we need to force refresh the UI even though visible items stay unchanged.
    let id: Int?

    public init(sections: [Section],
                configuration: TableViewConfiguration,
                id: Int?,
                itemView: @escaping (Item) -> ItemView,
                headerView: @escaping (_ sectionIndex: Int) -> HeaderView?) {
        self.sections = sections
        self.configuration = configuration
        self.id = id
        self.itemView = itemView
        self.headerView = headerView
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }

    public func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView()
        tableView.sectionIndexColor = configuration.sectionIndexColor
        tableView.backgroundColor = configuration.backgroundColor
        tableView.separatorColor = configuration.separatorColor
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellId)
        tableView.delegate = context.coordinator
        context.coordinator.configureDataSource(for: tableView)
        return tableView
    }

    public func updateUIView(_ tableView: UITableView, context: Context) {
        context.coordinator.updateTable(with: sections,
                                        showSectionIndexTitles: configuration.showSectionIndexTitles,
                                        id: id)
    }

    public final class Coordinator: NSObject, UITableViewDelegate {
        var parent: TableView
        var dataSource: PassDiffableDataSource<String, Item>!

        init(_ parent: TableView) {
            self.parent = parent
        }

        public func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
            guard let headerView = parent.headerView(section) else { return nil }
            let view = tableView.dequeueReusableHeaderFooterView(withIdentifier: kHeaderId)
                ?? UITableViewHeaderFooterView(reuseIdentifier: kHeaderId)
            view.contentConfiguration = UIHostingConfiguration {
                headerView
            }
            return view
        }

        func configureDataSource(for tableView: UITableView) {
            dataSource = PassDiffableDataSource<String,
                Item>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
                    let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    cell.contentConfiguration = UIHostingConfiguration {
                        self.parent
                            .itemView(item)
                            .padding(.bottom, self.parent.configuration.rowSpacing)
                    }
                    // A combination of minSize and magins to remove the vertical padding
                    .minSize(width: 0, height: 0)
                    .margins(.vertical, 0)
                    return cell
                }
            dataSource.defaultRowAnimation = .fade
        }

        func updateTable(with sections: [Section],
                         showSectionIndexTitles: Bool,
                         id: Int?) {
            var snapshot = NSDiffableDataSourceSnapshot<String, Item>()
            if dataSource.lastId != id {
                // Force refresh by providing an empty snapshot
                dataSource.apply(snapshot, animatingDifferences: false)
            }

            let sectionTitles = sections.map(\.title)
            snapshot.appendSections(sectionTitles)
            for section in sections {
                snapshot.appendItems(section.items, toSection: section.title)
            }

            dataSource.sectionTitles = sectionTitles
            dataSource.showSectionIndexTitles = showSectionIndexTitles
            dataSource.lastId = id
            dataSource.apply(snapshot, animatingDifferences: true)
        }
    }
}
