//
//  ProcessingView.swift
//  Reviso
//
//  Created by WOO Yu Kit Vincent on 17/2/2026.
//

import SwiftUI

struct ProcessingView: View {
    @State private var animationPhase = 0.0

    var body: some View {
        VStack(spacing: 24) {
            Spacer()

            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 8)

            Text("Processing Worksheet...")
                .font(.title2)
                .fontWeight(.semibold)

            Text("Detecting and erasing handwritten answers")
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    ProcessingView()
}
