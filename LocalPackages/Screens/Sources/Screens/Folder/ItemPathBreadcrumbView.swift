//
// ItemPathBreadcrumbView.swift
// Proton Pass - Created on 05/02/2026.
// Copyright (c) 2026 Proton Technologies AG
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

import DesignSystem
import Entities
import ProtonCoreUIFoundations
import SwiftUI

private enum PathElement: Identifiable {
    case ellipsis
    case folder(FolderUiModel)

    var id: String {
        switch self {
        case .ellipsis: "ellipsis"
        case let .folder(folder): folder.folderId
        }
    }
}

public struct ItemPathBreadcrumbView: View {
    let vaultContent: VaultContent
    let path: [FolderUiModel]
    @State private var expanded: Bool = false

    public init(vaultContent: VaultContent, path: [FolderUiModel]) {
        self.vaultContent = vaultContent
        self.path = path
        expanded = expanded
    }

    public var body: some View {
        if path.isEmpty {
            EmptyView()
        } else {
            Button { expanded.toggle() } label: {
                breadcrumb
            }
            .padding(DesignConstant.sectionPadding)
            .roundedDetailSection()
            .animation(.default, value: expanded)
        }
    }
}

private extension ItemPathBreadcrumbView {
    var pathElements: [PathElement] {
        if expanded || path.count == 1 {
            path.map { .folder($0) }
        } else if let lastFolder = path.last {
            [.ellipsis, .folder(lastFolder)]
        } else {
            []
        }
    }

    var breadcrumb: some View {
        AnyLayout(FlowLayout(spacing: 8)) {
            Label(title: {
                Text(vaultContent.name)
                    .foregroundStyle(PassColor.textWeak)
            }, icon: {
                vaultContent.vaultSmallIcon
                    .resizable()
                    .foregroundStyle(vaultContent.mainColor)
                    .scaledToFit()
                    .frame(width: 16, height: 16)
            })

            ForEach(pathElements) { element in
                switch element {
                case .ellipsis:
                    ellipsis
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))

                case let .folder(folder):
                    folderElement(folder: folder)
                        .transition(.asymmetric(insertion: .move(edge: .leading).combined(with: .opacity),
                                                removal: .move(edge: .leading).combined(with: .opacity)))
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var ellipsis: some View {
        HStack(spacing: 4) {
            IconProvider.chevronRight
                .resizable()
                .foregroundStyle(PassColor.textWeak)
                .frame(width: 16, height: 16)
            Text(verbatim: "...")
                .foregroundStyle(PassColor.textWeak)
        }
    }

    @ViewBuilder
    func folderElement(folder: FolderUiModel) -> some View {
        let isLast = folder == path.last
        HStack(spacing: 4) {
            IconProvider.chevronRight
                .resizable()
                .foregroundStyle(PassColor.textWeak)
                .frame(width: 16, height: 16)
            Label {
                Text(verbatim: folder.content.name)
                    .fontWeight(isLast ? .bold : .regular)
                    .foregroundStyle(isLast ? PassColor.textNorm : PassColor.textWeak)
            } icon: {
                IconProvider.foldersFilled
                    .resizable()
                    .foregroundStyle(PassColor.folderIcon)
                    .frame(width: 16, height: 16)
            }
        }
    }
}
