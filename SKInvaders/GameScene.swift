/**
 * Copyright (c) 2016 Razeware LLC
 *
 * Permission is hereby granted, free of charge, to any person obtaining a copy
 * of this software and associated documentation files (the "Software"), to deal
 * in the Software without restriction, including without limitation the rights
 * to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 * copies of the Software, and to permit persons to whom the Software is
 * furnished to do so, subject to the following conditions:
 *
 * The above copyright notice and this permission notice shall be included in
 * all copies or substantial portions of the Software.
 *
 * THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 * IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 * FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 * AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 * LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 * OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 * THE SOFTWARE.
 */

// random edit

import SpriteKit
import CoreMotion

class GameScene: SKScene, SKPhysicsContactDelegate {
  
  // Private GameScene Properties
    let kMinInvaderBottomHeight: Float = 32.0
    var gameEnding: Bool = false
    
    var score: Int = 0
    var shipHealth: Float = 1.0
    
    var contactQueue = [SKPhysicsContact]()
    
    var tapQueue = [Int]()
    var contentCreated = false
    let motionManager = CMMotionManager()
    
    // 1 begin moving to the right
    var invaderMovementDirection: InvaderMovementDirection = .right
    //2 havent moved yet so start time at 0
    var timeOfLastMove: CFTimeInterval = 0.0
    // 3 invaders take 1 second for each move
    let timePerMove: CFTimeInterval = 1.0
    
    enum InvaderMovementDirection {
        case right
        case left
        case downThenRight
        case downThenLeft
        case none
    }
    enum InvaderType{
        case a
        case b
        case c
        
        static var size: CGSize {
            return CGSize(width: 24, height: 16)
        }
        
        static var name: String {
            return "invader"
        }
    }
    
    enum BulletType {
        case shipFired
        case invaderFired
    }
    
    let kShipFiredBulletName = "shipFiredBullet"
    let kInvaderFiredBulletName = "invaderFiredBullet"
    let kBulletSize = CGSize(width:4, height: 8)
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
    
    let kInvaderCategory: UInt32 = 0x1 << 0
    let kShipFiredBulletCategory: UInt32 = 0x1 << 1
    let kShipCategory: UInt32 = 0x1 << 2
    let kSceneEdgeCategory: UInt32 = 0x1 << 3
    let kInvaderFiredBulletCategory: UInt32 = 0x1 << 4
  
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
  override func didMove(to view: SKView) {
    
    if (!self.contentCreated) {
        self.createContent()
        motionManager.startAccelerometerUpdates()
    }
    physicsWorld.contactDelegate = self
    }
    func createContent() {
        
        //    let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
        //
        //    invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        //
        //    self.addChild(invader)
        physicsBody = SKPhysicsBody(edgeLoopFrom: frame)
        physicsBody!.categoryBitMask = kSceneEdgeCategory
        setupInvaders()
        setupShip()
        setupHud()
        // black space color
        self.backgroundColor = SKColor.black
    }
    //MARK: Invader
    func loadInvaderTextures(ofType invaderType: InvaderType) -> [SKTexture] {
        
        var prefix: String
        
        switch(invaderType) {
        case .a:
            prefix = "InvaderA"
        case .b:
            prefix = "InvaderB"
        case .c:
            prefix = "InvaderC"
        }
        
        // 1 loads pair of sprites for each invader type
        return [SKTexture(imageNamed: String(format: "%@_00.png", prefix)),
                SKTexture(imageNamed: String(format: "%@_01.png", prefix))]
    }
    
    func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        let invaderTextures = loadInvaderTextures(ofType: invaderType)
        
        // 2 uses first such texture as the sprite's base image
        let invader = SKSpriteNode(texture: invaderTextures[0])
        invader.name = InvaderType.name
        
        // 3 animates images in continuous loop
        invader.run(SKAction.repeatForever(SKAction.animate(with: invaderTextures, timePerFrame: timePerMove)))
        
        // invaders' bitmasks setup
        invader.physicsBody = SKPhysicsBody(rectangleOf: invader.frame.size)
        invader.physicsBody!.isDynamic = false
        invader.physicsBody!.categoryBitMask = kInvaderCategory
        invader.physicsBody!.contactTestBitMask = 0x0
        invader.physicsBody!.collisionBitMask = 0x0
        
        return invader
    }
    func setupInvaders() {
        //1 set spawning area 1/3 from the right and 1/2 from the bottom
        let baseOrigin = CGPoint(x: size.width / 3, y: size.height / 2)
        
        for row in 0..<kInvaderRowCount {
            //2 set type for all invaders on a row
            var invaderType: InvaderType
            
            if row % 3 == 0 {
                invaderType = .a
            } else if row % 3 == 1 {
                invaderType = .b
            } else {
                invaderType = .c
            }
            // 3 where should the first one be placed
            let invaderPositionY = CGFloat(row) * (InvaderType.size.height * 2) + baseOrigin.y
            var invaderPosition = CGPoint(x: baseOrigin.x, y: invaderPositionY)
            
            // 4 loop columns
            for _ in 1..<kInvaderColCount {
                // 5 create invader for current row and column
                let invader = makeInvader(ofType: invaderType)
                invader.position = invaderPosition
                
                addChild(invader)
                // update position for next invader
                invaderPosition = CGPoint(
                    x: invaderPosition.x + InvaderType.size.width + kInvaderGridSpacing.width,
                    y: invaderPositionY
                )
            }
        }
    }
    //MARK: Ship
    func setupShip() {
        // 1 creates the ship can be reused if the ship gets destroyed
        let ship = makeShip()
        
        // 2 place ship on screen
        ship.position = CGPoint(x: size.width / 2.0, y: kShipSize.height / 2.0 )
        addChild(ship)
    }
    
    func makeShip() -> SKNode {
        let ship = SKSpriteNode(imageNamed: "Ship.png")
        ship.name = kShipName
        
        // 1 creates rectangular physics body
        ship.physicsBody = SKPhysicsBody(rectangleOf: ship.frame.size)
        // 2 makes shape dynamic to allow collisions
        ship.physicsBody!.isDynamic = true
        // 3 dont drop off the bottom
        ship.physicsBody!.affectedByGravity = false
        // 4 give mass so it moves naturally
        ship.physicsBody!.mass = 0.02
        
        // 1 set ship
        ship.physicsBody!.categoryBitMask = kShipCategory
        // 2 dont detect contact between ship and other physics bodies
        ship.physicsBody!.contactTestBitMask = 0x0
        // 3 do detect collisons between ship and the scenes outer edges
        ship.physicsBody!.collisionBitMask = kSceneEdgeCategory
        return ship
    }
    
    //MARK: Hud
    // boilerplate code for creating and adding text labels
    func setupHud() {
        // 1 score label name
        let scoreLabel = SKLabelNode(fontNamed: "courier")
        scoreLabel.name = kScoreHudName
        scoreLabel.fontSize = 25
        
        // 2 color of score label
        scoreLabel.fontColor = SKColor.green
        scoreLabel.text = String(format: "Score: %04u",0)
        
        // 3 position of score label
        scoreLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (40 + scoreLabel.frame.size.height/2)
        )
        addChild(scoreLabel)
        
        // 4 health label name
        let healthLabel = SKLabelNode(fontNamed: "Courier")
        healthLabel.name = kHealthHudName
        healthLabel.fontSize = 25
        
        // 5 color of health label
        healthLabel.fontColor = SKColor.red
        healthLabel.text = String(format: "Health: %.1f%%",shipHealth * 100.0)
        
        // 6 postion of health label
        healthLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (80 + healthLabel.frame.size.height/2)
        )
        addChild(healthLabel)
    }
    
    func adjustScore(by points: Int) {
        score += points
        if let score = childNode(withName: kScoreHudName) as? SKLabelNode {
            score.text = String(format: "Score: %05u", self.score)
        }
    }
    func adjustShipHealth(by healthAdjustment: Float) {
        // 1 makes sure it does not go negative
        shipHealth = max(shipHealth + healthAdjustment, 0)
        
        if let health = childNode(withName: kHealthHudName) as? SKLabelNode {
            health.text = String(format: "Health: %.1f%", self.shipHealth * 100)
        }
    }
    
    func makeBullet(ofType bulletType: BulletType) -> SKNode {
        var bullet: SKNode
        
        switch bulletType {
        case .shipFired:
            bullet = SKSpriteNode(color: SKColor.green, size: kBulletSize)
            bullet.name = kShipFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kShipFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kInvaderCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            
        case .invaderFired:
            bullet = SKSpriteNode(color: SKColor.magenta, size: kBulletSize)
            bullet.name = kInvaderFiredBulletName
            
            bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.frame.size)
            bullet.physicsBody!.isDynamic = true
            bullet.physicsBody!.affectedByGravity = false
            bullet.physicsBody!.categoryBitMask = kInvaderFiredBulletCategory
            bullet.physicsBody!.contactTestBitMask = kShipCategory
            bullet.physicsBody!.collisionBitMask = 0x0
            break
        }
        
        return bullet
    }

  // Scene Update
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        // 1 if its not time to move then dont do the rest of this func yet
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        determineInvaderMovementDirection()
        
        // 2 loop stuff
        enumerateChildNodes(withName: InvaderType.name) { node, stop in switch self.invaderMovementDirection {
            case .right:
                node.position = CGPoint(x: node.position.x + 10, y: node.position.y)
            case .left:
                node.position = CGPoint(x: node.position.x - 10, y: node.position.y)
            case .downThenLeft, .downThenRight:
                node.position = CGPoint(x: node.position.x, y: node.position.y - 10)
            case .none:
                break
            }
            
            // 3 record that invaders moved
            self.timeOfLastMove = currentTime
        }
    }
    
    func processUserMotion(forUpdate currentTime: CFTimeInterval) {
        // 1 get ship form scene
        if let ship = childNode(withName: kShipName) as? SKSpriteNode {
            //2 get accelerometer data
            if let data = motionManager.accelerometerData {
                //3 if facing up tilting adds accel
                if fabs(data.acceleration.x) > 0.2 {
                    // 4 how do you move the ship?
                    //print("Acceleration: \(data.acceleration.x)")
                    ship.physicsBody!.applyForce(CGVector(dx: 40 * CGFloat(data.acceleration.x), dy: 0))
                }
            }
        }
    }
    
    func fireInvaderBullets(forUpdate currentTime: CFTimeInterval) {
        let existingBullet = childNode(withName: kInvaderFiredBulletName)
        
        // 1 fire a bullet if one is not on screen
        if existingBullet == nil {
            var allInvaders = [SKNode]()
            
            // 2 collect all invaders on screen
            enumerateChildNodes(withName: InvaderType.name) { node, stop in allInvaders.append(node)
            }
            
            if allInvaders.count > 0 {
                //3 select invader at random
                let allInvadersIndex = Int(arc4random_uniform(UInt32(allInvaders.count)))
                
                let invader = allInvaders[allInvadersIndex]
                
                // 4 create bullet and fire from below invader
                let bullet = makeBullet(ofType: .invaderFired)
                bullet.position = CGPoint(
                    x: invader.position.x,
                    y: invader.position.y - invader.frame.size.height / 2 + bullet.frame.size.height / 2
                )
                
                // 5 bullet should travel straight down
                let bulletDestination = CGPoint(x: invader.position.x, y: -(bullet.frame.size.height / 2))
                
                // 6 fire invader bullet
                fireBullet(
                    bullet: bullet,
                    toDestination: bulletDestination,
                    withDuration: 2.0,
                    andSoundFileName: "InvaderBullet.wav"
                )
            }
        }
    }
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
    if isGameOver(){
        endGame()
    }
    processUserMotion(forUpdate: currentTime)
    moveInvaders(forUpdate: currentTime)
    processUserTaps(forUpdate: currentTime)
    fireInvaderBullets(forUpdate: currentTime)
    processContacts(forUpdate: currentTime)
    
  }
  
  // Scene Update Helpers
    func processUserTaps(forUpdate currentTime: CFTimeInterval) {
        // 1 loop tap tapQueue
        for tapCount in tapQueue {
            if tapCount == 1 {
                // 2 if queue is single tap handle it
                fireShipBullets()
            }
            // 3 remove tap from queue
            tapQueue.remove(at: 0)
        }
    }
    
    func processContacts(forUpdate currentTime: CFTimeInterval) {
        for contact in contactQueue {
            handle(contact)
            
            if let index = contactQueue.index(of: contact) {
                contactQueue.remove(at: index)
            }
        }
    }
  
  // Invader Movement Helpers
    func determineInvaderMovementDirection() {
        // 1 reference to the current invaderMovementDirection for modification
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // 2 loop over invaders
        enumerateChildNodes(withName: InvaderType.name) { node, stop in switch self.invaderMovementDirection {
            case .right:
                // 3 if invader right edge < 1 from right edge move down left
                if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .downThenLeft
                    
                    stop.pointee = true
                }
            case .left:
                //4 position < 1 from left move down right
                if (node.frame.minX <= 1.0) {
                    proposedMovementDirection = .downThenRight
                    
                    stop.pointee = true
            }
            case .downThenLeft:
                // 5 if down left then move left
                proposedMovementDirection = .left
                stop.pointee = true
        case .downThenRight:
            // 6 if down right then move right
            proposedMovementDirection = .right
            stop.pointee = true
        
        default:
            break
            }
        }
        
        // 7 if movement is different than current update current
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
  
  // Bullet Helpers

    func fireBullet(bullet: SKNode, toDestination destination: CGPoint, withDuration duration: CFTimeInterval, andSoundFileName soundName: String) {
        //1 moves bullet to the desired destination then removes it
        let bulletAction = SKAction.sequence([
            SKAction.move(to: destination, duration: duration),
            SKAction.wait(forDuration: 3.0 / 60.0),
            SKAction.removeFromParent()
            ])
        
        // 2 plays sound that bullet was fired
        let soundAction = SKAction.playSoundFileNamed(soundName, waitForCompletion: true)
        
        // 3 move bullet and play sound
        bullet.run(SKAction.group([bulletAction, soundAction]))
        
        // 4 fire bullet by adding to scene
        addChild(bullet)
    }
    
    func fireShipBullets(){
        let existingBullet = childNode(withName: kShipFiredBulletName)
        
        // 1 only fire bullet if there isn't one on screen (no machine gun)
        if existingBullet == nil {
            if let ship = childNode(withName: kShipName) {
                let bullet = makeBullet(ofType: .shipFired)
                // 2 set bullet position to come out the top of the ship
                bullet.position = CGPoint(
                    x: ship.position.x,
                    y: ship.position.y + ship.frame.size.height - bullet.frame.size.height / 2
                )
                // 3 set bullet destination to be off the top of the screen
                let bulletDestination = CGPoint(
                    x: ship.position.x,
                    y: frame.size.height + bullet.frame.size.height / 2
                )
                // 4 FIRE EVERYTHING
                fireBullet(
                    bullet: bullet,
                    toDestination: bulletDestination,
                    withDuration: 1.0,
                    andSoundFileName: "ShipBullet.wav"
                )
                
            }
        }
    }
    
    
  // User Tap Helpers
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        if let touch = touches.first {
            if (touch.tapCount == 1) {
                tapQueue.append(1)
            }
        }
    }
  
  // HUD Helpers
  
  // Physics Contact Helpers
    func didBegin(_ contact: SKPhysicsContact) {
        contactQueue.append(contact)
    }
    
    func handle(_ contact: SKPhysicsContact) {
        // Ensure you haven't already handled this contact and removed its nodes
        if contact.bodyA.node?.parent == nil || contact.bodyB.node?.parent == nil {
            return
        }
        
        let nodeNames = [contact.bodyA.node!.name!, contact.bodyB.node!.name!]
        
        if nodeNames.contains(kShipName) && nodeNames.contains(kInvaderFiredBulletName) {
            // Invader bullet hit a ship
            run(SKAction.playSoundFileNamed("ShipHit.wav", waitForCompletion: false))
            
            // 1 adjust ships health when it gets hit
            adjustShipHealth(by: -0.334)
            
            if shipHealth <= 0.0 {
                // 2 if health is 0 remove ship
                contact.bodyA.node!.removeFromParent()
                contact.bodyB.node!.removeFromParent()
            } else {
                // 3 if > 0 only remove bullet
                if let ship = childNode(withName: kShipName) {
                    ship.alpha = CGFloat(shipHealth)
                    
                    if contact.bodyA.node == ship {
                        contact.bodyB.node!.removeFromParent()
                        
                    } else {
                        contact.bodyA.node!.removeFromParent()
                    }
                }
            }
            
        } else if nodeNames.contains(InvaderType.name) && nodeNames.contains(kShipFiredBulletName) {
            // Ship bullet hit an invader
            run(SKAction.playSoundFileNamed("InvaderHit.wav", waitForCompletion: false))
            contact.bodyA.node!.removeFromParent()
            contact.bodyB.node!.removeFromParent()
            
            // 4 when invader is hit add 100 points
            adjustScore(by: 100)
        }
       
  
  // Game End Helpers
  
    }
        func isGameOver() -> Bool {
            // 1 get random invader from the scene
            let invader = childNode(withName: InvaderType.name)
            
            // 2 iterate through invaders to check if any are too low
            var invaderTooLow = false
            enumerateChildNodes(withName: InvaderType.name) {
                node, stop in
                
                if (Float(node.frame.minY) <= self.kMinInvaderBottomHeight) {
                    invaderTooLow = true
                    stop.pointee = true
                }
            }
            
            // 3 get pointer to your ship if health < 0 player = dead
            let ship = childNode(withName: kShipName)
            
            // 4 return if game is over if no more invaders or invader is too low or ship destroyed
            return invader == nil || invaderTooLow || ship == nil
        }
    
        func endGame() {
            // 1 end game onece
            if !gameEnding {
                gameEnding = true
                
                // 2 stop accelerometer
                motionManager.stopAccelerometerUpdates()
                
                // 3 show game over scene
                let gameOverScene: GameOverScene = GameOverScene(size: size)
                
                view?.presentScene(gameOverScene, transition: SKTransition.doorsOpenHorizontal(withDuration: 1.0))
            }
        }
}

