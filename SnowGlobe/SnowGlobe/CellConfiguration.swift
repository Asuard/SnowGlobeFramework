//
//  CellConfiguration.swift
//  SnowGlobe
//
//  Created by Alexis Suard on 22/08/2018.
//  Copyright © 2018 stringCode. All rights reserved.
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
}

