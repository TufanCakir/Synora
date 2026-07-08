//
//  CoinStackSymbol.swift
//  Synora
//
//  Created by Tufan Cakir on 05.07.26.
//

import SwiftUI

struct CoinStackSymbol: View {

    @Environment(\.colorScheme) private var colorScheme

    var gapColor: Color = Color(.systemBackground)

    private var iconColor: Color {
        colorScheme == .dark ? .white : .black
    }

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Proportionen der Münzstapel definieren
            let stackW = w * 0.58

            ZStack {
                // 1. HINTERER STAPEL (Rechts oben, höher gebaut mit 5 Münzen)
                CoinStack(coinNumber: 5, color: iconColor, gapColor: gapColor)
                    .frame(width: stackW, height: h * 0.65)
                    .position(x: w * 0.65, y: h * 0.38)

                // 2. VORDERE STAPEL (Links unten, flacher mit 4 Münzen)
                CoinStack(coinNumber: 4, color: iconColor, gapColor: gapColor)
                    .frame(width: stackW, height: h * 0.52)
                    .position(x: w * 0.35, y: h * 0.65)
            }
        }
        .aspectRatio(1, contentMode: .fit)
    }
}

// Hilfs-Komponente für die geschichteten Münzen eines Stapels
private struct CoinStack: View {
    let coinNumber: Int
    let color: Color
    let gapColor: Color

    var body: some View {
        GeometryReader { geo in
            let w = geo.size.width
            let h = geo.size.height

            // Berechnungen für die 3D-Stauchung
            let coinH = h * 0.32
            let spacing = h * 0.14

            ZStack {
                ForEach((0..<coinNumber).reversed(), id: \.self) { i in
                    let yOffset = CGFloat(i) * spacing

                    ZStack {
                        // Der "Cutout"-Effekt stanzt die Lücke mit der übergebenen gapColor
                        Single3DCoinShape()
                            .fill(gapColor)
                            .frame(width: w, height: coinH)
                            .scaleEffect(x: 1.09, y: 1.12)

                        // Die sichtbare, farbige Münze
                        Single3DCoinShape()
                            .fill(color)
                            .frame(width: w, height: coinH)
                    }
                    .position(x: w / 2, y: coinH / 2 + yOffset)
                }
            }
        }
    }
}

// Zeichnet einen echten, ausgefüllten 3D-Zylinder für das Flat-Design
private struct Single3DCoinShape: Shape {
    func path(in rect: CGRect) -> Path {
        var path = Path()

        let w = rect.width
        let h = rect.height
        let ellipseHeight = h * 0.55

        // 1. Der runde Boden der Münze
        path.addEllipse(
            in: CGRect(
                x: 0,
                y: h - ellipseHeight,
                width: w,
                height: ellipseHeight
            )
        )

        // 2. Der massive Mittelteil (Zylinderwand)
        path.addRect(
            CGRect(
                x: 0,
                y: ellipseHeight / 2,
                width: w,
                height: h - ellipseHeight
            )
        )

        // 3. Der obere Deckel der Münze
        path.addEllipse(in: CGRect(x: 0, y: 0, width: w, height: ellipseHeight))

        return path
    }
}

#Preview {
    VStack(spacing: 40) {
        // Light Mode Preview
        ZStack {
            Color(.systemBackground)
            CoinStackSymbol(gapColor: Color(.systemBackground))
                .frame(width: 150, height: 150)
        }

        ZStack {
            Color(.black)
            CoinStackSymbol(gapColor: .black)
                .frame(width: 150, height: 150)
        }
        .preferredColorScheme(.dark)
    }
}
