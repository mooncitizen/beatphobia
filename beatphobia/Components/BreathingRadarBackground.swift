//
//  CalmingBackground.swift
//  beatphobia
//
//  Created by Paul Gardiner on 18/10/2025.
//
import SwiftUI

extension View {
    func onAnimationCompleted<Value: VectorArithmetic>(for value: Value, completion: @escaping () -> Void) -> ModifiedContent<Self, AnimationCompletionObserverModifier<Value>> {
        return self.modifier(AnimationCompletionObserverModifier(observedValue: value, completion: completion))
    }
}

struct AnimationCompletionObserverModifier<Value: VectorArithmetic>: ViewModifier, Animatable {
    let observedValue: Value
    let completion: () -> Void

    var animatableData: Value {
        didSet {
            if animatableData == observedValue {
                DispatchQueue.main.async { [self] in
                    self.completion()
                }
            }
        }
    }
    
    init(observedValue: Value, completion: @escaping () -> Void) {
        self.observedValue = observedValue
        self.completion = completion
        self.animatableData = observedValue
    }

    func body(content: Content) -> some View {
        content
    }
}

enum CirclePosition {
    case bottom
    case top
    case center
}

struct BreathingRadarBackground: View {
    let backgroundColor: Color
    let baseCircleSize: CGFloat
    let breathingDuration: Double
    let maxBreathingScale: CGFloat
    let pingDuration: Double
    let position: CirclePosition
    
    @State private var breathingScale: CGFloat
    @State private var pingScale: CGFloat
    @State private var pingOpacity: Double

    init(backgroundColor: Color = Color(red: 24/255, green: 48/255, blue: 89/255),
         baseCircleSize: CGFloat = 300,
         breathingDuration: Double = 4.0,
         maxBreathingScale: CGFloat = 1.3,
         pingDuration: Double = 1.5,
         position: CirclePosition = .bottom,
         initialBreathingScale: CGFloat = 0.7) {
        
        self.backgroundColor = backgroundColor
        self.baseCircleSize = baseCircleSize
        self.breathingDuration = breathingDuration
        self.maxBreathingScale = maxBreathingScale
        self.pingDuration = pingDuration
        self.position = position
        
        _breathingScale = State(initialValue: initialBreathingScale)
        _pingScale = State(initialValue: maxBreathingScale)
        _pingOpacity = State(initialValue: 0.0)
    }

    private var yOffset: CGFloat {
        let scaledSize = baseCircleSize * maxBreathingScale
        
        switch position {
        case .bottom:
            return scaledSize
        case .top:
            return -scaledSize
        case .center:
            return 0
        }
    }

    var body: some View {
        ZStack {
            backgroundColor
                .edgesIgnoringSafeArea(.all)

            // Breathing Half-Circle (Base)
            Circle()
                .fill(Color.white.opacity(0.3))
                .frame(width: baseCircleSize, height: baseCircleSize)
                .scaleEffect(breathingScale)
                .offset(y: yOffset)
                .edgesIgnoringSafeArea(position == .center ? [] : (position == .bottom ? .bottom : .top))
                .onAppear {
                    startBreathingAnimation()
                }
                .onAnimationCompleted(for: breathingScale) {
                    if self.breathingScale == self.maxBreathingScale {
                        self.startPingAnimation()
                    }
                    startBreathingAnimation()
                }
                .animation(.easeInOut(duration: breathingDuration), value: breathingScale)

            // Radar Ping Circle
            Circle()
                .stroke(Color.white, lineWidth: 2)
                .frame(width: baseCircleSize, height: baseCircleSize)
                .scaleEffect(pingScale)
                .opacity(pingOpacity)
                .offset(y: yOffset)
                .edgesIgnoringSafeArea(position == .center ? [] : (position == .bottom ? .bottom : .top))
                .animation(.easeOut(duration: pingDuration), value: pingScale)
        }
    }
    
    func startBreathingAnimation() {
        let targetScale = (breathingScale == maxBreathingScale) ? 0.7 : maxBreathingScale
        
        withAnimation(.easeInOut(duration: breathingDuration)) {
            breathingScale = targetScale
        }
    }
    
    func startPingAnimation() {
        pingScale = maxBreathingScale
        pingOpacity = 1.0
        
        withAnimation(.easeOut(duration: pingDuration)) {
            pingScale = maxBreathingScale + 1.0
            pingOpacity = 0.0
        }
    }
}

#Preview {
    BreathingRadarBackground(
        baseCircleSize: 400,
        breathingDuration: 6.0,
        maxBreathingScale: 1.3,
        position: .top
    )
}
