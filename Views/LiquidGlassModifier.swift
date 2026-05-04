//
//  LiquidGlassModifier.swift
//  Cekrec
//
//  Created by Antigravity on 04/05/26.
//

import SwiftUI

// MARK: - Liquid Glass Bar

/// A reusable liquid glass container for toolbars and controls,
/// following the iOS 26 Liquid Glass design language.
struct LiquidGlassBar<Content: View>: View {
    let cornerRadius: CGFloat
    @ViewBuilder let content: () -> Content

    init(cornerRadius: CGFloat = 26, @ViewBuilder content: @escaping () -> Content) {
        self.cornerRadius = cornerRadius
        self.content = content
    }

    var body: some View {
        content()
            .padding(.horizontal, 20)
            .padding(.vertical, 12)
            .glassEffect(in: .capsule)
    }
}

// MARK: - Liquid Glass Button

/// An individual glass-styled icon button.
struct LiquidGlassButton: View {
    let icon: String
    let label: String
    let role: ButtonRole?
    let action: () -> Void

    init(
        icon: String,
        label: String,
        role: ButtonRole? = nil,
        action: @escaping () -> Void
    ) {
        self.icon = icon
        self.label = label
        self.role = role
        self.action = action
    }

    var body: some View {
        Button(role: role, action: action) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title3)
                    .fontWeight(.medium)
                Text(label)
                    .font(.caption2)
                    .fontWeight(.medium)
            }
            .foregroundStyle(.white)
            .frame(minWidth: 56)
        }
    }
}

// MARK: - Glass Icon Button (compact)

/// Compact circular glass button for toolbar actions.
struct GlassIconButton: View {
    let icon: String
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.body.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 36, height: 36)
                .glassEffect(in: .circle)
        }
    }
}
