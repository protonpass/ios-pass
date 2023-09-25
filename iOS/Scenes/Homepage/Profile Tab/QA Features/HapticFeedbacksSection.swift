//
// HapticFeedbacksSection.swift
// Proton Pass - Created on 15/04/2023.
// Copyright (c) 2023 Proton Technologies AG
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

import AVFoundation
import SwiftUI

struct HapticFeedbacksSection: View {
    @State private var isShowingAllOptions = false

    var body: some View {
        Section(content: {
            Group {
                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }, label: {
                    Text(verbatim: "Success")
                })

                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }, label: {
                    Text(verbatim: "Warning")
                })

                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }, label: {
                    Text(verbatim: "Error")
                })

                if !isShowingAllOptions {
                    Button(action: {
                        withAnimation {
                            isShowingAllOptions.toggle()
                        }
                    }, label: {
                        Text(verbatim: "Show more...")
                    })
                }
            }

            if isShowingAllOptions {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                }, label: {
                    Text("Light")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                }, label: {
                    Text(verbatim: "Medium")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
                }, label: {
                    Text(verbatim: "Heavy")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred()
                }, label: {
                    Text(verbatim: "Soft")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
                }, label: {
                    Text(verbatim: "Rigid")
                })

                Button(action: {
                    UISelectionFeedbackGenerator().selectionChanged()
                }, label: {
                    Text(verbatim: "Selection")
                })

                Button(action: {
                    AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
                }, label: {
                    Text(verbatim: "Old school")
                })

                NavigationLink(destination: { FineTunedHapticFeedbackView() },
                               label: { Text(verbatim: "Fine-tuned haptic feedbacks") })
            }
        }, header: {
            Label(title: {
                Text(verbatim: "Haptic feedbacks")
            }, icon: {
                Image(systemName: "iphone.radiowaves.left.and.right")
            })
        })
    }
}

private struct FineTunedHapticFeedbackView: View {
    @State private var intensity: CGFloat = 0.5

    var body: some View {
        Form {
            Section {
                VStack {
                    Text(verbatim: "Intensity \(intensity)")
                        .frame(maxWidth: .infinity, alignment: .leading)
                    Slider(value: $intensity, in: 0.0...1.0, step: 0.1)
                }
            }

            Section {
                Button(action: {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred(intensity: intensity)
                }, label: {
                    Text("Light")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred(intensity: intensity)
                }, label: {
                    Text(verbatim: "Medium")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: intensity)
                }, label: {
                    Text(verbatim: "Heavy")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
                }, label: {
                    Text(verbatim: "Soft")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: intensity)
                }, label: {
                    Text(verbatim: "Rigid")
                })
            }
        }
        .navigationTitle(Text(verbatim: "Fine-tuned haptic feedbacks"))
    }
}
