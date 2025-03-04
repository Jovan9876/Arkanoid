//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Objective-C++ wrapper for Box2D library
//
//====================================================================

#include <Box2D/Box2D.h>
#include "CBox2D.h"
#include <stdio.h>
#include <map>
#include <string>
#include <iostream>
//#import <UIKit/UIKit.h>

using namespace std;


// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


#pragma mark - Box2D contact listener class

// This C++ class is used to handle collisions
class CContactListener : public b2ContactListener
{
    
public:
    
    void BeginContact(b2Contact* contact) {};
    
    void EndContact(b2Contact* contact) {};
    
    void PreSolve(b2Contact* contact, const b2Manifold* oldManifold)
    {
        b2WorldManifold worldManifold;
        contact->GetWorldManifold(&worldManifold);
        b2PointState state1[2], state2[2];
        b2GetPointStates(state1, state2, oldManifold, contact->GetManifold());

        if (state2[0] == b2_addState)
        {
            // Get the bodies involved in the collision
            b2Body* bodyA = contact->GetFixtureA()->GetBody();
            b2Body* bodyB = contact->GetFixtureB()->GetBody();
            b2Body* bodyC = contact->GetFixtureB()->GetBody();

            // Retrieve PhysicsObject structs from user data
            struct PhysicsObject *objDataA = (struct PhysicsObject *)(bodyA->GetUserData());
            struct PhysicsObject *objDataB = (struct PhysicsObject *)(bodyB->GetUserData());
            struct PhysicsObject *objDataC = (struct PhysicsObject *)(bodyB->GetUserData());

            // Ensure objDataA is not NULL before accessing box2DObj
            if (!objDataA || !objDataA->box2DObj) return;
            if (!objDataB || !objDataB->box2DObj) return;
            if (!objDataC || !objDataC->box2DObj) return;

            // Perform safe type conversion
            CBox2D *parentObj = (__bridge CBox2D *)(objDataA->box2DObj);

            // Retrieve the physics objects map from CBox2D
            std::map<std::string, PhysicsObject *> *physicsMap =
                (std::map<std::string, PhysicsObject *> *)[parentObj GetPhysicsObjects];

            for (auto &pair : *physicsMap) {
                if (pair.second == objDataA) {
                    if (pair.first.find("Brick") != std::string::npos) {
                        [parentObj RegisterHit:pair.first.c_str()];
                        return;
                    }
                } else if (pair.second == objDataB) {
                    if (pair.first.find("Brick") != std::string::npos) {
                        [parentObj RegisterHit:pair.first.c_str()];
                        return;
                    }
                }
            }
        }
    }



    void PostSolve(b2Contact* contact, const b2ContactImpulse* impulse) {};
    
};


#pragma mark - CBox2D

@interface CBox2D ()
{
    
    // Screen dimensions
    float screenWidth;
    float screenHeight;
    
    
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    CContactListener *contactListener;
    float totalElapsedTime;
    
    // Map to keep track of physics object to communicate with the renderer
    std::map<std::string, struct PhysicsObject *> physicsObjects;

    std::string lastHitBrick; // Store the last hit brick
    std::vector<std::string> bricksToDestroy;  // Stores bricks to delete after Step()

    // Logit for this particular "game"
    bool ballHitBrick;  // register that the ball hit the break
    bool ballLaunched;  // register that the user has launched the ball
    
}
@end

@implementation CBox2D





- (instancetype)init:(float)width screenHeight:(float)height
{


    self = [super init];
    
    if (self) {
        
        screenWidth = width;
        screenHeight = height;
        
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, -10.0f);
        world = new b2World(*gravity);
        
        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Wall dimensions
        float wallThickness = WALL_THICKNESS;
        float wallLength = WALL_LENGTH;
        
        // TOP WALL - Consistent with SceneKit
        b2BodyDef topWallDef;
        topWallDef.type = b2_staticBody; // Assign static
        topWallDef.position.Set(0, screenHeight);
        b2Body* topWall = world->CreateBody(&topWallDef);
        
        b2PolygonShape topWallShape;
        topWallShape.SetAsBox(wallLength, wallThickness);
        topWall->CreateFixture(&topWallShape, 0.0f);
        
        
        // LEFT WALL - Consistent with SceneKit
        b2BodyDef leftWallDef;
        leftWallDef.type = b2_staticBody; // Assign static
        leftWallDef.position.Set(-screenWidth, 0);
        b2Body* leftWall = world->CreateBody(&leftWallDef);
        
        b2PolygonShape leftWallShape;
        leftWallShape.SetAsBox(wallThickness, wallLength);
        leftWall->CreateFixture(&leftWallShape, 0.0f);
        
        // RIGHT WALL - Consistent with SceneKit
        b2BodyDef rightWallDef;
        rightWallDef.type = b2_staticBody; // Assign static
        rightWallDef.position.Set(screenWidth, 0);
        b2Body* rightWall = world->CreateBody(&rightWallDef);
        
        b2PolygonShape rightWallShape;
        rightWallShape.SetAsBox(wallThickness, wallLength);
        rightWall->CreateFixture(&rightWallShape, 0.0f);
        

        
        
        // Add multiple bricks in a grid
        for (int row = 0; row < BRICK_ROWS; row++) {
            for (int col = 0; col < BRICK_COLUMNS; col++) {
                
                struct PhysicsObject *newObj = new struct PhysicsObject;
                newObj->loc.x = BRICK_POS_X + col * (BRICK_WIDTH + BRICK_SPACING);
                newObj->loc.y = BRICK_POS_Y + row * (BRICK_HEIGHT + BRICK_SPACING);
                newObj->objType = ObjTypeBox;
                
                char objName[20];
                snprintf(objName, sizeof(objName), "Brick_%d_%d", row, col); // Unique brick name
                
                [self AddObject:objName newObject:newObj];
                

            }
        }
        
        for (int row = 0; row < 1; row++) {
         
                
                struct PhysicsObject *newObj = new struct PhysicsObject;
                newObj->loc.x = PADDLE_POS_X;
                newObj->loc.y = PADDLE_POS_Y;
                newObj->objType = ObjTypeBox;
                char *objName = strdup("Paddle");
                [self AddObject:objName newObject:newObj];

            
        }
        
        
        struct PhysicsObject *newObj = new struct PhysicsObject;
        
        newObj = new struct PhysicsObject;
        newObj->loc.x = BALL_POS_X;
        newObj->loc.y = BALL_POS_Y;
        newObj->objType = ObjTypeCircle;
        char *objName  = strdup("Ball");
        [self AddObject:objName newObject:newObj];
        
        totalElapsedTime = 0;
        ballHitBrick = false;
        ballLaunched = false;
    

    }
    
    return self;
    
}

- (void)dealloc
{
    
    if (gravity) delete gravity;
    if (world) delete world;
    if (contactListener) delete contactListener;
    
}

-(void)Update:(float)elapsedTime
{
    
    // Get pointers to the brick and ball physics objects
    struct PhysicsObject *theBrick = physicsObjects[std::string("Brick")];
    struct PhysicsObject *thePaddle = physicsObjects[std::string("Paddle")];
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    
    // Check here if we need to launch the ball
    //  and if so, use ApplyLinearImpulse() and SetActive(true)
    if (ballLaunched)
    {
        
        // Apply a force (since the ball is set up not to be affected by gravity)
        ((b2Body *)theBall->b2ShapePtr)->ApplyLinearImpulse(b2Vec2(0, BALL_VELOCITY),
                                                            ((b2Body *)theBall->b2ShapePtr)->GetPosition(),
                                                            true);
        ((b2Body *)theBall->b2ShapePtr)->SetActive(true);
        ballLaunched = false;
    }
    
    // Check if it is time yet to drop the brick, and if so call SetAwake()
    totalElapsedTime += elapsedTime;
    if ((totalElapsedTime > BRICK_WAIT) && theBrick && theBrick->b2ShapePtr) {
        ((b2Body *)theBrick->b2ShapePtr)->SetAwake(true);
    }
    
    // Use these lines for debugging the brick and ball positions
    //    if (theBrick)
    //        printf("Brick: %4.2f %4.2f\t",
    //               ((b2Body *)theBrick->b2ShapePtr)->GetPosition().x,
    //               ((b2Body *)theBrick->b2ShapePtr)->GetPosition().y);
    //    if (theBall &&  theBall->b2ShapePtr)
    //        printf("Ball: %4.2f %4.2f",
    //               ((b2Body *)theBall->b2ShapePtr)->GetPosition().x,
    //               ((b2Body *)theBall->b2ShapePtr)->GetPosition().y);
    //    printf("\n");
    
    
    
    // If the last collision test was positive, stop the ball and destroy the brick
    if (ballHitBrick)
    {
        
        // Stop the ball and make sure it is not affected by forces
        // Ensure theBall is valid before accessing it
        if (theBall && theBall->b2ShapePtr) {
            ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
            ((b2Body *)theBall->b2ShapePtr)->SetAngularVelocity(0);
            ((b2Body *)theBall->b2ShapePtr)->SetAwake(false);
            ((b2Body *)theBall->b2ShapePtr)->SetActive(false);
        }

  
        // Find which brick was hit and remove only that one
        for (auto it = physicsObjects.begin(); it != physicsObjects.end(); ++it) {
            if (it->second && it->second->b2ShapePtr) {
                world->DestroyBody(((b2Body *)it->second->b2ShapePtr));
                delete it->second;
                physicsObjects.erase(it);
                break; // Remove only the first brick hit
            }
        }

        
    }
    
    if (world)
    {
        
        while (elapsedTime >= MAX_TIMESTEP)
        {
            world->Step(MAX_TIMESTEP, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
            elapsedTime -= MAX_TIMESTEP;
        }
        
        if (elapsedTime > 0.0f)
        {
            world->Step(elapsedTime, NUM_VEL_ITERATIONS, NUM_POS_ITERATIONS);
        }
        
    }
    
    // Destroy bricks that were hit AFTER Step() to avoid Box2D errors
    for (const std::string &brickName : bricksToDestroy) {
        auto it = physicsObjects.find(brickName);
        if (it != physicsObjects.end()) {
            world->DestroyBody((b2Body *)it->second->b2ShapePtr);
            delete it->second;
            physicsObjects.erase(it);
        }
    }
    bricksToDestroy.clear();  // Clear the pending list

    
    // Update each node based on the new position from Box2D
    for (auto const &b:physicsObjects) {
        if (b.second && b.second->b2ShapePtr) {
            b.second->loc.x = ((b2Body *)b.second->b2ShapePtr)->GetPosition().x;
            b.second->loc.y = ((b2Body *)b.second->b2ShapePtr)->GetPosition().y;
        }
    }
    
}


- (void)RegisterHit:(const char *)brickName {
    std::string brick = brickName; // Use directly in C++
    bricksToDestroy.push_back(brick);
}



-(void)LaunchBall
{
    // Set some flag here for processing later...
    ballLaunched = true;
    // Get the ball object
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    if (!theBall || !theBall->b2ShapePtr) return; // Ensure the ball exists

    b2Body *ballBody = (b2Body *)theBall->b2ShapePtr;

    // Reset velocity
    ballBody->SetLinearVelocity(b2Vec2(0, 0));
    ballBody->SetAngularVelocity(0);

    // Apply **diagonal** force (both upward and sideways)
    float launchSpeedX = BALL_VELOCITY * 0.7f;  // 70% power on X-axis
    float launchSpeedY = BALL_VELOCITY * 0.7f;  // 70% power on Y-axis

    ballBody->ApplyLinearImpulse(b2Vec2(launchSpeedX, launchSpeedY),
                                 ballBody->GetWorldCenter(),
                                 true);

    ballBody->SetActive(true);
}

// Method to move the paddle
- (void)MovePaddle:(float)xPos yPos:(float)yPos
{
    // Get the paddle object from physicsObjects map
    struct PhysicsObject *thePaddle = physicsObjects[std::string("Paddle")];
    
    // Ensure the paddle exists and is valid
    if (thePaddle && thePaddle->b2ShapePtr) {
        b2Body *paddleBody = (b2Body *)thePaddle->b2ShapePtr;
        
        // Set the paddle's new position (this will move the paddle)
        paddleBody->SetTransform(b2Vec2(xPos, yPos), paddleBody->GetAngle());
    }
}

-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj
{
    
    // Set up the body definition and create the body from it
    b2BodyDef bodyDef;
    b2Body *theObject;
    
    // Make the brick static
    if (strncmp(name, "Brick", 5) == 0) {  // Check if it's any brick
        bodyDef.type = b2_staticBody; // Set all bricks as static
    } else if (strncmp(name, "Paddle", 6) == 0){ // Check if it's the paddle
        bodyDef.type = b2_kinematicBody; //set paddle to kinematic
    }else{
        bodyDef.type = b2_dynamicBody; //ball is dynamic
    }

    bodyDef.position.Set(newObj->loc.x, newObj->loc.y);
    theObject = world->CreateBody(&bodyDef);
    if (!theObject) return;
    
    // Setup our physics object and store this object and the shape
    newObj->b2ShapePtr = (void *)theObject;
    newObj->box2DObj = (__bridge void *)self;
    
    // Set the user data to be this object and keep it asleep initially
    theObject->SetUserData(newObj);
    theObject->SetAwake(false);
    
    // Based on the objType passed in, create a box or circle
    b2PolygonShape dynamicBox;
    b2CircleShape circle;
    b2PolygonShape dynamicPaddle;
    b2FixtureDef fixtureDef;
    
    
    switch (newObj->objType) {
            
        case ObjTypeBox:
            // Check if it's the paddle (assuming the paddle name contains "Paddle")
            if (strncmp(name, "Paddle", 6) == 0) {
                cout<<"paddle";
                // For the paddle, we want it to have the shape of a brick but be dynamic
                dynamicBox.SetAsBox(PADDLE_WIDTH / 2, PADDLE_HEIGHT / 2);
                fixtureDef.shape = &dynamicBox;
                fixtureDef.density = 2.0f;
                fixtureDef.friction = 0.3f;
                fixtureDef.restitution = 0.5f;  // Lower restitution for paddle for realistic bounce
                
            } else {
                
                cout<<"box";
                // For other box-shaped objects (bricks)
                dynamicBox.SetAsBox(BRICK_WIDTH / 2, BRICK_HEIGHT / 2);
                fixtureDef.shape = &dynamicBox;
                fixtureDef.density = 1.0f;
                fixtureDef.friction = 0.3f;
                fixtureDef.restitution = 1.0f;  // Higher restitution for bricks
            }
            break;
            
        case ObjTypeCircle:
            
            circle.m_radius = BALL_RADIUS;
            fixtureDef.shape = &circle;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            theObject->SetGravityScale(0.0f);
            
            break;
            
            
        default:
            
            break;
            
    }
    
    // Add the new fixture to the Box2D object and add our physics object to our map
    theObject->CreateFixture(&fixtureDef);
    physicsObjects[name] = newObj;
    
}

-(struct PhysicsObject *) GetObject:(const char *)name
{
    return physicsObjects[name];
}


-(void)Reset
{
    
    
    // Look up the ball object and re-initialize the position, etc.
    struct PhysicsObject *theBall = physicsObjects["Ball"];
    theBall->loc.x = BALL_POS_X;
    theBall->loc.y = BALL_POS_Y;
    ((b2Body *)theBall->b2ShapePtr)->SetTransform(b2Vec2(BALL_POS_X, BALL_POS_Y), 0);
    ((b2Body *)theBall->b2ShapePtr)->SetLinearVelocity(b2Vec2(0, 0));
    ((b2Body *)theBall->b2ShapePtr)->SetAngularVelocity(0);
    ((b2Body *)theBall->b2ShapePtr)->SetAwake(false);
    ((b2Body *)theBall->b2ShapePtr)->SetActive(true);
    
    totalElapsedTime = 0;
    ballLaunched = false;
    
}

- (void *)GetPhysicsObjects {
    return (void *)&physicsObjects;
}




@end
