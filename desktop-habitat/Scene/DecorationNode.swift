//
//  DecorationNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

enum DecorationType: CaseIterable {
    case rock, smallRock, shell
}

/// A static decoration element drawn on the aquarium floor.
class DecorationNode: SKNode {

    let decorationType: DecorationType

    init(type: DecorationType, at position: CGPoint) {
        self.decorationType = type
        super.init()
        self.position  = position
        self.zPosition = 5
        buildDecoration()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // MARK: - Builders

    private func buildDecoration() {
        switch decorationType {
        case .rock:
            addRock(width: .random(in: 30...60), height: .random(in: 20...40))
        case .smallRock:
            addRock(width: .random(in: 12...25), height: .random(in: 8...18))
        case .shell:
            addShell()
        }
    }

    private func addRock(width w: CGFloat, height h: CGFloat) {
        let path = CGMutablePath()
        path.move(to: CGPoint(x: -w / 2, y: 0))
        path.addCurve(to: CGPoint(x: 0, y: h),
                      control1: CGPoint(x: -w / 2, y: h * 0.6),
                      control2: CGPoint(x: -w * 0.15, y: h * 1.05))
        path.addCurve(to: CGPoint(x: w / 2, y: 0),
                      control1: CGPoint(x: w * 0.2, y: h * 0.9),
                      control2: CGPoint(x: w / 2, y: h * 0.4))
        path.closeSubpath()

        let g = CGFloat.random(in: 0.30...0.50)
        let rock = SKShapeNode(path: path)
        rock.fillColor   = NSColor(red: g + 0.05, green: g, blue: g - 0.03, alpha: 1)
        rock.strokeColor = NSColor(red: g - 0.10, green: g - 0.10, blue: g - 0.12, alpha: 0.6)
        rock.lineWidth   = 1
        addChild(rock)

        // Specular highlight
        let hlPath = CGMutablePath()
        hlPath.addEllipse(in: CGRect(x: -w * 0.12, y: h * 0.45,
                                     width: w * 0.22, height: h * 0.25))
        let hl = SKShapeNode(path: hlPath)
        hl.fillColor   = NSColor(white: 1.0, alpha: 0.08)
        hl.strokeColor = .clear
        addChild(hl)
    }

    private func addShell() {
        let r: CGFloat = .random(in: 8...14)
        let path = CGMutablePath()
        path.move(to: .zero)
        path.addArc(center: .zero, radius: r,
                    startAngle: 0, endAngle: .pi, clockwise: false)
        path.closeSubpath()

        let shell = SKShapeNode(path: path)
        shell.fillColor   = NSColor(red: 0.95, green: 0.90, blue: 0.80, alpha: 1)
        shell.strokeColor = NSColor(red: 0.80, green: 0.70, blue: 0.60, alpha: 0.7)
        shell.lineWidth   = 0.5
        addChild(shell)

        // Ridges
        for i in 1..<4 {
            let rr = r * CGFloat(i) / 4
            let ridge = CGMutablePath()
            ridge.addArc(center: .zero, radius: rr,
                         startAngle: 0.15, endAngle: .pi - 0.15, clockwise: false)
            let s = SKShapeNode(path: ridge)
            s.strokeColor = NSColor(red: 0.80, green: 0.70, blue: 0.60, alpha: 0.3)
            s.lineWidth   = 0.5
            addChild(s)
        }
    }
}
