//
//  OnboardingPreview.swift
//  Runner
//
//  Created by Florian geiger on 23.02.26.
//

import SwiftUI

@available(iOS 26.0, *)
struct OnboardingPreview: View {
    var body: some View {
        let image = UIImage(named: "Screen", in: .main, compatibleWith: nil)
        
        iOS26StyleOnBoarding(
            tint: Color(red: 0x7E/255, green: 0x68/255, blue: 0x57/255),
            items: [
                .init(id: 0, title: "QR-Code bestellen", subtitle: "Bestellen Sie Ihren personalisierten\nRemember Me QR-Code in unserem Shop.", screenshot: image),
                .init(id: 1, title: "QR-Code erhalten", subtitle: "Ihr wetterfester QR-Code kommt sicher\nverpackt bei Ihnen an.", screenshot: image),
                .init(id: 2, title: "App herunterladen", subtitle: "Laden Sie die kostenlose Remember Me\nApp herunter und erstellen Sie Ihr Konto.", screenshot: image),
                .init(id: 3, title: "QR-Code scannen", subtitle: "Scannen Sie den QR-Code mit der App,\num ihn mit Ihrem Konto zu verknüpfen.", screenshot: image),
                .init(id: 4, title: "Gedenkseite gestalten", subtitle: "Fügen Sie Fotos, Videos, den Lebenslauf\nund persönliche Geschichten hinzu.", screenshot: image, zoomScale: 1.3, zoomAnchor: .bottom),
                .init(id: 5, title: "Veröffentlichen", subtitle: "Veröffentlichen Sie die Gedenkseite und\nbringen Sie den QR-Code am Gedenkort an.", screenshot: image, zoomScale: 1.2, zoomAnchor: .init(x: 0.5, y: -0.1)),
            ],
            hideBezels: true,
            onSkip: { print("Skipped – user already ordered") }
        ) {
            print("Completed")
        }
    }
}
