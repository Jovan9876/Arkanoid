//====================================================================
//
// COMP 8051   British Columbia Institute of Technology
// Assignment 2: Clone of Arkanoid
//
//====================================================================

import SceneKit

import QuartzCore

class ArkanoidGame: SCNScene {
    
    var cameraNode = SCNNode()                      // Initialize camera node
    
    var lastTime = CFTimeInterval(floatLiteral: 0)  // Used to calculate elapsed time on each update
    
    private var box2D: CBox2D!                      // Points to Objective-C++ wrapper for C++ Box2D library
    private var lives = 3
    private var score = 0
    private var totalBricks = 0
    private var startPOS = 1
    
    private var livesTextNode: SCNNode? // Reference for lives text
    private var scoreTextNode: SCNNode? // Reference for score text
    private var thePaddle: SCNNode!
    
    // Get screen width and height
    let screenHeight = UIScreen.main.bounds.height / 8 // Divide by 8 for correct position
    let screenWidth = UIScreen.main.bounds.width / 14 // Divide by 14 for correct position
    
    // Catch if initializer in init() fails
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initializer
    override init() {
        
        super.init() // Implement the superclass' initializer
        
        background.contents = UIColor.black // Set the background colour to black
        
        setupCamera()
        
        // Add the walls only for testing, ball, bricks, and lives text
        addBall()
        addBricks()
        addPaddle()
        addLivesText()
        addScoreText()
        //        addWalls() // for testing
        
        // Initialize the Box2D object
        box2D = CBox2D(Float(screenWidth), screenHeight: Float(screenHeight))
        
        
        // Setup the game loop tied to the display refresh
        let updater = CADisplayLink(target: self, selector: #selector(gameLoop))
        updater.preferredFrameRateRange = CAFrameRateRange(minimum: 120.0, maximum: 120.0, preferred: 120.0)
        updater.add(to: RunLoop.main, forMode: RunLoop.Mode.default)
        
    }
    
    
    func addWalls() {
        // FOR TESTING
        let wallThickness: CGFloat = CGFloat(WALL_THICKNESS) // 1.0f
        let wallLength: CGFloat = CGFloat(WALL_LENGTH)  // Increased height for full coverage
        
        let wallMaterial = SCNMaterial()
        wallMaterial.diffuse.contents = UIColor.white
        
        // TOP WALL - Consistent with Box2D
        let topWall = SCNNode(geometry: SCNBox(width: wallLength, height: wallThickness, length: 1, chamferRadius: 0))
        topWall.position = SCNVector3(0, screenHeight, 0)
        topWall.geometry?.materials = [wallMaterial]
        rootNode.addChildNode(topWall)
        
        // LEFT WALL - Consistent with Box2D
        let leftWall = SCNNode(geometry: SCNBox(width: wallThickness, height: wallLength, length: 1, chamferRadius: 0))
        leftWall.position = SCNVector3(-screenWidth, 0, 0)
        leftWall.geometry?.materials = [wallMaterial]
        rootNode.addChildNode(leftWall)
        
        // RIGHT WALL - Consistent with Box2D
        let rightWall = SCNNode(geometry: SCNBox(width: wallThickness, height: wallLength, length: 1, chamferRadius: 0))
        rightWall.position = SCNVector3(screenWidth, 0, 0)
        rightWall.geometry?.materials = [wallMaterial]
        rootNode.addChildNode(rightWall)
        
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
    
    
    func addLivesText() {
        let textGeometry = SCNText(string: "Balls: 3", extrusionDepth: 0.0)
        textGeometry.font = UIFont.systemFont(ofSize: 1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(-1.25, -1.6, -5) // Position
        textNode.scale = SCNVector3(0.2, 0.2, 0.2) // Adjust scale
        textNode.constraints = [SCNBillboardConstraint()] // Make the text face the camera
        
        cameraNode.addChildNode(textNode)
        self.livesTextNode = textNode
    }
    
    
    func updateLivesText() {
        
        if let textGeometry = livesTextNode?.geometry as? SCNText {
            textGeometry.string = "Balls: \(lives)"
        }
        
    }
    
    func addScoreText() {
        let textGeometry = SCNText(string: "Score: 0", extrusionDepth: 0.0)
        textGeometry.font = UIFont.systemFont(ofSize: 1)
        textGeometry.firstMaterial?.diffuse.contents = UIColor.white
        
        let textNode = SCNNode(geometry: textGeometry)
        textNode.position = SCNVector3(0, -1.6, -5) // Position
        textNode.scale = SCNVector3(0.2, 0.2, 0.2) // Adjust scale
        textNode.constraints = [SCNBillboardConstraint()] // Make the text face the camera
        
        cameraNode.addChildNode(textNode)
        self.scoreTextNode = textNode
    }
    
    
    func updateScoreText() {
        
        if let textGeometry = scoreTextNode?.geometry as? SCNText {
            textGeometry.string = "Score: \(score)"
        }
        
    }
    
    
    func addBricks() {
        
        let brickWidth: CGFloat = CGFloat(BRICK_WIDTH)
        let brickHeight: CGFloat = CGFloat(BRICK_HEIGHT)
        let brickSpacing: CGFloat = CGFloat(BRICK_SPACING)
        let startX: CGFloat = CGFloat(BRICK_POS_X)
        let startY: CGFloat = CGFloat(BRICK_POS_Y)
        
        let colors: [UIColor] = [.red, .blue, .green]  // Possible brick colors
        
        for row in 0..<Int(BRICK_ROWS) {  // 5 rows
            for col in 0..<Int(BRICK_COLUMNS) {  // 2 columns
                totalBricks += 1
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
    
    func addPaddle() {
        
        let paddleWidth: CGFloat = CGFloat(PADDLE_WIDTH)
        let paddleHeight: CGFloat = CGFloat(PADDLE_HEIGHT)
//        let paddleSpacing: CGFloat = CGFloat(PADDLE_SPACING)
//        let startX: CGFloat = CGFloat(PADDLE_POS_X)
//        let startY: CGFloat = CGFloat(PADDLE_POS_Y)
        
        
        thePaddle = SCNNode(geometry: SCNBox(width: paddleWidth, height: paddleHeight, length: 1, chamferRadius: 0))
        thePaddle.name = "Paddle"
        thePaddle.geometry?.firstMaterial?.diffuse.contents = UIColor.white
        thePaddle.position = SCNVector3(Int(PADDLE_POS_X), Int(PADDLE_POS_Y), 0)
        rootNode.addChildNode(thePaddle)
        
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
                // Check if the ball has fallen below the screen
                if theBall.position.y < Float(BALL_POS_X) - 10 {
                    lives -= 1  // Reduce player lives
                    updateLivesText()
                    if lives > 0 {
                        print("Ball lost! Lives left: \(lives)")
                        resetPhysics()
                    } else {
                        print("Game Over!")
                        resetGame()
                    }
                }
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
                    } else if !theBrick.isHidden {
                        // If the brick is destroyed, increase score
                        theBrick.isHidden = true
                        score += 1
                        updateScoreText()
                    } else if score == totalBricks {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                            self.resetGame() // Reset game u win // flashes bricks aswell
                        }
                        
                    }
                }
            }
        }
        
        if let paddlePtr = box2D.getObject("Paddle") {
            let paddlePos = UnsafePointer(paddlePtr)
            if let thePaddle = rootNode.childNode(withName: "Paddle", recursively: true) {
                thePaddle.position.x = paddlePos.pointee.loc.x
                thePaddle.position.y = paddlePos.pointee.loc.y
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
        
    }
    
    @MainActor
    func resetGame() {
        
        print("Reloading Game...")
        
        rootNode.childNodes.forEach {
            if $0 != cameraNode { // Keep camera and its children (lives text)
                $0.removeFromParentNode()
            }
        }
        
        box2D = CBox2D(Float(screenWidth), screenHeight: Float(screenHeight))
        lives = 3
        score = 0
        totalBricks = 0
        
        addBricks()
        addBall()
        addPaddle()
        
        updateLivesText()  // Update lives text
        updateScoreText() // Update score text
        
        print("Game Reset Complete")
        
    }
    
    @MainActor
    // Function to be called by drag gesture
    func handleDrag(_ translation: CGFloat) {
        // Move the paddle using the drag gesture
        thePaddle.position.x += Float(translation / 75)
    }
    
}
