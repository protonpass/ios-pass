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

private let kAnimationThreshold = 500
private let kHeaderId = "header"
private let kCellId = "cell"

private struct PassSectionIdentifier: Sendable, Hashable {
    let id: Int
    let title: String

    /// We can't init `id` directly as `AnyHashable` because `AnyHashable` is not `Sendable`
    /// so we manually map the `type` and `title` to a unique `id` as an `Int`
    init(type: AnyHashable, title: String) {
        var hasher = Hasher()
        hasher.combine(type)
        hasher.combine(title)
        id = hasher.finalize()
        self.title = title
    }
}

final class PassDiffableDataSource<Section: Hashable, Item: Hashable>:
    UITableViewDiffableDataSource<Section, Item> {
    var lastId: Int?
    var sectionIndexTitles: (() -> [String]?)?
    var titleForHeader: ((Int) -> String?)?

    override public func sectionIndexTitles(for tableView: UITableView) -> [String]? {
        sectionIndexTitles?()
    }

    override public func tableView(_ tableView: UITableView,
                                   titleForHeaderInSection section: Int) -> String? {
        titleForHeader?(section)
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

    let refreshControl = UIRefreshControl()
    let onRefresh: (() async -> Void)?

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
                headerView: @escaping (_ sectionIndex: Int) -> HeaderView?,
                onRefresh: (() async -> Void)? = nil) {
        self.sections = sections
        self.configuration = configuration
        self.id = id
        self.itemView = itemView
        self.headerView = headerView
        self.onRefresh = onRefresh
    }

    public func makeCoordinator() -> Coordinator {
        Coordinator(self, configuration: configuration)
    }

    public func makeUIView(context: Context) -> UITableView {
        let tableView = UITableView()
        tableView.sectionIndexColor = configuration.sectionIndexColor
        tableView.backgroundColor = configuration.backgroundColor
        tableView.separatorColor = configuration.separatorColor
        tableView.layoutMargins = .zero
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: kCellId)
        tableView.delegate = context.coordinator
        if onRefresh != nil {
            refreshControl.addTarget(context.coordinator,
                                     action: #selector(Coordinator.handleRefresh),
                                     for: .valueChanged)
            tableView.refreshControl = refreshControl
        }
        context.coordinator.configureDataSource(for: tableView)
        return tableView
    }

    public func updateUIView(_ tableView: UITableView, context: Context) {
        context.coordinator.updateTable(with: sections,
                                        configuration: configuration,
                                        id: id)
    }

    public final class Coordinator: NSObject, UITableViewDelegate {
        let parent: TableView
        private var dataSource: PassDiffableDataSource<PassSectionIdentifier, Item>!
        private var configuration: TableViewConfiguration

        init(_ parent: TableView, configuration: TableViewConfiguration) {
            self.parent = parent
            self.configuration = configuration
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

        public func tableView(_ tableView: UITableView, heightForHeaderInSection section: Int) -> CGFloat {
            if parent.headerView(section) == nil,
               dataSource.titleForHeader?(section)?.isEmpty == true {
                0
            } else {
                UITableView.automaticDimension
            }
        }

        func configureDataSource(for tableView: UITableView) {
            dataSource = PassDiffableDataSource<PassSectionIdentifier,
                Item>(tableView: tableView) { tableView, indexPath, item -> UITableViewCell? in
                    let cell = tableView.dequeueReusableCell(withIdentifier: kCellId, for: indexPath)
                    cell.backgroundColor = .clear
                    cell.contentView.backgroundColor = .clear
                    cell.layoutMargins = .zero
                    cell.separatorInset = .zero
                    cell.contentConfiguration = UIHostingConfiguration {
                        self.parent
                            .itemView(item)
                            .padding(.bottom, self.configuration.rowSpacing)
                    }
                    // A combination of minSize and magins to remove the vertical padding
                    .minSize(width: 0, height: 0)
                    .margins(.vertical, 0)
                    return cell
                }

            dataSource.sectionIndexTitles = { [weak self] in
                guard let self else { return nil }
                return configuration.showSectionIndexTitles ?
                    dataSource.snapshot().sectionIdentifiers.map(\.title) : nil
            }

            dataSource.titleForHeader = { [weak self] section in
                guard let self else { return nil }
                return dataSource.snapshot().sectionIdentifiers[safeIndex: section]?.title
            }

            dataSource.defaultRowAnimation = .bottom
        }

        func updateTable(with sections: [Section],
                         configuration: TableViewConfiguration,
                         id: Int?) {
            self.configuration = configuration
            var snapshot = NSDiffableDataSourceSnapshot<PassSectionIdentifier, Item>()
            let itemCount = sections.map(\.items.count).reduce(0) { $0 + $1 }

            for section in sections {
                let sectionId = PassSectionIdentifier(type: section.type, title: section.title)
                snapshot.appendSections([sectionId])
                snapshot.appendItems(section.items, toSection: sectionId)
            }

            if itemCount > kAnimationThreshold || dataSource.lastId != id {
                dataSource.applySnapshotUsingReloadData(snapshot)
            } else {
                dataSource.apply(snapshot, animatingDifferences: true)
            }
            dataSource.lastId = id
        }

        @objc
        func handleRefresh() {
            guard let onRefresh = parent.onRefresh else { return }
            Task { [weak self] in
                guard let self else { return }
                await onRefresh()
                parent.refreshControl.endRefreshing()
            }
        }
    }
}
