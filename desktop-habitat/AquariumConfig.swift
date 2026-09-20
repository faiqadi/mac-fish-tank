//
//  AquariumConfig.swift
//  desktop-habitat
//
//  Created by Faiqadi on 21/09/26.
//

import Foundation

/// Central configuration for the aquarium, persisted via UserDefaults.
class AquariumConfig {

    // MARK: - Persisted settings

    var fishCount: Int {
        get {
            let v = UserDefaults.standard.integer(forKey: "aquarium.fishCount")
            return v > 0 ? v : 8
        }
        set { UserDefaults.standard.set(newValue, forKey: "aquarium.fishCount") }
    }

    var isPaused: Bool {
        get { UserDefaults.standard.bool(forKey: "aquarium.isPaused") }
        set { UserDefaults.standard.set(newValue, forKey: "aquarium.isPaused") }
    }

    // MARK: - Runtime-only settings

    var isClickThrough: Bool = true
    var bubbleRate: Double = 2.0          // seconds between bubble bursts
    var cursorFleeRadius: CGFloat = 120   // how close cursor must be to scare fish
    var foodPelletCount: Int = 10         // pellets dropped per "Feed" action
}
