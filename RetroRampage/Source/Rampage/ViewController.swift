//
//  ViewController.swift
//  Rampage
//
//  Created by Nick Lockwood on 17/05/2019.
//  Programmed by Omar Hegazy on June 6th, 2021.
//  Copyright © 2019 Nick Lockwood. All rights reserved.
//

import UIKit
import Engine

private let joystickRadius: Double = 40
private let maximumTimeStep: Double = 1 / 20
private let worldTimeStep: Double = 1 / 120

public func loadTextures() -> Textures
{
    return Textures(loader: { name in
            guard let image = UIImage(named: name) else {
                fatalError("UIImage for \(name) cannot be created")
            }
            guard let bitmap = Bitmap(image: image) else {
                fatalError("Bitmap for \(name) (image: \(image)) cannot be created")
            }
            return bitmap
        })
}

public func loadLevels() -> [Tilemap]
{
    let jsonURL = Bundle.main.url(forResource: "Levels", withExtension: "json")!
    let jsonData = try! Data(contentsOf: jsonURL)
    let levels = try! JSONDecoder().decode([MapData].self, from: jsonData)
    return levels.enumerated().map { Tilemap($0.element, index: $0.offset)}
    //return try! JSONDecoder().decode([Tilemap].self, from: jsonData)
}


class ViewController: UIViewController {
    private let imageView = UIImageView()
    private let panGesture = UIPanGestureRecognizer()
    private let tapGesture = UITapGestureRecognizer()
    private let levels = loadLevels()
    private lazy var world = World(map: levels[0])
    private var lastFrameTime = CACurrentMediaTime()
    private let textures = loadTextures()
    private var lastFiredTime = 0.0

    override func viewDidLoad() {
        super.viewDidLoad()
        guard NSClassFromString("XCTestCase") == nil
        else
        {
            return
        }
        setUpImageView()

        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)

        panGesture.delegate = self
        view.addGestureRecognizer(panGesture)
        view.addGestureRecognizer(tapGesture)
        tapGesture.addTarget(self, action: #selector(fire))
        tapGesture.delegate = self
    }

    private var inputVector: Vector {
        switch panGesture.state {
        case .began, .changed:
            let translation = panGesture.translation(in: view)
            var vector = Vector(x: Double(translation.x), y: Double(translation.y))
            vector /= max(joystickRadius, vector.length)
            panGesture.setTranslation(CGPoint(
                x: vector.x * joystickRadius,
                y: vector.y * joystickRadius
            ), in: view)
            return vector
        default:
            return Vector(x: 0, y: 0)
        }
    }

    @objc func update(_ displayLink: CADisplayLink) {
        let timeStep = min(maximumTimeStep, displayLink.timestamp - lastFrameTime)
        let inputVector = self.inputVector
        let rotation = inputVector.x * world.player.turningSpeed * worldTimeStep
        let input = Input(speed: -inputVector.y, rotation: Rotation(sine: sin(rotation), cosine: cos(rotation)), isFiring: lastFiredTime > lastFrameTime)
        let worldSteps = (timeStep / worldTimeStep).rounded(.up)
        for _ in 0 ..< Int(worldSteps) {
            if let action = world.update(timeStep: timeStep / worldSteps, input: input) {
                switch action {
                case .loadLevel(let index):
                    let index = index % levels.count
                    world.setLevel(levels[index])
                }
            }
        }
        lastFrameTime = displayLink.timestamp

        let width = Int(imageView.bounds.width), height = Int(imageView.bounds.height)
        var renderer = Renderer(width: width, height: height, textures: textures)
        renderer.draw(world)

        imageView.image = UIImage(bitmap: renderer.bitmap)
    }
    
    @objc func fire(_ gestureRecognizer: UITapGestureRecognizer)
    {
        lastFiredTime = CACurrentMediaTime()
    }

    func setUpImageView() {
        view.addSubview(imageView)
        imageView.translatesAutoresizingMaskIntoConstraints = false
        imageView.topAnchor.constraint(equalTo: view.topAnchor).isActive = true
        imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor).isActive = true
        imageView.widthAnchor.constraint(equalTo: view.widthAnchor).isActive = true
        imageView.heightAnchor.constraint(equalTo: view.heightAnchor).isActive = true
        imageView.contentMode = .scaleAspectFit
        imageView.backgroundColor = .black
        imageView.layer.magnificationFilter = .nearest
    }
}

extension ViewController: UIGestureRecognizerDelegate
{
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}
