//
//  CellConfiguration.swift
//  Pods-SnowGlobe_Example
//
//  Created by Alexis Suard on 22/08/2018.
//

import Foundation

public struct CellConfiguration {
    public var birthRate: Float = 60
    public var lifetime: Float = 25
    public var scale: CGFloat = 0.2
    public var scaleRange: CGFloat = 0.1
    public var spin: CGFloat = 2
    public var spinRange: CGFloat = 2
    public var velocity: CGFloat = -150
    public var velocityRange: CGFloat = -70.0
    public var emissionLongitude: CGFloat = 0
    public var yAcceleration: CGFloat = 0
    public var xAcceleration: CGFloat = 0
    public var scaleSpeed: CGFloat = 0
    public var startPosition: CGPoint = .zero
    public init() {}
}
