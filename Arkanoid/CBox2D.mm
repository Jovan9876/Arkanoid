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


// Some Box2D engine paremeters
const float MAX_TIMESTEP = 1.0f/60.0f;
const int NUM_VEL_ITERATIONS = 10;
const int NUM_POS_ITERATIONS = 3;


// Uncomment this lines to use the HelloWorld example
//#define USE_HELLO_WORLD


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

            // Retrieve PhysicsObject structs from user data
            struct PhysicsObject *objDataA = (struct PhysicsObject *)(bodyA->GetUserData());
            struct PhysicsObject *objDataB = (struct PhysicsObject *)(bodyB->GetUserData());

            // Ensure objDataA is not NULL before accessing box2DObj
            if (!objDataA || !objDataA->box2DObj) return;
            if (!objDataB || !objDataB->box2DObj) return;

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
    
    // Box2D-specific objects
    b2Vec2 *gravity;
    b2World *world;
    CContactListener *contactListener;
    float totalElapsedTime;
    
    // Map to keep track of physics object to communicate with the renderer
    std::map<std::string, struct PhysicsObject *> physicsObjects;

    std::string lastHitBrick; // Store the last hit brick
    std::vector<std::string> bricksToDestroy;  // Stores bricks to delete after Step()

    
#ifdef USE_HELLO_WORLD
    b2BodyDef *groundBodyDef;
    b2Body *groundBody;
    b2PolygonShape *groundBox;
#endif

    // Logit for this particular "game"
    bool ballHitBrick;  // register that the ball hit the break
    bool ballLaunched;  // register that the user has launched the ball
    
}
@end

@implementation CBox2D


- (instancetype)init
{


    self = [super init];
    
    if (self) {
        
        // Initialize Box2D
        gravity = new b2Vec2(0.0f, -10.0f);
        world = new b2World(*gravity);
        
#ifdef USE_HELLO_WORLD
        groundBodyDef = NULL;
        groundBody = NULL;
        groundBox = NULL;
#endif

        contactListener = new CContactListener();
        world->SetContactListener(contactListener);
        
        // Wall dimensions
        float wallThickness = WALL_THICKNESS;
        float playWidth = BRICK_COLUMNS * (BRICK_WIDTH + BRICK_SPACING);
        float playHeight = BRICK_ROWS * (BRICK_HEIGHT + BRICK_SPACING) + 100;

        // TOP WALL - Consistent with SceneKit
        b2BodyDef topWallDef;
        topWallDef.position.Set(BRICK_POS_X + (playWidth / 2) - 20, BRICK_POS_Y + playHeight-80 + wallThickness);
        b2Body* topWall = world->CreateBody(&topWallDef);

        b2PolygonShape topWallShape;
        topWallShape.SetAsBox(playWidth / 2, wallThickness / 2);
        topWall->CreateFixture(&topWallShape, 0.0f);

        // LEFT WALL - Consistent with SceneKit
        b2BodyDef leftWallDef;
        leftWallDef.position.Set(BRICK_POS_X - wallThickness - 4,  // Left edge
                                 BRICK_POS_Y + (playHeight / 2) - 70);  // Center vertically
        b2Body* leftWall = world->CreateBody(&leftWallDef);

        b2PolygonShape leftWallShape;
        leftWallShape.SetAsBox(wallThickness / 2, (playHeight / 2) + 50);  // Correct size
        leftWall->CreateFixture(&leftWallShape, 0.0f);

        // RIGHT WALL - Consistent with SceneKit
        b2BodyDef rightWallDef;
        rightWallDef.position.Set(BRICK_POS_X + (playWidth / 2) + (wallThickness / 2) + 20,
                                  BRICK_POS_Y + (playHeight / 2) - 70);
        b2Body* rightWall = world->CreateBody(&rightWallDef);

        b2PolygonShape rightWallShape;
        rightWallShape.SetAsBox(wallThickness / 2, (playHeight / 2) + 50);
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
#ifdef USE_HELLO_WORLD
    if (groundBodyDef) delete groundBodyDef;
    if (groundBox) delete groundBox;
#endif
    if (contactListener) delete contactListener;
    
}

-(void)Update:(float)elapsedTime
{
    
    // Get pointers to the brick and ball physics objects
    struct PhysicsObject *theBrick = physicsObjects[std::string("Brick")];
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
    if (!theBall || !theBall->b2ShapePtr) return;

    b2Body *ballBody = (b2Body *)theBall->b2ShapePtr;

    // Reset velocity
    ballBody->SetLinearVelocity(b2Vec2(0, 0));
    ballBody->SetAngularVelocity(0);

    // Apply **sideways** force instead of vertical
    float launchSpeed = BALL_VELOCITY;  // Adjust if needed
    ballBody->ApplyLinearImpulse(b2Vec2(launchSpeed, 0),  // Move sideways
                                 ballBody->GetWorldCenter(),
                                 true);
    
}

-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj
{
    
    // Set up the body definition and create the body from it
    b2BodyDef bodyDef;
    b2Body *theObject;
    
    

    bodyDef.position.Set(newObj->loc.x, newObj->loc.y);
    theObject = world->CreateBody(&bodyDef);
    if (!theObject) return;
        
    // Make the brick static
    if (strncmp(name, "Brick", 5) == 0) {  // Check if it's any brick
        bodyDef.type = b2_staticBody; // Set all bricks as static
    } else {
        bodyDef.type = b2_dynamicBody;
    }


    bodyDef.position.Set(newObj->loc.x, newObj->loc.y);
    theObject = world->CreateBody(&bodyDef);
    
    
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
    b2FixtureDef fixtureDef;
    
    switch (newObj->objType) {
            
        case ObjTypeBox:
            
            dynamicBox.SetAsBox(BRICK_WIDTH/2, BRICK_HEIGHT/2);
            fixtureDef.shape = &dynamicBox;
            fixtureDef.density = 1.0f;
            fixtureDef.friction = 0.3f;
            fixtureDef.restitution = 1.0f;
            
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


-(void)HelloWorld
{
    
#ifdef USE_HELLO_WORLD
    
    groundBodyDef = new b2BodyDef;
    groundBodyDef->position.Set(0.0f, -10.0f);
    groundBody = world->CreateBody(groundBodyDef);
    groundBox = new b2PolygonShape;
    groundBox->SetAsBox(50.0f, 10.0f);
    
    groundBody->CreateFixture(groundBox, 0.0f);
    
    // Define the dynamic body. We set its position and call the body factory.
    b2BodyDef bodyDef;
    bodyDef.type = b2_dynamicBody;
    bodyDef.position.Set(0.0f, 4.0f);
    b2Body* body = world->CreateBody(&bodyDef);
    
    // Define another box shape for our dynamic body.
    b2PolygonShape dynamicBox;
    dynamicBox.SetAsBox(1.0f, 1.0f);
    
    // Define the dynamic body fixture.
    b2FixtureDef fixtureDef;
    fixtureDef.shape = &dynamicBox;
    
    // Set the box density to be non-zero, so it will be dynamic.
    fixtureDef.density = 1.0f;
    
    // Override the default friction.
    fixtureDef.friction = 0.3f;
    
    // Add the shape to the body.
    body->CreateFixture(&fixtureDef);
    
    // Prepare for simulation. Typically we use a time step of 1/60 of a
    // second (60Hz) and 10 iterations. This provides a high quality simulation
    // in most game scenarios.
    float32 timeStep = 1.0f / 60.0f;
    int32 velocityIterations = 6;
    int32 positionIterations = 2;
    
    // This is our little game loop.
    world->SetGravity(b2Vec2(0, -10.0f));
    for (int32 i = 0; i < 60; ++i)
    {
        
        // Instruct the world to perform a single step of simulation.
        // It is generally best to keep the time step and iterations fixed.
        world->Step(timeStep, velocityIterations, positionIterations);
        
        // Now print the position and angle of the body.
        b2Vec2 position = body->GetPosition();
        float32 angle = body->GetAngle();
        
        printf("%4.2f %4.2f %4.2f\n", position.x, position.y, angle);
        
    }
    
#endif
    
}

@end
