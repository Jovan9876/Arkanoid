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
    private var paddleNode: SCNNode?
    private var ballNode: SCNNode?
    private var lives = 3
    private var ballAttachedToPaddle = true  // Track if the ball is attached to the paddle
    
    // Catch if initializer in init() fails
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // Initializer
    override init() {
        
        super.init() // Implement the superclass' initializer
        
        background.contents = UIColor.black // Set the background colour to black
        
        setupCamera()
        
        // Add the ball, paddle, walls and the brick
        addWalls()
        addPaddle()
        addBall()
        addBricks()
        
        // Initialize the Box2D object
        box2D = CBox2D()
        
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
    
    func addWalls() {
        let wallThickness: CGFloat = 1.0
        let playAreaWidth: CGFloat = 40.0
        let playAreaHeight: CGFloat = 160.0

        // Left Wall
        let leftWall = SCNNode(geometry: SCNBox(width: wallThickness, height: playAreaHeight, length: 1, chamferRadius: 0))
        leftWall.position = SCNVector3(-playAreaWidth / 2 - wallThickness / 2, 0, 0) // Adjusted position
        leftWall.physicsBody = SCNPhysicsBody.static()
        rootNode.addChildNode(leftWall)

        // Right Wall
        let rightWall = SCNNode(geometry: SCNBox(width: wallThickness, height: playAreaHeight, length: 1, chamferRadius: 0))
        rightWall.position = SCNVector3(playAreaWidth / 2 + wallThickness / 2, 0, 0) // Adjusted position
        rightWall.physicsBody = SCNPhysicsBody.static()
        rootNode.addChildNode(rightWall)

        // Top Wall
        let topWall = SCNNode(geometry: SCNBox(width: playAreaWidth, height: wallThickness, length: 1, chamferRadius: 0))
        topWall.position = SCNVector3(0, playAreaHeight / 2 + wallThickness / 2, 0) // Adjusted position
        topWall.physicsBody = SCNPhysicsBody.static()
        rootNode.addChildNode(topWall)
    }

    
    func addPaddle() {
        
        let paddle = SCNNode(geometry: SCNBox(width: 15, height: 3, length: 1, chamferRadius: 0))
        paddle.name = "Paddle"
        paddle.geometry?.firstMaterial?.diffuse.contents = UIColor.blue
        paddle.position = SCNVector3(Int(BALL_POS_X), Int(BALL_POS_Y-5), 0)
        rootNode.addChildNode(paddle)
        paddleNode = paddle

    }
    
    func addBricks() {
        
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

                brick.position = SCNVector3(Float(xPos), Float(yPos), 0)
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
        ballNode = theBall
        
    }
    
    @MainActor
    func movePaddle(to deltaX: Float) {
        guard let paddle = paddleNode else { return }

        // Update paddle position based on its current position
        
        let newX = paddle.position.x + deltaX // Move relative to its last position
        paddle.position.x = newX

        // If the ball is still attached, move it with the paddle
        if ballAttachedToPaddle, let ball = ballNode {
            ball.position = SCNVector3(newX, paddle.position.y + 5, 0) // Keep ball above paddle
        }
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

