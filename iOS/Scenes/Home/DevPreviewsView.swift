//
// DevPreviewsView.swift
// Proton Pass - Created on 07/12/2022.
// Copyright (c) 2022 Proton Technologies AG
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
import Client
import Core
import SwiftUI
import UIComponents

/// Preview features under development
struct DevPreviewsView: View {
    let credentialManager: CredentialManagerProtocol
    let preferences: Preferences
    let bannerManager: BannerManager

    var body: some View {
        NavigationView {
            Form {
                OnboardingSection(credentialManager: credentialManager,
                                  preferences: preferences,
                                  bannerManager: bannerManager)
                HapticFeedbacksSection()
            }
            .navigationTitle("Developer previews")
            .navigationBarTitleDisplayMode(.large)
        }
        .accentColor(.interactionNorm)
    }
}

private struct OnboardingSection: View {
    @State private var isShowing = false
    let credentialManager: CredentialManagerProtocol
    let preferences: Preferences
    let bannerManager: BannerManager

    var body: some View {
        Section(content: {
            Button(action: {
                isShowing.toggle()
            }, label: {
                Text("Trigger onboarding process")
            })
        })
        .fullScreenCover(isPresented: $isShowing, content: {
            OnboardingView(viewModel: .init(credentialManager: credentialManager,
                                            preferences: preferences,
                                            bannerManager: bannerManager))
        })
    }
}

private struct HapticFeedbacksSection: View {
    var body: some View {
        Section(content: {
            Group {
                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.success)
                }, label: {
                    Text("Success")
                })

                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.warning)
                }, label: {
                    Text("Warning")
                })

                Button(action: {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                }, label: {
                    Text("Error")
                })
            }

            Button(action: {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }, label: {
                Text("Light")
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
            }, label: {
                Text("Medium")
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .heavy).impactOccurred()
            }, label: {
                Text("Heavy")
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .soft).impactOccurred()
            }, label: {
                Text("Soft")
            })

            Button(action: {
                UIImpactFeedbackGenerator(style: .rigid).impactOccurred()
            }, label: {
                Text("Rigid")
            })

            Button(action: {
                UISelectionFeedbackGenerator().selectionChanged()
            }, label: {
                Text("Selection")
            })

            Button(action: {
                AudioServicesPlaySystemSound(SystemSoundID(kSystemSoundID_Vibrate))
            }, label: {
                Text("Old school")
            })

            NavigationLink(destination: { FineTunedHapticFeedbackView() },
                           label: { Text("Fine-tuned haptic feedbacks") })
        }, header: {
            Text("Haptic feedbacks")
        })
    }
}

private struct FineTunedHapticFeedbackView: View {
    @State private var intensity: CGFloat = 0.5
    var body: some View {
        Form {
            Section {
                VStack {
                    Text("Intensity \(intensity)")
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
                    Text("Medium")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .heavy).impactOccurred(intensity: intensity)
                }, label: {
                    Text("Heavy")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .soft).impactOccurred(intensity: intensity)
                }, label: {
                    Text("Soft")
                })

                Button(action: {
                    UIImpactFeedbackGenerator(style: .rigid).impactOccurred(intensity: intensity)
                }, label: {
                    Text("Rigid")
                })
            }
        }
        .navigationTitle("Fine-tuned haptic feedbacks")
    }
}
