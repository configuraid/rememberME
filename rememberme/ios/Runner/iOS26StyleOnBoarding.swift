import SwiftUI
import AVKit

@available(iOS 26.0, *)
struct iOS26StyleOnBoarding: View {
    var tint: Color = .blue
    var items: [Item]
    var hideBezels: Bool = false
    var onSkip: (() -> Void)? = nil
    var onComplete: () -> ()
    
    @State private var currentIndex: Int = 0
    @State private var screenshotSize: CGSize = .zero
    
    var body: some View {
        ZStack(alignment: .bottom) {
            Color.black.ignoresSafeArea()
            screenshotLayer
            contentLayer
            
            if currentIndex > 0 {
                BackButton()
            }
        }
        .preferredColorScheme(.dark)
    }

    private var screenshotLayer: some View {
        ScreenshotView()
            .compositingGroup()
            .scaleEffect(
                items[currentIndex].zoomScale,
                anchor: items[currentIndex].zoomAnchor
            )
            .padding(.top, 35)
            .padding(.horizontal, 30)
            .padding(.bottom, 250)
    }

    private var contentLayer: some View {
        VStack(spacing: 8) {
            TextContentView()
            
            if let url = items[currentIndex].linkURL,
               let linkTitle = items[currentIndex].linkTitle {
                LinkButton(url: url, title: linkTitle)
            }
            
            IndicatorView()
            ContinueButton()
            
            if currentIndex < items.count - 1, let onSkip = onSkip {
                SkipButton(action: onSkip)
            }
        }
        .padding(.top, 16)
        .padding(.horizontal, 15)
        .frame(height: currentIndex < items.count - 1 ? 260 : 220)
        .background {
            Color.black.opacity(0.7)
            VariableGlassBlur(18)
        }
    }
    
    // MARK: - Link Button
    @ViewBuilder
    func LinkButton(url: URL, title: String) -> some View {
        Link(destination: url) {
            HStack(spacing: 6) {
                Image(systemName: "cart")
                    .font(.subheadline)
                Text(title)
                    .fontWeight(.medium)
                Image(systemName: "arrow.up.right")
                    .font(.caption)
            }
            .foregroundStyle(tint)
            .padding(.vertical, 4)
        }
    }

    // MARK: - Skip Button
    @ViewBuilder
    func SkipButton(action: @escaping () -> Void) -> some View {
        Button {
            action()
        } label: {
            HStack(spacing: 6) {
                Image(systemName: "qrcode")
                    .font(.subheadline)
                Text("Bereits bestellt? Überspringen")
                    .fontWeight(.medium)
            }
            .padding(.vertical, 6)
        }
        .buttonStyle(.glass)
        .buttonSizing(.flexible)
        .padding(.horizontal, 30)
        .padding(.bottom, 4)
        .transition(.opacity.combined(with: .move(edge: .bottom)))
    }

    // MARK: - Continue Button
    func ContinueButton() -> some View {
        ContinueButtonView(
            title: continueButtonTitle,
            tint: tint,
            action: continueAction
        )
    }

    private var continueButtonTitle: String {
        currentIndex == items.count - 1 ? "Jetzt starten" : "Weiter"
    }

    private func continueAction() {
        if currentIndex == items.count - 1 {
            onComplete()
            return
        }
        withAnimation(animation) {
            currentIndex = min(currentIndex + 1, items.count - 1)
        }
    }

    // MARK: - Back Button
    @ViewBuilder
    func BackButton() -> some View {
        Button {
            withAnimation(animation) {
                currentIndex = max(currentIndex - 1, 0)
            }
        } label: {
            Image(systemName: "chevron.left")
                .font(.title3)
                .frame(width: 20, height: 30)
        }
        .buttonStyle(.glass)
        .buttonBorderShape(.circle)
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
        .padding(.leading, 15)
        .padding(.top, 5)
        .transition(.opacity)
    }

    // MARK: - Dot Indicator
    @ViewBuilder
    func IndicatorView() -> some View {
        HStack(spacing: 6) {
            ForEach(items.indices, id: \.self) { index in
                let isActive = currentIndex == index
                Capsule()
                    .fill(.white.opacity(isActive ? 1 : 0.4))
                    .frame(width: isActive ? 25 : 6, height: 6)
            }
        }
        .padding(.bottom, 5)
    }

    // MARK: - Text Content
    @ViewBuilder
    func TextContentView() -> some View {
        GeometryReader {
            let size = $0.size
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        let isActive = currentIndex == index
                        VStack(spacing: 6) {
                            Text(item.title)
                                .font(.title2)
                                .fontWeight(.semibold)
                                .lineLimit(1)
                                .foregroundStyle(.white)
                            Text(item.subtitle)
                                .font(.callout)
                                .lineLimit(2)
                                .multilineTextAlignment(.center)
                                .foregroundStyle(.white.opacity(0.8))
                        }
                        .frame(width: size.width)
                        .compositingGroup()
                        .blur(radius: isActive ? 0 : 30)
                        .opacity(isActive ? 1 : 0)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollIndicators(.hidden)
            .scrollDisabled(true)
            .scrollTargetBehavior(.paging)
            .scrollClipDisabled()
            .scrollPosition(id: .init(get: { currentIndex }, set: { _ in }))
        }
    }

    // MARK: - Variable Glass Blur
    @ViewBuilder
    func VariableGlassBlur(_ radius: CGFloat) -> some View {
        let tint: Color = .black.opacity(0.5)
        Rectangle()
            .fill(.clear)
            .glassEffect(.clear.tint(tint), in: .rect)
            .blur(radius: radius)
            .padding([.horizontal, .bottom], -radius * 2)
            .opacity(items[currentIndex].zoomScale != 1 ? 1 : 0)
            .ignoresSafeArea()
    }

    // MARK: - Screenshot View (mit Video-Support)
    @ViewBuilder
    func ScreenshotView() -> some View {
        let shape = ConcentricRectangle(corners: .concentric, isUniform: true)
        GeometryReader {
            let size = $0.size
            Rectangle()
                .fill(.black)
            ScrollView(.horizontal) {
                HStack(spacing: 12) {
                    ForEach(items.indices, id: \.self) { index in
                        let item = items[index]
                        Group {
                            if let videoName = item.videoName {
                                // Video-Player
                                LoopingVideoView(
                                    videoName: videoName,
                                    isActive: currentIndex == index
                                )
                                .clipShape(shape)
                            } else if let screenshot = item.screenshot {
                                // Statisches Bild
                                Image(uiImage: screenshot)
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .onGeometryChange(for: CGSize.self) { $0.size } action: { newValue in
                                        screenshotSize = newValue
                                    }
                                    .clipShape(shape)
                            } else {
                                // Placeholder
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(Color.white.opacity(0.05))
                                    .overlay {
                                        VStack(spacing: 12) {
                                            Image(systemName: item.placeholderIcon ?? "photo")
                                                .font(.system(size: 48))
                                                .foregroundStyle(.white.opacity(0.3))
                                            Text("Bild folgt")
                                                .font(.caption)
                                                .foregroundStyle(.white.opacity(0.3))
                                        }
                                    }
                            }
                        }
                        .frame(width: size.width, height: size.height)
                    }
                }
                .scrollTargetLayout()
            }
            .scrollDisabled(true)
            .scrollTargetBehavior(.viewAligned)
            .scrollIndicators(.hidden)
            .scrollPosition(id: .init(get: { currentIndex }, set: { _ in }))
        }
        .clipShape(shape)
        .overlay {
            if screenshotSize != .zero && !hideBezels {
                ZStack {
                    shape.stroke(.white, lineWidth: 6)
                    shape.stroke(.black, lineWidth: 4)
                    shape.stroke(.black, lineWidth: 6).padding(4)
                }
                .padding(-6)
            }
        }
        .frame(
            maxWidth: screenshotSize.width == 0 ? nil : screenshotSize.width,
            maxHeight: screenshotSize.height == 0 ? nil : screenshotSize.height
        )
        .containerShape(RoundedRectangle(cornerRadius: deviceCornerRadius))
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }

    var deviceCornerRadius: CGFloat {
        if let imageSize = items.first?.screenshot?.size {
            let ratio = screenshotSize.height / imageSize.height
            return 190 * ratio
        }
        return 0
    }
    
    var animation: Animation {
        .interpolatingSpring(duration: 0.65, bounce: 0, initialVelocity: 0)
    }

    // MARK: - Item Model
    struct Item: Identifiable {
        var id: Int
        var title: String
        var subtitle: String
        var screenshot: UIImage?
        var videoName: String? = nil
        var placeholderIcon: String? = nil
        var zoomScale: CGFloat = 1
        var zoomAnchor: UnitPoint = .center
        var linkURL: URL? = nil
        var linkTitle: String? = nil
    }

    // MARK: - Continue Button View
    private struct ContinueButtonView: View {
        let title: String
        let tint: Color
        let action: () -> Void
        var body: some View {
            Button(action: action) {
                Text(title)
                    .fontWeight(.medium)
                    .padding(.vertical, 6)
            }
            .tint(tint)
            .buttonStyle(.glassProminent)
            .buttonSizing(.flexible)
            .padding(.horizontal, 30)
        }
    }
}

// MARK: - Looping Video Player
@available(iOS 26.0, *)
struct LoopingVideoView: UIViewRepresentable {
    let videoName: String
    let isActive: Bool
    
    func makeUIView(context: Context) -> UIView {
        let containerView = UIView()
        containerView.backgroundColor = .black
        containerView.clipsToBounds = true
        
        guard let url = Bundle.main.url(forResource: videoName, withExtension: "mp4") else {
            print("⚠️ Video nicht gefunden: \(videoName).mp4")
            return containerView
        }
        
        let player = AVPlayer(url: url)
        player.isMuted = true
        
        let playerLayer = AVPlayerLayer(player: player)
        playerLayer.videoGravity = .resizeAspectFill
        containerView.layer.addSublayer(playerLayer)
        
        // Loop-Observer
        NotificationCenter.default.addObserver(
            forName: .AVPlayerItemDidPlayToEndTime,
            object: player.currentItem,
            queue: .main
        ) { _ in
            player.seek(to: .zero)
            player.play()
        }
        
        context.coordinator.player = player
        context.coordinator.playerLayer = playerLayer
        
        return containerView
    }
    
    func updateUIView(_ uiView: UIView, context: Context) {
        // Layout aktualisieren
        DispatchQueue.main.async {
            context.coordinator.playerLayer?.frame = uiView.bounds
        }
        
        // Play/Pause basierend auf aktuellem Schritt
        if isActive {
            context.coordinator.player?.play()
        } else {
            context.coordinator.player?.pause()
            context.coordinator.player?.seek(to: .zero)
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator()
    }
    
    class Coordinator {
        var player: AVPlayer?
        var playerLayer: AVPlayerLayer?
    }
}
