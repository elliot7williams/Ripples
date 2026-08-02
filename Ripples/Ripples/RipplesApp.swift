//
//  ContentView.swift
//  Ripples
//
//  Created by Elliot Williams on 2025-07-13.
//

import SwiftUI
import CoreImage
import CoreImage.CIFilterBuiltins
import UIKit

struct WaterRippleView: View {
    let image: UIImage
    @State private var ripples: [RippleData] = []
    @State private var timer: Timer?
    
    var body: some View {
        RippleEffectView(image: image, ripples: ripples)
            .contentShape(Rectangle())
            .gesture(
                DragGesture(minimumDistance: 0)
                    .onEnded { value in
                        addRipple(at: value.location)
                    }
            )
            .onAppear {
                startTimer()
            }
            .onDisappear {
                stopTimer()
            }
    }
    
    private func addRipple(at location: CGPoint) {
        let newRipple = RippleData(center: location, startTime: Date())
        ripples.append(newRipple)
        
        // Remove ripple after animation completes
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            ripples.removeAll { $0.id == newRipple.id }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0/60.0, repeats: true) { _ in
            // Remove completed ripples
            ripples.removeAll { $0.progress >= 1.0 }
        }
    }
    
    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }
}

struct RippleData: Identifiable {
    let id = UUID()
    let center: CGPoint
    let startTime: Date
    
    var progress: CGFloat {
        let elapsed = Date().timeIntervalSince(startTime)
        return min(CGFloat(elapsed / 2.0), 1.0) // 2 second duration
    }
}

struct RippleEffectView: UIViewRepresentable {
    let image: UIImage
    let ripples: [RippleData]
    
    func makeUIView(context: Context) -> RippleOverlayView {
        let overlayView = RippleOverlayView()
        overlayView.backgroundColor = .clear
        overlayView.isUserInteractionEnabled = true
        return overlayView
    }
    
    func updateUIView(_ uiView: RippleOverlayView, context: Context) {
        uiView.ripples = ripples
        uiView.setNeedsDisplay()
    }
}

class RippleOverlayView: UIView {
    var ripples: [RippleData] = []
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Clear the context
        context.clear(rect)
        
        // Draw water ripples
        for ripple in ripples {
            let progress = ripple.progress
            guard progress > 0 && progress < 1 else { continue }
            
            // Draw multiple concentric ripple waves
            let waveCount = 3
            for i in 0..<waveCount {
                let waveOffset = CGFloat(i) * 0.3
                let waveProgress = max(0, min(1, progress - waveOffset))
                
                if waveProgress > 0 {
                    let radius = rect.width * 0.4 * waveProgress
                    let alpha = (1.0 - CGFloat(i) * 0.3) * (1.0 - waveProgress) * 0.3
                    
                    // Create water-like ripple effect
                    context.setStrokeColor(UIColor.white.withAlphaComponent(alpha).cgColor)
                    context.setLineWidth(2.0)
                    context.addEllipse(in: CGRect(
                        x: ripple.center.x - radius,
                        y: ripple.center.y - radius,
                        width: radius * 2,
                        height: radius * 2
                    ))
                    context.strokePath()
                    
                    // Add inner glow effect
                    context.setStrokeColor(UIColor.cyan.withAlphaComponent(alpha * 0.5).cgColor)
                    context.setLineWidth(1.0)
                    context.addEllipse(in: CGRect(
                        x: ripple.center.x - radius * 0.8,
                        y: ripple.center.y - radius * 0.8,
                        width: radius * 1.6,
                        height: radius * 1.6
                    ))
                    context.strokePath()
                }
            }
        }
    }
}

struct ContentView: View {
    var body: some View {
        ZStack {
            if let image = UIImage(named: "photo") {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .ignoresSafeArea()

                WaterRippleView(image: image)
                    .ignoresSafeArea()
            } else {
                Text("Add your photo")
            }
        }
    }
}

#Preview {
    ContentView()
}

@main
struct RipplesApp: App {
    var body: some Scene {
        WindowGroup {
            ContentView()
        }
    }
}
