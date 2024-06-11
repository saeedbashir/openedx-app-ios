//
//  ResponsiveView.swift
//  Core
//
//  Created by  Stepanok Ivan on 26.03.2024.
//

import SwiftUI

private struct SensitiveKey: EnvironmentKey {
    static let defaultValue: Bool = false
}

public extension EnvironmentValues {
    var shouldHideMenuBar: Bool {
        get { self[SensitiveKey.self] }
        set { self[SensitiveKey.self] = newValue }
    }
}

public struct DynamicOffsetView: View {
    
    private let padHeight: CGFloat = 290
    private let collapsedVerticalHeight: CGFloat = 100
    private let coordinateBoundaryLower: CGFloat = -115
    private var idiom: UIUserInterfaceIdiom { UIDevice.current.userInterfaceIdiom }
    @Binding private var shouldShowUpgradeButton: Bool
    
    @Binding private var coordinate: CGFloat
    @Binding private var collapsed: Bool
    @State private var collapseHeight: CGFloat = .zero
    
    @Environment(\.isHorizontal) private var isHorizontal
    @Environment(\.shouldHideMenuBar) private var shouldHideMenuBar
    
    public init(
        coordinate: Binding<CGFloat>,
        collapsed: Binding<Bool>,
        shouldShowUpgradeButton: Binding<Bool>
    ) {
        self._coordinate = coordinate
        self._collapsed = collapsed
        self._shouldShowUpgradeButton = shouldShowUpgradeButton
    }
    
    public var body: some View {
        VStack {
            Color.blue
        }
        .frame(height: collapseHeight)
        .overlay(
            GeometryReader { geometry -> Color in
                guard idiom != .pad else {
                    return .clear
                }
                guard !isHorizontal else {
                    DispatchQueue.main.async {
                        coordinate = coordinateBoundaryLower
                    }
                    return .clear
                }
                DispatchQueue.main.async {
                    coordinate = geometry.frame(in: .global).minY
                }
                return .clear
            }
        )
        .onAppear {
            changeCollapsedHeight(
                collapsed: collapsed,
                isHorizontal: isHorizontal,
                shouldShowUpgradeButton: shouldShowUpgradeButton,
                shouldHideMenuBar: shouldHideMenuBar
            )
        }
        .onChange(of: shouldHideMenuBar) { shouldHideMenuBar in
            changeCollapsedHeight(
                collapsed: collapsed,
                isHorizontal: isHorizontal,
                shouldShowUpgradeButton: shouldShowUpgradeButton,
                shouldHideMenuBar: shouldHideMenuBar
            )
        }
        .onChange(of: shouldShowUpgradeButton) { shouldShowUpgradeButton in
            changeCollapsedHeight(
                collapsed: collapsed,
                isHorizontal: isHorizontal,
                shouldShowUpgradeButton: shouldShowUpgradeButton,
                shouldHideMenuBar: shouldHideMenuBar
            )
        }
        .onChange(of: collapsed) { collapsed in
            if !collapsed {
                changeCollapsedHeight(
                    collapsed: collapsed,
                    isHorizontal: isHorizontal,
                    shouldShowUpgradeButton: shouldShowUpgradeButton,
                    shouldHideMenuBar: shouldHideMenuBar
                )
            }
        }
        .onChange(of: isHorizontal) { isHorizontal in
            if isHorizontal {
                collapsed = true
            }
            changeCollapsedHeight(
                collapsed: collapsed,
                isHorizontal: isHorizontal,
                shouldShowUpgradeButton: shouldShowUpgradeButton,
                shouldHideMenuBar: shouldHideMenuBar
            )
        }
    }
    
    private func collapsedHorizontalHeight(shouldHideMenuBar: Bool) -> CGFloat {
        120 - (shouldHideMenuBar ? 50 : 0)
    }
    
    private func expandedHeight(shouldShowUpgradeButton: Bool, shouldHideMenuBar: Bool) -> CGFloat {
        240 + (shouldShowUpgradeButton ? 83 : 0) - (shouldHideMenuBar ? 20 : 0)
    }

    private func changeCollapsedHeight(
        collapsed: Bool,
        isHorizontal: Bool,
        shouldShowUpgradeButton: Bool,
        shouldHideMenuBar: Bool
    ) {
        if idiom == .pad {
            collapseHeight = padHeight
        } else if collapsed {
            if isHorizontal {
                collapseHeight = collapsedHorizontalHeight(shouldHideMenuBar: shouldHideMenuBar)
            } else {
                collapseHeight = collapsedVerticalHeight
            }
        } else {
            collapseHeight = expandedHeight(
                shouldShowUpgradeButton: shouldShowUpgradeButton,
                shouldHideMenuBar: shouldHideMenuBar
            )
        }
    }
}
