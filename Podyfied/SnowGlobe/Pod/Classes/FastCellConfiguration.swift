//
//  CellConfiguration.swift
//  Pods-SnowGlobe_Example
//
//  Created by Alexis Suard on 22/08/2018.
//

import Foundation

public struct FastCellConfiguration {
    public var birthRate: Float = 0.7
    public var lifetime: Float = 7.0
    public var scale: CGFloat = 1
    public var scaleRange: CGFloat = 0
    public var spin: CGFloat = 0
    public var spinRange: CGFloat = 0
    public var velocity: CGFloat = 700
    public var velocityRange: CGFloat = 50
    public var image: UIImage?
    public var radians: [CGFloat] = []
    public init() {}
}
