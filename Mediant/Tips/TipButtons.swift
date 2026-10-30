import SwiftUI

/// The four tip buttons, shared by Settings and the just-emptied Trash. They sit in one row of
/// equal buttons when the prices fit, else in a 2 × 2 grid, else in one column. A price never
/// shrinks, wraps or gets cut. Nothing is shown when the tips cannot load: the place says that.
struct TipButtons: View {
    enum Style { case glass, pink }

    let place: TipJar.Place
    let style: Style

    @Environment(AppModel.self) private var model
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var glowCount = 0
    @State private var hapticCount = 0

    private var tips: TipJar { model.tips }

    var body: some View {
        content
            .background(glow)
            .task { await tips.loadIfNeeded() }
            .onChange(of: tips.celebration) { _, celebration in
                // With Reduce Motion off, the fireworks overlay shows the success and taps the haptic.
                guard reduceMotion, let celebration, celebration.place == place else { return }
                glowCount += 1
                hapticCount += 1
            }
            .sensoryFeedback(.impact, trigger: hapticCount)
    }

    @ViewBuilder
    private var content: some View {
        switch tips.load {
        case .loading:
            EqualGrid(columns: 4) {
                ForEach(0..<4, id: \.self) { _ in
                    Capsule().fill(style.fill).frame(height: Self.height)
                }
            }
            .shimmering(true)
            .accessibilityHidden(true)
        case .loaded(let products):
            fitting(products)
        case .unavailable:
            EmptyView()
        }
    }

    /// One row, then 2 × 2, then one column: the first that fits the width at the normal font size.
    private func fitting(_ products: [TipProduct]) -> some View {
        ViewThatFits(in: .horizontal) {
            EqualGrid(columns: 4) { buttons(products) }
            EqualGrid(columns: 2) { buttons(products) }
            EqualGrid(columns: 1) { buttons(products) }
        }
    }

    private func buttons(_ products: [TipProduct]) -> some View {
        ForEach(products, id: \.id) { button(for: $0) }
    }

    private func button(for product: TipProduct) -> some View {
        let isBuying = tips.purchasing?.productID == product.id
        return Button {
            Task { await tips.buy(product, from: place) }
        } label: {
            Text(product.displayPrice)
                .font(.system(size: 15, weight: .bold))
                .monospacedDigit()
                .fixedSize()
                .opacity(isBuying ? 0 : 1)
                .overlay { if isBuying { ProgressView().tint(style.text) } }
                .foregroundStyle(style.text)
                .padding(.horizontal, 12)
                .frame(maxWidth: .infinity, minHeight: Self.height)
                .background(Capsule().fill(style.fill))
                .overlay(Capsule().strokeBorder(style.border, lineWidth: 1))
                .contentShape(Capsule())
        }
        .buttonStyle(.plain)
        .disabled(tips.purchasing != nil)
        .accessibilityLabel("Tip, \(product.displayPrice)")
    }

    /// Reduce Motion only: a soft pink glow that fades over 1 s.
    private var glow: some View {
        Capsule()
            .fill(Color(red: 1, green: 0.22, blue: 0.37))
            .blur(radius: 18)
            .padding(.horizontal, -8)
            .keyframeAnimator(initialValue: 0.0, trigger: glowCount) { content, opacity in
                content.opacity(opacity * 0.55)
            } keyframes: { _ in
                LinearKeyframe(1.0, duration: 0.1)
                CubicKeyframe(0.0, duration: 0.9)
            }
            .allowsHitTesting(false)
            .accessibilityHidden(true)
    }

    private static let height: CGFloat = 32
}

private extension TipButtons.Style {
    var fill: Color {
        switch self {
        case .glass: .white.opacity(0.14)
        case .pink: Color(red: 1, green: 0.216, blue: 0.373).opacity(0.18)  // #ff375f
        }
    }

    var border: Color {
        switch self {
        case .glass: .white.opacity(0.22)
        case .pink: Color(red: 1, green: 0.361, blue: 0.576).opacity(0.40)  // #ff5c93
        }
    }

    var text: Color {
        switch self {
        case .glass: .white
        case .pink: Color(red: 1, green: 0.702, blue: 0.769)  // #ffb3c4
        }
    }
}

/// Equal-width cells in `columns` columns, 8 pt apart. Its ideal width is the widest cell times
/// the columns, so `ViewThatFits` takes it only when every cell fits at the normal size.
private struct EqualGrid: Layout {
    let columns: Int
    private let spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let cell = cellSize(subviews)
        let needed = cell.width * CGFloat(columns) + spacing * CGFloat(columns - 1)
        let rows = (subviews.count + columns - 1) / columns
        let height = cell.height * CGFloat(rows) + spacing * CGFloat(max(rows - 1, 0))
        // Never narrower than needed: a proposal that is too small shows as "does not fit".
        return CGSize(width: max(needed, proposal.width ?? needed), height: height)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let cell = cellSize(subviews)
        let width = (bounds.width - spacing * CGFloat(columns - 1)) / CGFloat(columns)
        for (index, subview) in subviews.enumerated() {
            let x = bounds.minX + CGFloat(index % columns) * (width + spacing)
            let y = bounds.minY + CGFloat(index / columns) * (cell.height + spacing)
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(width: width, height: cell.height))
        }
    }

    private func cellSize(_ subviews: Subviews) -> CGSize {
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return CGSize(width: sizes.map(\.width).max() ?? 0, height: sizes.map(\.height).max() ?? 0)
    }
}
