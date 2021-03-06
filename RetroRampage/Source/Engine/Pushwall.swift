//
//  Pushwall.swift
//  Engine
//
//  Created by Omar Hegazy on 6/29/21.
//  Copyright © 2021 Nick Lockwood. All rights reserved.
//

public struct Pushwall: Actor {
    public var position: Vector
    public let tile: Tile
    public var speed: Double = 0.25
    public var velocity: Vector
    public let radius: Double = 0.5
    
    public init(position: Vector, tile: Tile) {
        self.position = position
        self.tile = tile
        self.velocity = Vector(x: 0, y: 0)
    }
}

public extension Pushwall {
    var isDead: Bool { return false}
    
    func billboards(facing viewpoint: Vector) -> [Billboard]
    {
        let topLeft = rect.min, bottomRight = rect.max
        let topRight = Vector(x: bottomRight.x, y: topLeft.y)
        let bottomLeft = Vector(x: topLeft.x, y: bottomRight.y)
        let textures = tile.textures
        return [
            Billboard(start: topLeft, direction: Vector(x: 0, y: 1), length: 1, texture: textures[0]),
            Billboard(start: topRight, direction: Vector(x: -1, y: 0), length: 1, texture: textures[1]),
            Billboard(start: bottomRight, direction: Vector(x: 0, y: -1), length: 1, texture: textures[0]),
            Billboard(start: bottomLeft, direction: Vector(x: 1, y: 0), length: 1, texture: textures[1])
        ].filter { billboard in
            let ray = billboard.start - viewpoint
            let faceNormal = billboard.direction.orthogonal
            return ray.dot(faceNormal) < 0
        }
    }
    
    var isMoving: Bool
    {
        return velocity.x != 0 || velocity.y != 0
    }
    
    mutating func update(in world: inout World)
    {
            if isMoving == false, let intersection = world.player.intersection(with: self) {
                let direction: Vector
                if abs(intersection.x) > abs(intersection.y) {
                    direction = Vector(x: intersection.x > 0 ? 1 : -1, y: 0)
                } else {
                    direction = Vector(x: 0, y: intersection.y > 0 ? 1 : -1)
                }
                if !world.map.tile(at: position + direction, from: position).isWall {
                    velocity += direction * speed
            }
        }
        if let intersection = self.intersection(with: world),
            abs(intersection.x) > 0.001 || abs(intersection.y) > 0.001 {
            velocity = Vector(x: 0, y: 0)
            position.x = position.x.rounded(.down) + 0.5
            position.y = position.y.rounded(.down) + 0.5
        }

    }
}

