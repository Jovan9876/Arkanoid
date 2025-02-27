//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Lab10: Demo using Box2D for a ball that can be launched and
//        a falling brick that disappears when it hits the ball
//
//====================================================================

import SceneKit

import QuartzCore

class Box2DDemo: SCNScene {
    
    var cameraNode = SCNNode()                      // Initialize camera node
    
    var lastTime = CFTimeInterval(floatLiteral: 0)  // Used to calculate elapsed time on each update
    
    private var box2D: CBox2D!                      // Points to Objective-C++ wrapper for C++ Box2D library
    
    // Catch if initializer in init() fails
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initializer
    override init() {
        
        super.init() // Implement the superclass' initializer
        
        background.contents = UIColor.black // Set the background colour to black
        
        setupCamera()
        
        // Add the walls only for testing, ball and the brick
        addBall()
        addBricks()
//        addWalls() for testing

        // Initialize the Box2D object
        box2D = CBox2D()
        //        box2D.helloWorld()  // If you want to test the HelloWorld example of Box2D
        
        // Setup the game loop tied to the display refresh
        let updater = CADisplayLink(target: self, selector: #selector(gameLoop))
        updater.preferredFrameRateRange = CAFrameRateRange(minimum: 120.0, maximum: 120.0, preferred: 120.0)
        updater.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        
    }
    
    
    // Function to setup the camera node
    func setupCamera() {
        
        let camera = SCNCamera() // Create Camera object
        cameraNode.camera = camera // Give the cameraNode a camera
        // Since this is 2D, just look down the z-axis
        cameraNode.position = SCNVector3(0, 50, 100)
        cameraNode.eulerAngles = SCNVector3(0, 0, 0)
        rootNode.addChildNode(cameraNode) // Add the cameraNode to the scene
        
    }
    
    
    func addBricks() {
        
//        let theBrick = SCNNode(geometry: SCNBox(width: CGFloat(BRICK_WIDTH), height: CGFloat(BRICK_HEIGHT), length: 1, chamferRadius: 0))
//        theBrick.name = "Brick"
//        theBrick.geometry?.firstMaterial?.diffuse.contents = UIColor.red
//        theBrick.position = SCNVector3(Int(BRICK_POS_X), Int(BRICK_POS_Y), 0)
//        rootNode.addChildNode(theBrick)
        
        
        let brickWidth: CGFloat = CGFloat(BRICK_WIDTH)  // 20.0f
        let brickHeight: CGFloat = CGFloat(BRICK_HEIGHT)  // 5.0f
        let brickSpacing: CGFloat = CGFloat(BRICK_SPACING)  // 5
        let startX: CGFloat = CGFloat(BRICK_POS_X)  // -12
        let startY: CGFloat = CGFloat(BRICK_POS_Y)  // 40

        let colors: [UIColor] = [.red, .blue, .green]  // Possible brick colors
        
        for row in 0..<Int(BRICK_ROWS) {  // 5 rows
            for col in 0..<Int(BRICK_COLUMNS) {  // 2 columns
                let brick = SCNNode(geometry: SCNBox(width: brickWidth, height: brickHeight, length: 1, chamferRadius: 0))
                brick.name = "Brick_\(row)_\(col)"
                brick.geometry?.firstMaterial?.diffuse.contents = colors.randomElement()

                // Calculate position based on row & column indices
                let xPos = startX + CGFloat(col) * (brickWidth + brickSpacing)
                let yPos = startY + CGFloat(row) * (brickHeight + brickSpacing)

                brick.position = SCNVector3(Int(xPos), Int(yPos), 0)
                rootNode.addChildNode(brick)
            }
        }
        
        
    }
    
    
    func addBall() {
        
        let theBall = SCNNode(geometry: SCNSphere(radius: CGFloat(BALL_RADIUS)))
        theBall.name = "Ball"
        theBall.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        theBall.position = SCNVector3(Int(BALL_POS_X), Int(BALL_POS_Y), 0)
        rootNode.addChildNode(theBall)
        
    }
    
    
    // Simple game loop that gets called each frame
    @MainActor
    @objc
    func gameLoop(displaylink: CADisplayLink) {
        
        if (lastTime != CFTimeInterval(floatLiteral: 0)) {  // if it's the first frame, just update lastTime
            let elapsedTime = displaylink.targetTimestamp - lastTime    // calculate elapsed time
            updateGameObjects(elapsedTime: elapsedTime) // update all the game objects
        }
        lastTime = displaylink.targetTimestamp
        
    }
    
    
//    @MainActor
//    func updateGameObjects(elapsedTime: Double) {
//        
//        // Update Box2D physics simulation
//        box2D.update(Float(elapsedTime))
//        
//        // Get ball position and update ball node
//        let ballPos = UnsafePointer(box2D.getObject("Ball"))
//        let theBall = rootNode.childNode(withName: "Ball", recursively: true)
//        theBall?.position.x = (ballPos?.pointee.loc.x)!
//        theBall?.position.y = (ballPos?.pointee.loc.y)!
//        //        print("Ball pos: \(String(describing: theBall?.position.x)) \(String(describing: theBall?.position.y))")
//        
//        // Get brick position and update brick node
//        let brickPos = UnsafePointer(box2D.getObject("Brick"))
//        let theBrick = rootNode.childNode(withName: "Brick", recursively: true)
//        if (brickPos != nil) {
//            
//            // The brick is visible, so set the position
//            theBrick?.position.x = (brickPos?.pointee.loc.x)!
//            theBrick?.position.y = (brickPos?.pointee.loc.y)!
//            //            print("Brick pos: \(String(describing: theBrick?.position.x)) \(String(describing: theBrick?.position.y))")
//            
//        } else {
//            
//            // The brick has disappeared, so hide it
//            theBrick?.isHidden = true
//            
//        }
//        
//    }
  
//    func addWalls() {
//        // FOR TESTING
//        let wallThickness: CGFloat = CGFloat(WALL_THICKNESS) // 1.0f
//        
//        let playWidth: CGFloat = CGFloat(BRICK_COLUMNS) * (CGFloat(BRICK_WIDTH) + CGFloat(BRICK_SPACING))
//        let playHeight: CGFloat = CGFloat(BRICK_ROWS) * (CGFloat(BRICK_HEIGHT) + CGFloat(BRICK_SPACING) + 100)
//
//        let wallHeight: CGFloat = CGFloat(playHeight) + 100  // Increase height for full coverage
//        
//        let wallMaterial = SCNMaterial()
//        wallMaterial.diffuse.contents = UIColor.white
//
//        // TOP WALL - Consistent with Box2D
//        let topWall = SCNNode(geometry: SCNBox(width: playWidth, height: wallThickness, length: 1, chamferRadius: 0))
//        topWall.position = SCNVector3(Float(BRICK_POS_X) + Float(playWidth) / 2 - 20,  // Align center
//                                      Float(BRICK_POS_Y) + Float(playHeight) + Float(wallThickness), 0)
//
//        topWall.geometry?.materials = [wallMaterial]
//        rootNode.addChildNode(topWall)
//        
//        
//        // LEFT WALL - Consistent with Box2D
//        let leftWall = SCNNode(geometry: SCNBox(width: wallThickness, height: wallHeight, length: 1, chamferRadius: 0))
//        leftWall.position = SCNVector3(Float(BRICK_POS_X) - Float(wallThickness + 10),  // Left edge
//                                       Float(BRICK_POS_Y) + Float(playHeight) / 2 - 70,  // Center vertically
//                                       0)
//
//        leftWall.geometry?.materials = [wallMaterial]
//        rootNode.addChildNode(leftWall)
//
//        // RIGHT WALL - Consistent with Box2D
//        let rightWall = SCNNode(geometry: SCNBox(width: wallThickness, height: wallHeight, length: 1, chamferRadius: 0))
//        rightWall.position = SCNVector3(Float(BRICK_POS_X) + Float(playWidth) / 2 + Float(wallThickness) / 2 + 20,
//                                        Float(BRICK_POS_Y) + Float(playHeight) / 2 - 70,
//                                        0)  // Keep it on the same Z-plane
//
//        rightWall.geometry?.materials = [wallMaterial]
//        rootNode.addChildNode(rightWall)
//        
//    }



    
    @MainActor
    func updateGameObjects(elapsedTime: Double) {
        
        // Update Box2D physics simulation
        box2D.update(Float(elapsedTime))
        
        // Update ball position
        if let ballPtr = box2D.getObject("Ball") {
            let ballPos = UnsafePointer(ballPtr)
            if let theBall = rootNode.childNode(withName: "Ball", recursively: true) {
                theBall.position.x = ballPos.pointee.loc.x
                theBall.position.y = ballPos.pointee.loc.y
            }
        }
        
        // Loop through all bricks and update positions
        for row in 0..<Int(BRICK_ROWS) {
            for col in 0..<Int(BRICK_COLUMNS) {
                let brickName = "Brick_\(row)_\(col)"
                let brickPos = UnsafePointer(box2D.getObject(brickName))

                if let theBrick = rootNode.childNode(withName: brickName, recursively: true) {
                    if brickPos != nil {
                        theBrick.position.x = brickPos!.pointee.loc.x
                        theBrick.position.y = brickPos!.pointee.loc.y
                    } else {
                        theBrick.isHidden = true // Hide the brick when it’s destroyed
                    }
                }
            }
        }


    }

    
    
    // Function to be called by double-tap gesture: launch the ball
    @MainActor
    func handleDoubleTap() {
        
        box2D.launchBall()
        
    }
    
    
    // Function to reset the physics (reset Box2D and reset the brick)
    @MainActor
    func resetPhysics() {
        
        box2D.reset()
        let theBrick = rootNode.childNode(withName: "Brick", recursively: true)
        theBrick?.isHidden = false
        
    }
    
}


