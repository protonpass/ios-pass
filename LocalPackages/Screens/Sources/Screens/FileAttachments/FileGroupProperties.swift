//
// FileGroupProperties.swift
// Proton Pass - Created on 27/11/2024.
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

import DesignSystem
import Entities
import UIKit

public extension FileGroup {
    var icon: UIImage {
        switch self {
        case .image:
            PassIcon.fileTypeImage
        case .photo:
            PassIcon.fileTypePhoto
        case .vectorImage:
            PassIcon.fileTypeVectorImage
        case .video:
            PassIcon.fileTypeVideo
        case .audio:
            PassIcon.fileTypeAudio
        case .key:
            PassIcon.fileTypeKey
        case .text:
            PassIcon.fileTypeText
        case .calendar:
            PassIcon.fileTypeCalendar
        case .pdf:
            PassIcon.fileTypePdf
        case .word:
            PassIcon.fileTypeWord
        case .powerPoint:
            PassIcon.fileTypePowerPoint
        case .excel:
            PassIcon.fileTypeExcel
        case .document:
            PassIcon.fileTypeDocument
        case .unknown:
            PassIcon.fileTypeUnknown
        }
    }
}
