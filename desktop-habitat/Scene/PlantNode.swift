//
//  PlantNode.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

enum PlantType: CaseIterable {
    case tallSeaweed, shortGrass, broadLeaf
}

/// An aquatic plant anchored to the aquarium floor that sways in the current.
class PlantNode: SKNode {

    let plantType: PlantType

    private var segments: [SKShapeNode] = []
    private let segmentCount: Int
    private let plantHeight: CGFloat
    private let baseColor: NSColor
    private let swayPhase: CGFloat
    private let swaySpeed: CGFloat

    // MARK: - Init

    init(type: PlantType, at position: CGPoint) {
        self.plantType = type
        swayPhase = .random(in: 0 ... .pi * 2)
        swaySpeed = .random(in: 0.5...1.5)

        switch type {
        case .tallSeaweed:
            segmentCount = .random(in: 8...12)
            plantHeight  = .random(in: 120...200)
            baseColor    = NSColor(red: 0.10, green: .random(in: 0.50...0.70),
                                   blue: 0.15, alpha: 0.90)
        case .shortGrass:
            segmentCount = .random(in: 4...6)
            plantHeight  = .random(in: 40...80)
            baseColor    = NSColor(red: 0.15, green: .random(in: 0.60...0.80),
                                   blue: 0.10, alpha: 0.85)
        case .broadLeaf:
            segmentCount = .random(in: 5...7)
            plantHeight  = .random(in: 80...140)
            baseColor    = NSColor(red: 0.05, green: .random(in: 0.45...0.60),
                                   blue: 0.20, alpha: 0.90)
        }

        super.init()
        self.position  = position
        self.zPosition = 10
        buildSegments()
    }

    @available(*, unavailable)
    required init?(coder _: NSCoder) { fatalError() }

    // MARK: - Build

    private func buildSegments() {
        let segH = plantHeight / CGFloat(segmentCount)
        let baseW: CGFloat = plantType == .broadLeaf ? 18
                           : plantType == .tallSeaweed ? 8 : 5

        var parent: SKNode = self
        for i in 0..<segmentCount {
            let frac = CGFloat(i) / CGFloat(segmentCount)
            let w = baseW * (1.0 - frac * 0.6)

            let seg = SKShapeNode(
                rect: CGRect(x: -w / 2, y: 0, width: w, height: segH),
                cornerRadius: w * 0.3
            )

            // Lighten toward tips
            let adj = frac * 0.20
            seg.fillColor = NSColor(
                red:   baseColor.redComponent   + adj,
                green: baseColor.greenComponent + adj,
                blue:  baseColor.blueComponent  + adj,
                alpha: baseColor.alphaComponent
            )
            seg.strokeColor = NSColor(
                red:   baseColor.redComponent   - 0.05,
                green: baseColor.greenComponent - 0.05,
                blue:  baseColor.blueComponent  - 0.05,
                alpha: 0.4
            )
            seg.lineWidth = 0.5

            if i == 0 {
                seg.position = .zero
            } else {
                seg.position = CGPoint(x: 0, y: segH)
            }

            parent.addChild(seg)
            segments.append(seg)
            parent = seg
        }
    }

    // MARK: - Animation

    func update(time t: TimeInterval) {
        for (i, seg) in segments.enumerated() where i > 0 {
            let maxAngle: CGFloat = CGFloat(i) / CGFloat(segmentCount) * 0.08
            seg.zRotation = sin(CGFloat(t) * swaySpeed + swayPhase + CGFloat(i) * 0.3) * maxAngle
        }
    }
}
