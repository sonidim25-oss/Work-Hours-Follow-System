import SwiftUI

struct ConfettiParticle: Identifiable {
    let id = UUID()
    var position: CGPoint
    var velocity: CGVector
    var color: Color
    var size: Double
    var rotation: Double
    var rotationSpeed: Double
}

struct ConfettiView: View {
    @Binding var isEmitting: Bool
    
    @State private var particles: [ConfettiParticle] = []
    @State private var lastUpdate = Date()
    
    let colors: [Color] = [.red, .blue, .green, .yellow, .orange, .purple, .pink]
    
    var body: some View {
        GeometryReader { geo in
            TimelineView(.animation) { timeline in
                Canvas { context, size in
                    // Only draw here, do not mutate state
                    for p in particles {
                        context.translateBy(x: p.position.x, y: p.position.y)
                        context.rotate(by: .degrees(p.rotation))
                        
                        let rect = CGRect(x: -p.size/2, y: -p.size/2, width: p.size, height: p.size)
                        context.fill(Path(rect), with: .color(p.color))
                        
                        context.rotate(by: .degrees(-p.rotation))
                        context.translateBy(x: -p.position.x, y: -p.position.y)
                    }
                }
                .onChange(of: timeline.date) { _, now in
                    updatePhysics(now: now, size: geo.size)
                }
            }
        }
        .ignoresSafeArea()
    }
    
    private func updatePhysics(now: Date, size: CGSize) {
        let dt = min(now.timeIntervalSince(lastUpdate), 0.1)
        lastUpdate = now
        
        var nextParticles: [ConfettiParticle] = []
        
        for particle in particles {
            var p = particle
            p.velocity.dy += 600 * dt // gravity
            p.position.x += p.velocity.dx * dt
            p.position.y += p.velocity.dy * dt
            p.rotation += p.rotationSpeed * dt
            
            if p.position.y <= size.height + 50 {
                nextParticles.append(p)
            }
        }
        
        if isEmitting && nextParticles.count < 150 {
            let count = Int.random(in: 2...6)
            for _ in 0..<count {
                let p = ConfettiParticle(
                    // Spawn near the top edge so it's immediately visible
                    position: CGPoint(x: Double.random(in: 0...size.width), y: -10),
                    velocity: CGVector(
                        dx: Double.random(in: -150...150),
                        dy: Double.random(in: 150...450)
                    ),
                    color: colors.randomElement() ?? .red,
                    size: Double.random(in: 8...16),
                    rotation: Double.random(in: 0...360),
                    rotationSpeed: Double.random(in: -360...360)
                )
                nextParticles.append(p)
            }
        }
        
        particles = nextParticles
    }
}
