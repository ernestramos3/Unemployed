import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat = 10
    var lineSpacing: CGFloat = 10

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let maxWidth = proposal.width ?? .infinity
        var x: CGFloat = 0, y: CGFloat = 0, rowHeight: CGFloat = 0, widest: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > 0 && x + size.width > maxWidth {
                y += rowHeight + lineSpacing
                x = 0
                rowHeight = 0
            }
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
            widest = max(widest, x - spacing)
        }
        return CGSize(width: proposal.width ?? widest, height: subviews.isEmpty ? 0 : y + rowHeight)
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        var x = bounds.minX, y = bounds.minY, rowHeight: CGFloat = 0
        for subview in subviews {
            let size = subview.sizeThatFits(.unspecified)
            if x > bounds.minX && x + size.width > bounds.maxX {
                y += rowHeight + lineSpacing
                x = bounds.minX
                rowHeight = 0
            }
            subview.place(at: CGPoint(x: x, y: y), proposal: ProposedViewSize(size))
            x += size.width + spacing
            rowHeight = max(rowHeight, size.height)
        }
    }
}

struct RemovableChip: View {
    let title: String
    let onRemove: () -> Void

    var body: some View {
        Button(action: onRemove) {
            HStack(spacing: 10) {
                Text(title).font(Theme.semibold(15))
                Image(systemName: "xmark").font(.system(size: 10, weight: .bold))
            }
            .foregroundStyle(Theme.onLime)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.lime, in: Capsule())
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Remove \(title)")
    }
}

struct AddChip: View {
    let title: String
    let onAdd: () -> Void

    var body: some View {
        Button(action: onAdd) {
            HStack(spacing: 10) {
                Text(title).font(Theme.semibold(16))
                Image(systemName: "plus").font(.system(size: 12, weight: .semibold))
            }
            .foregroundStyle(Theme.ink)
            .padding(.horizontal, 12)
            .padding(.vertical, 4)
            .background(Theme.card, in: Capsule())
            .overlay(Capsule().stroke(Theme.chipGray, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add \(title)")
    }
}

struct ToggleChips: View {
    let options: [String]
    let selected: [String]
    let onToggle: (String) -> Void

    var body: some View {
        FlowLayout(spacing: 18, lineSpacing: 14) {
            ForEach(options, id: \.self) { option in
                if selected.contains(option) {
                    RemovableChip(title: option) { onToggle(option) }
                } else {
                    AddChip(title: option) { onToggle(option) }
                }
            }
        }
    }
}

// demographic questions
struct OptionButton: View {
    let title: String
    let isSelected: Bool
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text(title)
                .font(Theme.semibold(16))
                .foregroundStyle(isSelected ? Theme.onLime : Theme.ink)
                .padding(.horizontal, 14)
                .frame(minHeight: 39)
                .background(isSelected ? Theme.lime : Theme.card, in: Capsule())
                .overlay(Capsule().stroke(isSelected ? Theme.lime : Theme.chipGray, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
}

/// question with only one response
struct SingleChoiceQuestion: View {
    let question: String
    let options: [String]
    let selected: String?
    let onChoose: (String) -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(question)
                .font(Theme.semibold(20))
                .fixedSize(horizontal: false, vertical: true)
            FlowLayout(spacing: 9, lineSpacing: 9) {
                ForEach(options, id: \.self) { option in
                    OptionButton(title: option, isSelected: selected == option) { onChoose(option) }
                }
            }
        }
    }
}

///dropdown menu for questions
struct SearchPicker: View {
    let label: String
    let placeholder: String
    let catalog: [String]
    let exclude: [String]
    let onPick: (String) -> Void

    @State private var query = ""
    @FocusState private var isFocused: Bool

    private var trimmed: String { query.trimmingCharacters(in: .whitespacesAndNewlines) }

    private var matches: [(text: String, isCustom: Bool)] {
        guard !trimmed.isEmpty else { return [] }
        var results = catalog
            .filter { $0.localizedCaseInsensitiveContains(trimmed) && !exclude.contains($0) }
            .prefix(4)
            .map { (text: $0, isCustom: false) }
        let isKnown = catalog.contains { $0.caseInsensitiveCompare(trimmed) == .orderedSame }
        if !isKnown && !exclude.contains(trimmed) {
            results.append((text: trimmed, isCustom: true))
        }
        return results
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(label).font(Theme.semibold(20))

            TextField("", text: $query, prompt: Text(placeholder).foregroundStyle(Theme.placeholderGray))
                .font(Theme.regular(20))
                .foregroundStyle(Theme.ink)
                .autocorrectionDisabled()
                .submitLabel(.done)
                .focused($isFocused)
                .onSubmit { pick(trimmed) }
                .padding(.horizontal, 8)
                .padding(.vertical, 12)
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.chipGray, lineWidth: 2))

            if !matches.isEmpty {
                VStack(spacing: 0) {
                    ForEach(Array(matches.enumerated()), id: \.offset) { index, match in
                        Button { pick(match.text) } label: {
                            Text(match.isCustom ? "Add \u{201C}\(match.text)\u{201D}" : match.text)
                                .font(Theme.regular(16))
                                .foregroundStyle(Theme.ink)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 12)
                                .contentShape(Rectangle())
                        }
                        .buttonStyle(.plain)
                        if index < matches.count - 1 { Divider() }
                    }
                }
                .background(Theme.card, in: RoundedRectangle(cornerRadius: 8))
                .overlay(RoundedRectangle(cornerRadius: 8).stroke(Theme.chipGray, lineWidth: 1))
            }
        }
    }

    private func pick(_ value: String) {
        let value = value.trimmingCharacters(in: .whitespacesAndNewlines)
        query = ""
        guard !value.isEmpty, !exclude.contains(value) else { return }
        onPick(value)
    }
}

/// progress bar: a lime arrow that grows left to right as the steps go by
struct OnboardingProgressBar: View {
    let progress: CGFloat

    private let lineWidth: CGFloat = 5
    private let head: CGFloat = 8

    var body: some View {
        GeometryReader { geo in
            let usable = geo.size.width - lineWidth
            let length = max(head * 2, usable * min(max(progress, 0), 1))
            ZStack(alignment: .leading) {
                Capsule()
                    .fill(Theme.ink.opacity(0.12))
                    .frame(height: lineWidth)
                ArrowLine(direction: .right, headSize: head)
                    .stroke(Theme.lime, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))
                    .frame(width: length, height: head * 2 + lineWidth)
                    .padding(.leading, lineWidth / 2)
            }
            .frame(maxHeight: .infinity)
        }
        .frame(height: 24)
        .animation(.spring(response: 0.55, dampingFraction: 0.85), value: progress)
        .accessibilityElement()
        .accessibilityLabel("Progress")
        .accessibilityValue("\(Int(progress * 100)) percent")
    }
}

/// back button
struct BackButton: View {
    let action: () -> Void

    var body: some View {
        Button(action: action) {
            Text("Back")
                .font(Theme.semibold(20))
                .foregroundStyle(Theme.onLime)
                .padding(.vertical, 12)
                .frame(width: 140)
                .background(Theme.pillWhite, in: Capsule())
        }
        .buttonStyle(PressScaleStyle())
    }
}

///skip and content error handliing
struct OnboardingScaffold<Content: View>: View {
    let progress: CGFloat
    let showSkip: Bool
    let isBusy: Bool
    let error: String?
    let onSkip: () -> Void
    let onBack: () -> Void
    let onNext: () -> Void
    let content: Content

    init(progress: CGFloat, showSkip: Bool = false, isBusy: Bool = false, error: String? = nil,
         onSkip: @escaping () -> Void = {}, onBack: @escaping () -> Void, onNext: @escaping () -> Void,
         @ViewBuilder content: () -> Content) {
        self.progress = progress
        self.showSkip = showSkip
        self.isBusy = isBusy
        self.error = error
        self.onSkip = onSkip
        self.onBack = onBack
        self.onNext = onNext
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            OnboardingProgressBar(progress: progress)
                .padding(.top, 12)

            HStack {
                Spacer()
                if showSkip {
                    Button("Skip >", action: onSkip)
                        .font(Theme.semibold(18))
                        .foregroundStyle(Theme.skipGray)
                        .disabled(isBusy)
                }
            }
            .frame(height: 22)
            .padding(.top, 36)

            ScrollView {
                content
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, 20)
                    .padding(.bottom, 24)
            }
            .scrollDismissesKeyboard(.interactively)

            if let error {
                ErrorBanner(message: error)
                    .padding(.bottom, 12)
                    .transition(.opacity)
            }

            HStack {
                BackButton(action: onBack)
                Spacer()
                ZStack {
                    CTAButton(title: "Next", action: onNext)
                        .opacity(isBusy ? 0.4 : 1)
                    if isBusy { ProgressView().tint(Theme.forest) }
                }
                .disabled(isBusy)
            }
            .padding(.bottom, 8)
        }
        .padding(.horizontal, 25)
        .foregroundStyle(Theme.ink)
        .background(Theme.background)
    }
}
