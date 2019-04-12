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

class GameScene: SKScene {
  
  // Private GameScene Properties
    
    var contentCreated = false

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
    
    let kInvaderGridSpacing = CGSize(width: 12, height: 12)
    let kInvaderRowCount = 6
    let kInvaderColCount = 6
    let kShipSize = CGSize(width: 30, height: 16)
    let kShipName = "ship"
    let kScoreHudName = "scoreHud"
    let kHealthHudName = "healthHud"
  
  // Object Lifecycle Management
  
  // Scene Setup and Content Creation
  override func didMove(to view: SKView) {
    
    if (!self.contentCreated) {
      self.createContent()
    }
    }
    func createContent() {
        
        //    let invader = SKSpriteNode(imageNamed: "InvaderA_00.png")
        //
        //    invader.position = CGPoint(x: self.size.width/2, y: self.size.height/2)
        //
        //    self.addChild(invader)
        
        setupInvaders()
        setupShip()
        setupHud()
        // black space color
        self.backgroundColor = SKColor.black
    }
    //MARK: Invader
    func makeInvader(ofType invaderType: InvaderType) -> SKNode {
        //1 determines the color type
        var invaderColor: SKColor
        
        switch(invaderType) {
        case .a:
            invaderColor = SKColor.red
        case .b:
            invaderColor = SKColor.green
        case .c:
            invaderColor = SKColor.blue
        }
        // 2 initialized a sprite that renders a rectangle of the color
        let invader = SKSpriteNode(color: invaderColor, size: InvaderType.size)
        invader.name = InvaderType.name
        
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
        let ship = SKSpriteNode(color: SKColor.green, size: kShipSize)
        ship.name = kShipName
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
        healthLabel.text = String(format: "Health: %.1f%%", 100.0)
        
        // 6 postion of health label
        healthLabel.position = CGPoint(
            x: frame.size.width / 2,
            y: size.height - (80 + healthLabel.frame.size.height/2)
        )
        addChild(healthLabel)
    }
    
    

  // Scene Update
    func moveInvaders(forUpdate currentTime: CFTimeInterval) {
        // 1 if its not time to move then dont do the rest of this func yet
        if (currentTime - timeOfLastMove < timePerMove) {
            return
        }
        
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
  override func update(_ currentTime: TimeInterval) {
    /* Called before each frame is rendered */
    moveInvaders(forUpdate: currentTime)
  }
  
  // Scene Update Helpers
  
  // Invader Movement Helpers
    func determineInvaderMovementDirection() {
        // 1
        var proposedMovementDirection: InvaderMovementDirection = invaderMovementDirection
        
        // 2
        enumerateChildNodes(withName: InvaderType.name) { node, stop in switch self.invaderMovementDirection {
            case .right:
                // 3
                if (node.frame.maxX >= node.scene!.size.width - 1.0) {
                    proposedMovementDirection = .downThenLeft
                    
                    stop.pointee = true
                }
            case .left:
                //4
                if (node.frame.minX <= 1.0) {
                    proposedMovementDirection = .downThenRight
                    
                    stop.pointee = true
            }
            case .downThenLeft:
                proposedMovementDirection = .left
                stop.pointee = true
        case .downThenRight:
            proposedMovementDirection = .right
            stop.pointee = true
        
        default:
            break
            }
        }
        
        // 7
        if (proposedMovementDirection != invaderMovementDirection) {
            invaderMovementDirection = proposedMovementDirection
        }
    }
  
  // Bullet Helpers
  
  // User Tap Helpers
  
  // HUD Helpers
  
  // Physics Contact Helpers
  
  // Game End Helpers
  
}
