// the animation fort he job cards

import SwiftUI

struct SwipeCardView: View {
    let job: Job
    let isTopCard: Bool
    var matchedLabels: [String] = []
    
    @Binding var buttonSwipe: SwipeDirection?
    let onSwiped: (SwipeDirection) -> Void

    @State private var offset: CGSize = .zero

    private let swipeThreshold: CGFloat = 120
    private let flyOffDistance: CGFloat = 600

    // decider of wher the card flys to after the swipe
    private var progress: Double {
        Double(max(-1, min(1, offset.width / swipeThreshold)))
    }

    var body: some View {
        cardContent
            .overlay(alignment: .topLeading) {
                stamp("APPLY", color: .green)
                    .opacity(max(0, progress))
                    .rotationEffect(.degrees(-15))
                    .padding(24)
            }
            .overlay(alignment: .topTrailing) {
                stamp("NOPE", color: .red)
                    .opacity(max(0, -progress))
                    .rotationEffect(.degrees(15))
                    .padding(24)
            }
            .offset(offset)
            .rotationEffect(.degrees(Double(offset.width / 20)))
            .gesture(dragGesture)
            .allowsHitTesting(isTopCard)
            .onChange(of: buttonSwipe) { _, newValue in
                guard isTopCard, let direction = newValue else { return }
                flyOff(direction)
            }
    }


    private var dragGesture: some Gesture {
        DragGesture()
            .onChanged { value in
                offset = value.translation
            }
            .onEnded { value in
                if value.translation.width > swipeThreshold {
                    flyOff(.right)
                } else if value.translation.width < -swipeThreshold {
                    flyOff(.left)
                } else {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        offset = .zero
                    }
                }
            }
    }

    // how the card actually flies
    private func flyOff(_ direction: SwipeDirection) {
        let x = direction == .right ? flyOffDistance : -flyOffDistance
        withAnimation(.easeOut(duration: 0.25)) {
            offset = CGSize(width: x, height: offset.height + 40)
        }
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
            buttonSwipe = nil
            onSwiped(direction)
        }
    }

    private var cardContent: some View {
        VStack(alignment: .leading, spacing: 14) {
            HStack(spacing: 12) {
                Image(systemName: job.logoSymbol)
                    .symbolRenderingMode(.hierarchical)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 2) {
                    Text(job.company)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                    Text(job.title)
                        .font(.title2.bold())
                        .lineLimit(2)
                }
            }

            if !matchedLabels.isEmpty {
                Label("Matches: " + matchedLabels.joined(separator: " · "), systemImage: "sparkles")
                    .font(.caption.weight(.semibold))
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(Color.green.opacity(0.2))
                    .clipShape(Capsule())
            }

            Divider()

            Label(job.location, systemImage: "mappin.and.ellipse")
            Label(job.payDisplay, systemImage: "dollarsign.circle")
            Label("\(job.jobType.rawValue) · \(job.workMode.rawValue) · \(job.experienceLevel.rawValue)", systemImage: "briefcase")

            Text(job.summary)
                .font(.body)
                .foregroundStyle(.secondary)
                .padding(.top, 4)

            Spacer(minLength: 0)

            // Tags
            HStack {
                ForEach(job.tags, id: \.self) { tag in
                    Text(tag)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(Capsule())
                }
            }

            HStack {
                Text(job.postedDisplay)
                Spacer()
                Text(job.applyMethod.rawValue)
            }
            .font(.caption)
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 24))
        .shadow(color: .black.opacity(0.15), radius: 10, y: 4)
    }

    private func stamp(_ text: String, color: Color) -> some View {
        Text(text)
            .font(.title.weight(.heavy))
            .foregroundStyle(color)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .overlay(RoundedRectangle(cornerRadius: 8).stroke(color, lineWidth: 4))
    }
}
