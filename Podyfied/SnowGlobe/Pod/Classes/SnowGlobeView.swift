//
//  SnowGlobeView.swift
//  SnowGlobe
//
//  Created by stringCode on 11/2/14.
//

import UIKit
import CoreMotion
import AudioToolbox

private let lifetimeKey = "lifetime"

open class SnowGlobeView: UIView {
    
    //MARK: - Initializers
    public init(frame: CGRect, position: CGPoint) {
        super.init(frame: frame)
        self.centerPosition = position
        self.initialSetup()
    }
    
    public override init(frame: CGRect) {
        super.init(frame: frame)
        self.initialSetup()
    }
    
    public required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.initialSetup()
    }
    
    public var stopAnimationDuration = 4.0
    public var centerPosition: CGPoint?
    
    //MARK: - Public
    
    /** 
        When true, Creates CMMotionManager, monitors accelerometer and starts emitting snow flakes upon shaking.
        When set to flase emits snow flakes upon view's appearance on screen.
    */
    open var shakeToSnow: Bool = false {
        didSet {
            if oldValue != shakeToSnow {
                shouldShakeToSnow(shakeToSnow)
            }
        }
    }
    
    open var cellConfiguration: CellConfiguration = CellConfiguration() {
        didSet {
            if let images = snowFlakeImage {
                emitterCells = images.map { SnowGlobeView.newEmitterCell(image: $0, configuration: cellConfiguration) }
            }
            emitter.emitterCells = emitterCells
        }
    }
    
    open var fastCellConfiguration: FastCellConfiguration = FastCellConfiguration() {
        didSet {
            createShootingParticle(with: fastCellConfiguration)
        }
    }
    
    /// Snow flake image, recomended size 74 X 74 pixels @2x.
    open var snowFlakeImage: [UIImage]? {
        get {
            return emitterCells.flatMap({ cell in
                if let image: Any = cell.contents {
                    return UIImage(cgImage: image as! CGImage)
                }
                return nil
            })
        }
        set {
            if let strongValue = newValue {
                emitterCells = strongValue.map { SnowGlobeView.newEmitterCell(image: $0) }
            }
            emitter.emitterCells = emitterCells
        }
    }
    
    open var soundEffectsEnabled: Bool = true
    
    /// default ligth snow flake image
    open class func lightSnowFlakeImage() -> (UIImage?) {
        if let image = UIImage(named: "flake") {
            return image;
        }
        return SnowGlobeView.frameworkImage(named: "flake@2x")
    }
    
    /// default dark snow flake image
    open class func darkSnowFlakeImage() -> (UIImage?) {
        if let image = UIImage(named: "flake2") {
            return image;
        }
        return SnowGlobeView.frameworkImage(named: "flake2@2x")
    }
    
    func createShootingParticle(with configuration: FastCellConfiguration) {
        let particleEmmitter = CAEmitterLayer()
        particleEmmitter.emitterPosition = CGPoint(x: self.frame.size.width/2, y: 5)
        particleEmmitter.emitterSize = CGSize(width: self.frame.size.width, height: 10)
        particleEmmitter.emitterShape = kCAEmitterLayerLine
        particleEmmitter.beginTime = CACurrentMediaTime()
        var cells: [CAEmitterCell] = []
        for radian in configuration.radians {
            cells.append(makeShootingCell(with: radian, and: configuration))
        }
       
        particleEmmitter.emitterCells = cells
        self.layer.addSublayer(particleEmmitter)
    }
    
    func makeShootingCell(with radian: CGFloat, and configuration: FastCellConfiguration) -> CAEmitterCell {
        let cell = CAEmitterCell()
        cell.birthRate = configuration.birthRate * Float(arc4random_uniform(1000))/1000
        cell.lifetime = configuration.lifetime
        cell.emissionLongitude = radian
        cell.velocity = configuration.velocity
        cell.velocityRange = configuration.velocityRange
        cell.spin = configuration.spin
        cell.spinRange = configuration.spinRange
        cell.scale = configuration.scale
        cell.scaleRange = configuration.scaleRange
        if let image = configuration.image {
            cell.contents = image.image(withRotation: -radian+3.14).cgImage
        }
        
        return cell
    }
    //MARK: -
    
    open override class var layerClass: AnyClass {
        return CAEmitterLayer.self
    }
    
    open override func layoutSubviews() {
        super.layoutSubviews()
        if let position = centerPosition {
            emitter.emitterPosition = position
        } else {
            emitter.emitterPosition = CGPoint(x: self.frame.size.width/2, y: self.frame.size.height)
            emitter.emitterSize = CGSize(width: self.frame.size.width, height: 1)
        }
        emitter.beginTime = CACurrentMediaTime()
    }
    
    open override func willMove(toWindow newWindow: UIWindow?) {
        super.willMove(toWindow: newWindow)
        if newWindow != nil && shakeToSnow == false && isAnimating == false {
            startAnimating()
        } else {
            stopAnimating()
        }
    }
    
    deinit {
        self.shakeToSnow = false
        AudioServicesDisposeSystemSoundID(sleighBellsSoundId)
    }
    
    //MARK: - Private
    
    /**
        Animates emitter's lifetime property to 1, causing emitter to start emitting
    */
    func startAnimating () {
        playSoundIfNeeded()
        let animDuration = 0.1
        let anim = CABasicAnimation(keyPath: lifetimeKey)
        anim.fromValue = emitter.presentation()?.lifetime
        anim.toValue = 1
        anim.setValue(animDuration, forKeyPath: "duration")
        emitter.removeAnimation(forKey: lifetimeKey)
        emitter.add(anim, forKey: lifetimeKey)
        emitter.lifetime = 1
    }
    
    /**
        Animates emitter's lifetime property to 0, causing emitter to stop emitting
    */
    func stopAnimating () {
        if emitter.presentation() == nil {
            return
        }
        let animDuration = stopAnimationDuration
        let anim = CAKeyframeAnimation(keyPath: lifetimeKey)
        anim.values = [emitter.presentation()!.lifetime, emitter.presentation()!.lifetime, 0.0]
        anim.keyTimes = [0.0, 0.5, 1.0]
        anim.setValue(animDuration, forKeyPath: "duration")
        emitter.add(anim, forKey: lifetimeKey)
        emitter.lifetime = 0.0
        DispatchQueue.main.asyncAfter( deadline: DispatchTime.now() + Double(Int64(animDuration * Double(NSEC_PER_SEC))) / Double(NSEC_PER_SEC), execute: {[weak self] ()->() in
            self?.shouldPlaySound = true
        })

    }
    
    /// Queue that recieves accelerometer updates from CMMotionManager
    fileprivate lazy var queue = OperationQueue()
    fileprivate lazy var emitterCells: [CAEmitterCell] = [SnowGlobeView.newEmitterCell()]
    fileprivate var emitter = CAEmitterLayer()
    fileprivate var isAnimating : Bool {
        get { return self.emitter.lifetime == 1.0 }
    }

    fileprivate func initialSetup() {
        backgroundColor = UIColor.clear
        autoresizingMask = [UIViewAutoresizing.flexibleWidth, UIViewAutoresizing.flexibleHeight]
        isUserInteractionEnabled = false
        emitter.emitterCells = emitterCells
        if let _ = centerPosition {
            emitter.emitterShape = kCAEmitterLayerPoint
        } else {
            emitter.emitterShape = kCAEmitterLayerLine
        }
        emitter.renderMode = kCAEmitterLayerOldestLast
        emitter.lifetime = 1
        self.layer.addSublayer(emitter)
        cellConfiguration = CellConfiguration()
        
    }
    
    fileprivate func shouldShakeToSnow(_ shakeToSnow: Bool) {
        let motionManager = CMMotionManager.sharedManager
        motionManager.accelerometerUpdateInterval = 0.15
        if motionManager.isAccelerometerActive || !shakeToSnow {
            motionManager.stopAccelerometerUpdates()
        }
        motionManager.startAccelerometerUpdates(to: queue) { [weak self] accelerometerData, error in
            let data = accelerometerData!.acceleration
            var magnitude = sqrt( sq(data.x) + sq(data.y) + sq(data.z) )
            magnitude = (magnitude < 3.0) ? 0.0 : magnitude
            if (magnitude == 0.0 && self?.isAnimating == false) {
                return
            }
            if let welf = self {
                DispatchQueue.main.async { welf.animate(toLifetime: magnitude) }
            }
        }
    }
    
    fileprivate func animate(toLifetime rate:Double) {
        if rate <= 0.0 && self.emitter.lifetime != 0.0 {
            stopAnimating()
        } else if rate > 0.0 && isAnimating == false {
            startAnimating()
        }
    }
    
    fileprivate class func newEmitterCell(image: UIImage? = nil, configuration: CellConfiguration = CellConfiguration()) -> CAEmitterCell {
        let cell = CAEmitterCell()
        var currentImage = image
        if currentImage == nil {
            currentImage = SnowGlobeView.lightSnowFlakeImage()
        }
        
        cell.contents = currentImage?.cgImage
        cell.birthRate = configuration.birthRate * Float(arc4random_uniform(1000))/1000
        
        cell.lifetime = configuration.lifetime
        cell.scale = configuration.scale
        cell.scaleRange = configuration.scaleRange
        cell.spin = configuration.spin
        cell.spinRange = configuration.spinRange
        cell.velocity = configuration.velocity
        cell.velocityRange = configuration.velocityRange
        if configuration.startPosition != .zero {
            let yRelativePosition = configuration.startPosition.y/UIScreen.main.bounds.height
            if yRelativePosition < 0.3 { //Up
                cell.emissionLongitude = configuration.emissionLongitude * CGFloat(arc4random_uniform(1000))/1000
            } else if yRelativePosition > 0.7 { //Down
                cell.emissionLongitude = -configuration.emissionLongitude * CGFloat(arc4random_uniform(1000))/1000
            } else {
                cell.emissionLongitude = configuration.emissionLongitude * CGFloat(arc4random_uniform(1000))/1000
                if Float(arc4random_uniform(1000))/1000 >= 0.5 {
                    cell.emissionLongitude = -cell.emissionLongitude
                }
            }
        }
        cell.yAcceleration = configuration.yAcceleration
        cell.scaleSpeed = configuration.scaleSpeed
        cell.xAcceleration = configuration.xAcceleration * (0.7 + CGFloat(arc4random_uniform(1000))/1000)
        if Float(arc4random_uniform(1000))/1000 >= 0.5 {
            cell.xAcceleration = -cell.xAcceleration
        }
        
        return cell
    }
    
    class func frameworkImage(named name: String?) -> (UIImage? ) {
        var image: UIImage? = nil
        let frameworkBundle = Bundle(identifier: "uk.co.stringCode.SnowGlobe")
        if let imagePath = frameworkBundle?.path(forResource: name, ofType: "png") {
            image = UIImage(contentsOfFile: imagePath)
        }
        return image
    }
    
    //MARK: Sound effects
    
    fileprivate var shouldPlaySound:Bool = true
    
    fileprivate func playSoundIfNeeded() {
        if shouldPlaySound && soundEffectsEnabled {
            shouldPlaySound = false
            AudioServicesPlaySystemSound(sleighBellsSoundId);
        }
    }
    
    fileprivate lazy var sleighBellsSoundId: SystemSoundID = {
        var soundId: SystemSoundID = 0
        if let url = Bundle.main.url(forResource: "SleighBells", withExtension: "mp3") {
            AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
        } else if let url = Bundle(identifier: "uk.co.stringCode.SnowGlobe")?.url(forResource: "SleighBells", withExtension: "mp3") {
            AudioServicesCreateSystemSoundID(url as CFURL, &soundId)
        }
        return soundId
    }()
}
