//====================================================================
//
// (c) Borna Noureddin
// COMP 8051   British Columbia Institute of Technology
// Objective-C++ wrapper for Box2D library
//
//====================================================================

#ifndef MyGLGame_CBox2D_h
#define MyGLGame_CBox2D_h

#import <Foundation/NSObject.h>


// Set up brick and ball physics parameters here:
//   position, width+height (or radius), velocity,
//   and how long to wait before dropping brick

#define BRICK_POS_X           -24
#define BRICK_POS_Y           40
#define BRICK_WIDTH           6.0f
#define BRICK_HEIGHT          3.0f
#define BRICK_ROWS            7
#define BRICK_COLUMNS         5
#define BRICK_SPACING         6
#define BRICK_WAIT            1.0f
#define BALL_POS_X            0
#define BALL_POS_Y            5
#define BALL_RADIUS           2.0f
#define BALL_VELOCITY         1000.0f
#define WALL_THICKNESS        1.0f
#define WALL_LENGTH           100.0f

// You can define other object types here
typedef enum { ObjTypeBox=0, ObjTypeCircle=1 } ObjectType;




// Location of each object in our physics world
struct PhysicsLocation {
    float x, y, theta;
};


// Information about each physics object
struct PhysicsObject {

    struct PhysicsLocation loc; // location
    ObjectType objType;         // type
    void *b2ShapePtr;           // pointer to Box2D shape definition
    void *box2DObj;             // pointer to the CBox2D object for use in callbacks
};


// Wrapper class
@interface CBox2D : NSObject



-(void) HelloWorld; // Basic Hello World! example from Box2D

-(void) LaunchBall;                                                         // launch the ball
-(void) Update:(float)elapsedTime;                                          // update the Box2D engine
- (void)RegisterHit:(const char *)brickName;                                // Register when the ball hits the brick pass in the name of the hit brick

-(void) AddObject:(char *)name newObject:(struct PhysicsObject *)newObj;    // Add a new physics object
-(struct PhysicsObject *) GetObject:(const char *)name;                     // Get a physics object by name
-(void) Reset;                                                              // Reset Box2D

- (void *)GetPhysicsObjects;



@end

#endif
