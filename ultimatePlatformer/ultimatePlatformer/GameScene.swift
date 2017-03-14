//
//  GameScene.swift
//  ultimatePlatformer
//
//  Created by Akash Kundu on 3/7/17.
//  Copyright © 2017 Akash Kundu. All rights reserved.
//

import SpriteKit
import GameplayKit
import CoreMotion

class GameScene: SKScene,SKPhysicsContactDelegate {
    
    var motionManager = CMMotionManager()
    
    //*****variables for main playing scene
    var player:SKSpriteNode?
    var ground:SKSpriteNode?
    var adjustedElevation: Double = 0.0
    var bestHeightLine: SKSpriteNode?
    var deadline: SKSpriteNode?
    var deadlineHeight: CGFloat = 0.0
    var playableSpace: Int = 800
    var platAction: SKAction?
    var platActionReversed: SKAction?
    var platActionSeq:SKAction?
    var platActionLoop:SKAction?
    var bestHeight: CGFloat = 0
    var platActionDuration: TimeInterval = 0
    var platActionDurationRange: Double = 5
    var level:Int = 1
    var maxYFactor: Int = 5
    var platformWidth: CGFloat = 100
    var numOfPlats: Int = 25
    var jumpPower: Int = 600
    var xAccel: CGFloat = 0.0
    var canJump: Bool = false
    let platTexture:SKTexture = SKTexture(imageNamed: "platform")
    var origSize: CGSize?
    var elevationLabel: SKLabelNode?
    
    //***variable for start scene
    var tapToStart: SKLabelNode?
    var grnExplain: SKLabelNode?
    var redExplain: SKLabelNode?
    var transition: SKTransition = SKTransition.crossFade(withDuration: 2)
    
    //***variables for gameover scene
    var gameOverCover: SKSpriteNode?
    var gameOverLabel: SKLabelNode?
    var replayBttn: SKSpriteNode?
    var finalElevationLabel: SKLabelNode?
    
    //***camera setup variables 
    //scale of camera divides what you see if <1 and multiplies if >1
    var cam: SKCameraNode?
    var camScale: CGFloat = 1.3
    
    //***collision categories
    let noCategory: UInt32 = 0
    let playerCategory: UInt32 = 0b1
    let groundCategory: UInt32 = 0b1 << 1
    let platCategory: UInt32 = 0b1 << 2
    
    override func didMove(to view: SKView) {
        
        
        self.physicsWorld.contactDelegate = self
        origSize = self.size
        
        scene?.size.height = (scene?.size.height)! * CGFloat(maxYFactor)
        
        cam = SKCameraNode()
        cam?.setScale(camScale)
        
        self.camera = cam
        self.addChild(cam!)
        
        
        player = self.childNode(withName: "player") as? SKSpriteNode
        ground = self.childNode(withName: "ground") as? SKSpriteNode
        tapToStart = self.childNode(withName: "tapToStart") as? SKLabelNode
        grnExplain = self.childNode(withName: "grnExplain") as? SKLabelNode
        redExplain = self.childNode(withName: "redExplain") as? SKLabelNode
        bestHeightLine = self.childNode(withName: "bestHeightLine") as? SKSpriteNode
        deadline = self.childNode(withName: "deadline") as? SKSpriteNode
        gameOverCover = self.childNode(withName: "gameOverCover") as? SKSpriteNode
        gameOverLabel = self.childNode(withName: "gameOverLabel") as? SKLabelNode
        replayBttn = self.childNode(withName: "replayBttn") as? SKSpriteNode
        finalElevationLabel = self.childNode(withName: "finalElevationLabel") as? SKLabelNode
        elevationLabel = self.childNode(withName: "elevationLabel") as? SKLabelNode
        
        gameOverCover?.isHidden = true
        gameOverLabel?.isHidden = true
        replayBttn?.isHidden = true
        finalElevationLabel?.isHidden = true
        
        
        player?.physicsBody?.categoryBitMask = playerCategory
        player?.physicsBody?.collisionBitMask =  groundCategory | platCategory
        player?.physicsBody?.contactTestBitMask = groundCategory | platCategory
        ground?.physicsBody?.categoryBitMask = groundCategory
        ground?.physicsBody?.collisionBitMask = playerCategory
        ground?.physicsBody?.contactTestBitMask = playerCategory
        
        player?.position = CGPoint(x: -100 ,y: (player?.size.height)!/2)
        player?.physicsBody?.isDynamic = false
        player?.isHidden = true
        ground?.isHidden = true
        
        grnExplain?.position.x = (((frame.size.width/2) * camScale) - frame.size.width/2)
        redExplain?.position.x = (((frame.size.width/2) * camScale) - frame.size.width/2)
        tapToStart?.position.x = (((frame.size.width/2) * camScale) - frame.size.width/2)
        
        self.view?.isPaused = true
        
        cam?.position.y = (player?.position.y)! + CGFloat(400)
    
        
        //can use device motion or just accelermeter, for single axis tilting, feels same. For multi axis tiling, device motion seems better
        
        /* using ray wanderlich method:
        -using accelerometer, get acceleration data
        -split into current acceleration and the data from the accelermometer sensor
        -change velocity of player in didSimulatePhysics func
        - seems like changing velocity avoids force/impulse build up
        - this way provides smoothest/most natural movement so far (compared to adding impule and adding force) */
        
        if(motionManager.isAccelerometerAvailable)
        {
            motionManager.accelerometerUpdateInterval = 0.2
            motionManager.startAccelerometerUpdates()
            
        }
        
        motionManager.startAccelerometerUpdates(to: OperationQueue.current!, withHandler: { (data, error) in
           /* if let myData = data
            {
                self.player?.physicsBody?.applyForce(CGVector(dx: 300*(myData.acceleration.x) , dy: 0))
            }*/
            
                let accel = data?.acceleration
                self.xAccel = CGFloat(accel!.x * 0.75) + self.xAccel * 0.25
            
            
        })
        
        /*if motionManager.isDeviceMotionAvailable {
            motionManager.deviceMotionUpdateInterval = 0.2
            motionManager.startDeviceMotionUpdates(to: OperationQueue.current!, withHandler: {(data, error)
                in
                if let userTilt = data?.gravity
                {
                    //apply impulse works better because the tilting effect feels much more natural
                    
                        //self.player?.physicsBody?.applyForce(CGVector(dx: 500*(userTilt.x) , dy: 0))
                        //self.player?.physicsBody?.applyImpulse(CGVector(dx: 100*(userTilt.x) , dy: 0))
                    
                }
            })
        }*/
        
    }
    
    func didBegin(_ contact: SKPhysicsContact) {
        
        let contactA = contact.bodyA.categoryBitMask
        let contactB = contact.bodyB.categoryBitMask
        
        if (contactB == groundCategory || contactB == platCategory) || (contactA == groundCategory || contactA == platCategory)
        {
            canJump = true
        }
    
    }
    
    func touchDown(atPoint pos : CGPoint) {
        
        if canJump
        {
            self.player?.physicsBody?.applyImpulse(CGVector(dx: 0, dy: jumpPower))
            canJump = false
        }
        
    }
    
    func touchMoved(toPoint pos : CGPoint) {    }
    
    func touchUp(atPoint pos : CGPoint) {    }
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        
        tapToStart?.isHidden = true
        grnExplain?.isHidden = true
        redExplain?.isHidden = true
        ground?.isHidden = false
        if !(player?.physicsBody?.isDynamic)!
        {
            spawnPlatforms(howMany: numOfPlats)
            self.view?.isPaused = false
            player?.physicsBody?.isDynamic = true
            player?.isHidden = false
        }
        
        for t in touches { self.touchDown(atPoint: t.location(in: self)) }
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchMoved(toPoint: t.location(in: self)) }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches {
            //easy and simple way to create button with sprite kit is here
            let bttnLocation = t.location(in: self)
            let nodeAtTouch = atPoint(bttnLocation)
            if nodeAtTouch.name == replayBttn?.name
            {
                startOver()
            }
            self.touchUp(atPoint: t.location(in: self)) }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        for t in touches { self.touchUp(atPoint: t.location(in: self)) }
    }
    
    func generateRandNumX(limit: Double) -> Double
    {
        let sign = arc4random_uniform(2)
        let number = arc4random_uniform(UInt32(limit))
        if sign == 0
        {
            return -(Double(number))
        }
        else
        {
            return Double(number)
        }
    }
    func generateRandNumY(limit: Double) -> Double
    {
        let num = Double(arc4random_uniform(UInt32(limit)))
        return num
        
    }
    
    func spawnPlatforms(howMany: Int)
    {
        for _ in 1...howMany
        {
        var platActionX: CGFloat = 0
        var platActionY: CGFloat = 0
        let plat: SKSpriteNode = SKSpriteNode()
        plat.size.height = CGFloat(0.5)
        plat.size.width = CGFloat(130)
        plat.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: plat.size.width, height: plat.size.height))
        plat.color = UIColor.white
        
        plat.physicsBody?.categoryBitMask = platCategory
        plat.physicsBody?.collisionBitMask = playerCategory
        plat.physicsBody?.contactTestBitMask = playerCategory
        
        plat.physicsBody?.affectedByGravity = false
        plat.physicsBody?.isDynamic = false
        plat.physicsBody?.restitution = 0.3
        plat.position = CGPoint(x: generateRandNumX(limit: Double(frame.size.width)/2), y: generateRandNumY(limit: Double(frame.size.height)/2))
        
        platActionY = CGFloat(generateRandNumY(limit: 200))
        platActionX = CGFloat(generateRandNumY(limit: 200))
        platActionDuration = generateRandNumY(limit: platActionDurationRange) + 1
        
        platAction = SKAction.moveBy(x: platActionX ,y: platActionY, duration: platActionDuration)
        platAction?.timingMode = .easeInEaseOut
        platActionReversed = platAction?.reversed()
        platActionSeq = SKAction.sequence([platAction!,platActionReversed!])
        platActionLoop = SKAction.repeatForever(platActionSeq!)
        plat.run(platActionLoop!)
        
        addChild(plat)
        }
    }
    
    override func didSimulatePhysics() {
        
        player?.physicsBody?.velocity = CGVector(dx: xAccel*1500, dy: (player?.physicsBody?.velocity.dy)!)
        cam?.position.y = (player?.position.y)! + CGFloat(400)
       
        //if (player?.position.x)! > (((frame.size.width/2) * camScale) + (player?.size.width)!) took too much time
        if (player?.position.x)! > (((frame.size.width/2) * camScale))
        {
            player?.position = CGPoint(x: -((player?.position.x)!) ,y: (player?.position.y)!)
        }
            //if (player?.position.x)! > (((frame.size.width/2) * camScale) + (player?.size.width)!) took too much time
        else if (player?.position.x)! < (((-frame.size.width/2) * camScale))
        {
            player?.position = CGPoint(x: -((player?.position.x)!) ,y: (player?.position.y)!)
        }

    }
    
    func extendScene()
    {
        level += 1
        scene?.size.height *= 2
        numOfPlats *= 2
        if level % 2 == 0 && platActionDurationRange >= 1
        {
            platActionDurationRange -= -1
        }
        spawnPlatforms(howMany: numOfPlats)
        jumpPower += 50
        if playableSpace > 100
        {
            playableSpace -= 50
        }
    }
    
    func updateBestHeight()
    {
        bestHeight = (player?.position.y)!
        bestHeightLine?.position.y = bestHeight + CGFloat((player?.size.height)!/2)
        bestHeightLine?.position.x = 0
        
        elevationLabel?.position = CGPoint(x: frame.minX,y: (bestHeightLine?.position.y)! + 5)
        elevationLabel?.text = "\(Int(bestHeight) - 40)"
        
        if (bestHeightLine?.position.y)! >= ((scene?.size.height)! / 2) - 50
        {
            extendScene()
        }
        updateDeadlineHeight()

    }
    
    func updateDeadlineHeight()
    {
        deadlineHeight = (player?.position.y)! - CGFloat(playableSpace)
        deadline?.position.y = deadlineHeight
    }
    
    func startOver()
    {
        if let view = self.view {
            // Load the SKScene from 'GameScene.sks'
            if let scene = SKScene(fileNamed: "GameScene") {
                // Set the scale mode to scale to fit the window
                scene.scaleMode = .aspectFill
                // Present the scene
                view.presentScene(scene)
            }
        }
    }
    
    func gameOver()
    {
        self.view?.isPaused = true
        gameOverLabel?.position = (cam?.position)!
        gameOverCover?.position = CGPoint(x: 0, y: (cam?.position.y)!)
        finalElevationLabel?.position = CGPoint(x: 0, y:  (gameOverLabel?.position.y)! - 110)
        replayBttn?.position = CGPoint(x:  0, y:  (finalElevationLabel?.position.y)! - 200)
        
        bestHeightLine?.position = CGPoint(x: 0, y: (player?.position.y)!)

        gameOverLabel?.text = "game over. 2 taps to retry."
        finalElevationLabel?.text = "score: \(Int(bestHeight) - 40)"
        gameOverCover?.size = CGSize(width: frame.size.width * camScale , height: frame.size.height/2 * camScale)
        gameOverCover?.isHidden = false
        gameOverLabel?.isHidden = false
        replayBttn?.isHidden = false
        finalElevationLabel?.isHidden = false
    }
    
    override func update(_ currentTime: TimeInterval) {
        
        if (player?.position.y)! > bestHeight
        {
            updateBestHeight()
        }
        else if (player?.position.y)! < deadlineHeight
        {
            gameOver()
        }
        
        // Called before each frame is rendered
    }
}
