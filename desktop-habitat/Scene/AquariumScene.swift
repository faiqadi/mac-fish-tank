//
//  AquariumScene.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import SpriteKit

/// The main SpriteKit scene that renders the full aquarium.
class AquariumScene: SKScene {

    // MARK: - Configuration

    var config = AquariumConfig()

    // MARK: - Entity lists

    private var fish: [FishNode]            = []
    private var turtles: [TurtleNode]       = []
    private var dolphins: [DolphinNode]     = []
    private var activeWhale: WhaleNode?
    private var bubbles: [BubbleNode]       = []
    private var plants: [PlantNode]         = []
    private var foodPellets: [FoodPelletNode] = []

    // MARK: - Layer nodes (z-ordering)

    private let backgroundLayer = SKNode()
    private let causticsLayer   = SKNode()
    private let decorationLayer = SKNode()
    private let plantBackLayer  = SKNode()
    private let fishLayer       = SKNode()
    private let bubbleLayer     = SKNode()
    private let plantFrontLayer = SKNode()
    private let effectsLayer    = SKNode()
    private let surfaceLayer    = SKNode()

    // MARK: - Internal state

    private var cursorPosition: CGPoint?
    private var previousCursorPos: CGPoint?
    private var cursorVelocity: CGPoint = .zero
    private var lastCursorTime: TimeInterval = 0
    private var lastUpdateTime: TimeInterval = 0
    private var bubbleTimer: TimeInterval    = 0
    private var whaleSpawnTimer: TimeInterval = .random(in: 12...22)
    private var caustics: CausticsEffect?

    // MARK: - Layout helpers

    var sandHeight: CGFloat     { size.height * 0.08 }
    var waterSurfaceY: CGFloat  { size.height * 0.96 }
    var swimAreaMinY: CGFloat   { sandHeight + 25 }
    var swimAreaMaxY: CGFloat   { waterSurfaceY - 30 }
    private var swimBounds: CGRect {
        CGRect(x: 30, y: swimAreaMinY,
               width: size.width - 60,
               height: swimAreaMaxY - swimAreaMinY)
    }

    // MARK: - Scene lifecycle

    override func didMove(to view: SKView) {
        backgroundColor = .clear
        setupLayers()
        setupWaterBackground()
        setupSandFloor()
        setupLightRays()
        setupCaustics()
        setupPlants()
        setupDecorations()
        setupWaterSurface()
        setupAmbientParticles()
        setupFish()
        setupTurtles()
        setupDolphins()
    }

    // MARK: - Layer setup

    private func setupLayers() {
        let layers: [(SKNode, CGFloat)] = [
            (backgroundLayer, -100),
            (causticsLayer,   -90),
            (decorationLayer, -50),
            (plantBackLayer,  -20),
            (fishLayer,         0),
            (bubbleLayer,      40),
            (plantFrontLayer,  70),
            (effectsLayer,     80),
            (surfaceLayer,     95),
        ]
        for (layer, z) in layers {
            layer.zPosition = z
            addChild(layer)
        }
    }

    // MARK: - Background

    private func setupWaterBackground() {
        let tex = Self.gradientTexture(
            size: size,
            colors: [
                NSColor(red: 0.01, green: 0.06, blue: 0.18, alpha: 0.93),
                NSColor(red: 0.03, green: 0.14, blue: 0.35, alpha: 0.90),
                NSColor(red: 0.06, green: 0.25, blue: 0.50, alpha: 0.87),
                NSColor(red: 0.10, green: 0.35, blue: 0.60, alpha: 0.84),
            ]
        )
        let water = SKSpriteNode(texture: tex, size: size)
        water.position    = CGPoint(x: size.width / 2, y: size.height / 2)
        water.anchorPoint = CGPoint(x: 0.5, y: 0.5)
        backgroundLayer.addChild(water)
    }

    // MARK: - Sand

    private func setupSandFloor() {
        let sandSize = CGSize(width: size.width, height: sandHeight)
        let tex = Self.gradientTexture(
            size: sandSize,
            colors: [
                NSColor(red: 0.45, green: 0.35, blue: 0.20, alpha: 1),
                NSColor(red: 0.60, green: 0.48, blue: 0.28, alpha: 1),
                NSColor(red: 0.55, green: 0.44, blue: 0.26, alpha: 0.95),
            ]
        )
        let sand = SKSpriteNode(texture: tex, size: sandSize)
        sand.position = CGPoint(x: size.width / 2, y: sandHeight / 2)
        backgroundLayer.addChild(sand)

        // Subtle sand grain particles
        let grainCount = Int(size.width / 8)
        for _ in 0..<grainCount {
            let dot = SKShapeNode(circleOfRadius: .random(in: 0.5...1.5))
            dot.fillColor   = NSColor(white: .random(in: 0.55...0.75), alpha: 0.3)
            dot.strokeColor = .clear
            dot.position    = CGPoint(x: .random(in: 0...size.width),
                                      y: .random(in: 2...sandHeight - 2))
            backgroundLayer.addChild(dot)
        }
    }

    // MARK: - Light rays

    private func setupLightRays() {
        let rayCount = Int.random(in: 4...6)
        for _ in 0..<rayCount {
            let x = CGFloat.random(in: size.width * 0.1 ... size.width * 0.9)
            let topW: CGFloat = .random(in: 30...60)
            let botW: CGFloat = topW * .random(in: 1.8...3.0)
            let h = size.height * .random(in: 0.5...0.85)

            let path = CGMutablePath()
            path.move(to: CGPoint(x: x - topW / 2, y: size.height))
            path.addLine(to: CGPoint(x: x + topW / 2, y: size.height))
            path.addLine(to: CGPoint(x: x + botW / 2, y: size.height - h))
            path.addLine(to: CGPoint(x: x - botW / 3, y: size.height - h))
            path.closeSubpath()

            let ray = SKShapeNode(path: path)
            ray.fillColor   = NSColor(white: 1.0, alpha: .random(in: 0.02...0.05))
            ray.strokeColor = .clear
            ray.zPosition   = -80

            // Gentle sway
            let sway = SKAction.sequence([
                .moveBy(x: .random(in: 10...25), y: 0, duration: .random(in: 4...7)),
                .moveBy(x: .random(in: -25 ... -10), y: 0, duration: .random(in: 4...7)),
            ])
            ray.run(.repeatForever(sway))
            backgroundLayer.addChild(ray)
        }
    }

    // MARK: - Water surface

    private func setupWaterSurface() {
        // Wavy highlight at the surface
        let segW: CGFloat = 20
        let segs = Int(size.width / segW) + 1
        for i in 0..<segs {
            let x = CGFloat(i) * segW
            let shimmer = SKShapeNode(rectOf: CGSize(width: segW + 2, height: 3))
            shimmer.fillColor   = NSColor(white: 1.0, alpha: 0.15)
            shimmer.strokeColor = .clear
            shimmer.position    = CGPoint(x: x, y: waterSurfaceY)

            let phase: TimeInterval = Double(i) * 0.15
            let wave = SKAction.sequence([
                .wait(forDuration: phase),
                .repeatForever(.sequence([
                    .moveBy(x: 0, y: 3, duration: 1.2),
                    .moveBy(x: 0, y: -3, duration: 1.2),
                ]))
            ])
            shimmer.run(wave)
            surfaceLayer.addChild(shimmer)
        }
    }

    // MARK: - Caustics

    private func setupCaustics() {
        let c = CausticsEffect(floorWidth: size.width, floorHeight: sandHeight + 10)
        caustics = c
        causticsLayer.addChild(c)
    }

    // MARK: - Plants

    private func setupPlants() {
        let count = Int.random(in: 6...10)
        for i in 0..<count {
            let type = PlantType.allCases.randomElement()!
            let x = size.width * (CGFloat(i) + 0.5) / CGFloat(count) + .random(in: -20...20)
            let plant = PlantNode(type: type, at: CGPoint(x: x, y: sandHeight - 2))
            // Alternate front / back layers
            if i % 3 == 0 {
                plantFrontLayer.addChild(plant)
            } else {
                plantBackLayer.addChild(plant)
            }
            plants.append(plant)
        }
    }

    // MARK: - Decorations

    private func setupDecorations() {
        let count = Int.random(in: 3...5)
        for _ in 0..<count {
            let type = DecorationType.allCases.randomElement()!
            let x: CGFloat = .random(in: 60 ... size.width - 60)
            let deco = DecorationNode(type: type, at: CGPoint(x: x, y: sandHeight - 2))
            decorationLayer.addChild(deco)
        }
    }

    // MARK: - Ambient particles

    private func setupAmbientParticles() {
        let emitter = ParticleEffects.ambientParticles(in: size)
        effectsLayer.addChild(emitter)
    }

    // MARK: - Fish

    private func setupFish() {
        for _ in 0..<config.fishCount {
            spawnFish()
        }
    }

    private func spawnFish() {
        let species = FishSpecies.allCases.randomElement()!
        let fishNode = FishNode(species: species)
        fishNode.position = CGPoint(
            x: .random(in: swimBounds.minX...swimBounds.maxX),
            y: .random(in: swimBounds.minY...swimBounds.maxY)
        )
        fishLayer.addChild(fishNode)
        fish.append(fishNode)
    }

    // MARK: - Turtles

    private func setupTurtles() {
        let count = 2
        for _ in 0..<count {
            let turtle = TurtleNode(length: .random(in: 55...68))
            turtle.position = CGPoint(
                x: .random(in: swimBounds.minX + 80 ... swimBounds.maxX - 80),
                y: .random(in: swimBounds.minY + 60 ... swimBounds.maxY - 60)
            )
            fishLayer.addChild(turtle)
            turtles.append(turtle)
        }
    }

    // MARK: - Dolphins

    private func setupDolphins() {
        let count = 1
        for _ in 0..<count {
            let dolphin = DolphinNode(length: .random(in: 76...86))
            dolphin.position = CGPoint(
                x: .random(in: swimBounds.minX + 80 ... swimBounds.maxX - 80),
                y: .random(in: swimBounds.minY + 80 ... swimBounds.maxY - 80)
            )
            fishLayer.addChild(dolphin)
            dolphins.append(dolphin)
        }
    }

    // MARK: - Public API

    func updateCursorPosition(_ screenPos: CGPoint) {
        guard let window = view?.window else { return }
        let winPos   = window.convertPoint(fromScreen: screenPos)
        guard let viewPos = view?.convert(winPos, from: nil) else { return }
        let newPos = convertPoint(fromView: viewPos)

        let now = CACurrentMediaTime()
        let dt = now - lastCursorTime
        if dt > 0.001 && dt < 0.2, let prev = previousCursorPos {
            cursorVelocity = CGPoint(
                x: (newPos.x - prev.x) / CGFloat(dt),
                y: (newPos.y - prev.y) / CGFloat(dt)
            )
        } else {
            cursorVelocity = .zero
        }
        previousCursorPos = newPos
        lastCursorTime = now
        cursorPosition = newPos
    }

    func dropFood(count: Int? = nil) {
        let n = count ?? config.foodPelletCount
        let now = CACurrentMediaTime()
        for _ in 0..<n {
            let x: CGFloat = .random(in: 50 ... size.width - 50)
            let pelletPos = CGPoint(x: x, y: waterSurfaceY)
            let pellet = FoodPelletNode(at: pelletPos)
            fishLayer.addChild(pellet)
            foodPellets.append(pellet)

            // Broadcast surface splash wave to all fish (lateral line detection)
            for f in fish {
                f.recordSplash(at: pelletPos, time: now)
            }
        }
    }

    // MARK: - Game loop

    override func update(_ currentTime: TimeInterval) {
        let dt: TimeInterval
        if lastUpdateTime == 0 { dt = 0 } else { dt = currentTime - lastUpdateTime }
        lastUpdateTime = currentTime
        guard dt < 1.0 else { return }      // skip huge jumps (e.g. after sleep)

        // Decay cursor velocity if mouse hasn't moved
        let now = CACurrentMediaTime()
        if now - lastCursorTime > 0.08 {
            cursorVelocity = CGPoint(
                x: cursorVelocity.x * 0.8,
                y: cursorVelocity.y * 0.8
            )
        }

        updateFish(dt: dt)
        updateTurtles(dt: dt)
        updateDolphins(dt: dt)
        updateWhale(dt: dt)
        updateBubbles(dt: dt)
        updatePlants(time: currentTime)
        updateFood(dt: dt)
        updateCaustics(time: currentTime)
        spawnBubblesIfNeeded(dt: dt)
        spawnWhaleIfNeeded(dt: dt)
        cleanUpFood()
    }

    // MARK: - Sub-updates

    private func updateFish(dt: TimeInterval) {
        for f in fish {
            f.update(deltaTime: dt, bounds: swimBounds,
                     cursorPosition: cursorPosition,
                     cursorVelocity: cursorVelocity,
                     foodPellets: foodPellets,
                     allFish: fish)
        }
    }

    private func updateTurtles(dt: TimeInterval) {
        for t in turtles {
            t.update(deltaTime: dt,
                     bounds: swimBounds,
                     waterSurfaceY: waterSurfaceY,
                     cursorPosition: cursorPosition,
                     foodPellets: foodPellets)
        }
    }

    private func updateDolphins(dt: TimeInterval) {
        for d in dolphins {
            d.update(deltaTime: dt,
                     bounds: swimBounds,
                     waterSurfaceY: waterSurfaceY,
                     cursorPosition: cursorPosition,
                     foodPellets: foodPellets)
        }
    }

    private func updateWhale(dt: TimeInterval) {
        guard let whale = activeWhale else { return }
        whale.update(deltaTime: dt, bounds: swimBounds, sceneSize: size)
        if whale.isDismissed {
            whale.removeFromParent()
            activeWhale = nil
            whaleSpawnTimer = .random(in: 45...80)
        }
    }

    private func spawnWhaleIfNeeded(dt: TimeInterval) {
        guard activeWhale == nil else { return }
        whaleSpawnTimer -= dt
        if whaleSpawnTimer <= 0 {
            let swimRight = Bool.random()
            let whale = WhaleNode(swimmingRight: swimRight, length: .random(in: 480...560))

            let startX = swimRight ? (-whale.whaleLength * 1.05) : (size.width + whale.whaleLength * 1.05)
            let startY = CGFloat.random(in: sandHeight + 90 ... waterSurfaceY - 80)
            whale.position = CGPoint(x: startX, y: startY)

            // Add behind foreground fish and foreground plants in plantBackLayer for deep cinematic effect
            plantBackLayer.addChild(whale)
            activeWhale = whale
        }
    }

    private func updateBubbles(dt: TimeInterval) {
        bubbles.removeAll { $0.parent == nil }
        for b in bubbles {
            b.update(deltaTime: dt, waterSurfaceY: waterSurfaceY)
        }
    }

    private func updatePlants(time t: TimeInterval) {
        for p in plants { p.update(time: t) }
    }

    private func updateFood(dt: TimeInterval) {
        for p in foodPellets where !p.isEaten && p.parent != nil {
            p.update(deltaTime: dt, sandY: sandHeight)
        }
    }

    private func updateCaustics(time t: TimeInterval) {
        caustics?.update(time: t)
    }

    private func cleanUpFood() {
        foodPellets.removeAll { $0.parent == nil }
    }

    private func spawnBubblesIfNeeded(dt: TimeInterval) {
        bubbleTimer += dt
        if bubbleTimer >= config.bubbleRate {
            bubbleTimer = 0
            let count = Int.random(in: 1...3)
            for _ in 0..<count {
                let x: CGFloat = .random(in: 30 ... size.width - 30)
                let b = BubbleNode(at: CGPoint(x: x, y: sandHeight + .random(in: 0...20)))
                bubbleLayer.addChild(b)
                bubbles.append(b)
            }
        }
    }

    // MARK: - Gradient texture helper

    static func gradientTexture(size: CGSize, colors: [NSColor]) -> SKTexture {
        let image = NSImage(size: size, flipped: false) { rect in
            guard let ctx = NSGraphicsContext.current?.cgContext else { return false }
            let space = CGColorSpaceCreateDeviceRGB()
            let cgColors = colors.map { $0.cgColor }
            guard let grad = CGGradient(colorsSpace: space, colors: cgColors as CFArray,
                                        locations: nil) else { return false }
            ctx.drawLinearGradient(grad,
                                  start: CGPoint(x: 0, y: 0),
                                  end: CGPoint(x: 0, y: rect.height),
                                  options: [])
            return true
        }
        return SKTexture(image: image)
    }
}
