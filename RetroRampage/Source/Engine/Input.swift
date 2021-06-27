//
//  Input.swift
//  Engine
//
//  Created by Omar Hegazy on 6/16/21.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

public struct Input {
    public var speed: Double
    public var rotation: Rotation
    public var isFiring: Bool

    public init(speed: Double, rotation: Rotation, isFiring: Bool) {
        self.speed = speed
        self.rotation = rotation
        self.isFiring = isFiring
    }
}


