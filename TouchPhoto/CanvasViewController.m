//
//  CanvasViewController.m
//  TouchPhoto
//
//  Created by Vo Thanh Cong on 2/21/12.
//  Copyright (c) 2012 BeeDream Studios. All rights reserved.
//

#import "CanvasViewController.h"

typedef struct {
    float Position[3];
    float TexCoord[2];
} Vertex;

//const Vertex Vertices[] = {
//    {{1, -1, 1}, {1, 0}},
//    {{1, 1, 1}, {1, 1}},
//    {{-1, 1, 1}, {0, 1}},
//    {{-1, -1, 1}, {0, 0}},
//};

const GLubyte Indices[] = {
    0, 1, 2,
    2, 3, 0,
};



@interface CanvasViewController () {
    BOOL _increasing;
    
    GLuint _vertexBuffer;
    GLuint _indexBuffer;   
    GLuint _vertexArray;
    
    // Translate
    float _rotation;
    float _zooming;
    float _panX;
    float _panY;
    
    //multitouch
    NSInteger _numberOfTouches;
    
    CGSize _screenSize;
    
}
@property (strong, nonatomic) EAGLContext *context;
@property (strong, nonatomic) GLKBaseEffect *effect;

@end


@implementation CanvasViewController
@synthesize context = _context;
@synthesize effect = _effect;

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        // Custom initialization
    }
    return self;
}

- (void)didReceiveMemoryWarning
{
    // Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];
    
    // Release any cached data, images, etc that aren't in use.
}

#pragma mark Transforming

- (void)resetTransform {
    _rotation = 0;
    _zooming = 1;
//    _zooming = 1;    
    _panX = 0;
    _panY = 0;
}


#pragma mark - View lifecycle

/*
// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView
{
}
*/
- (void)setupGL {
    //KONG: move from const in header into this method, so that we can modify it to fit image's width/height
    Vertex Vertices[] = {
        {{1, -1, 0}, {1, 0}},
        {{1, 1, 0}, {1, 1}},
        {{-1, 1, 0}, {0, 1}},
        {{-1, -1, 0}, {0, 0}},
    };

    _screenSize = self.view.frame.size;
    
    [EAGLContext setCurrentContext:self.context];
    glEnable(GL_CULL_FACE);
    
    self.effect = [[GLKBaseEffect alloc] init];
    
    NSDictionary * options = [NSDictionary dictionaryWithObjectsAndKeys:
                              [NSNumber numberWithBool:YES],
                              GLKTextureLoaderOriginBottomLeft, 
                              nil];
    
    NSError * error;    
    NSString *path = [[NSBundle mainBundle] pathForResource:@"foolish-and-hungry" ofType:@"png"];
    GLKTextureInfo * info = [GLKTextureLoader textureWithContentsOfFile:path options:options error:&error];
    if (info == nil) {
        NSLog(@"Error loading file: %@", [error localizedDescription]);
    } else {
        //KONG: adjust drawing Rectangle, in respect to image's width, height
        
//        NSLog(@"Loaded texture: %u %u", info.width, info.height);        
        for (int i= 0; i< sizeof(Vertices)/sizeof(Vertex); i++) {
//            NSLog(@"Loaded texture: %f", Vertices[i].Position[1]);
            Vertices[i].Position[1] *= (float)info.height/info.width;
        }
    }
    self.effect.texture2d0.name = info.name;
    self.effect.texture2d0.enabled = true;
    
    // New lines
    glGenVertexArraysOES(1, &_vertexArray);
    glBindVertexArrayOES(_vertexArray);
    
    // Old stuff
    glGenBuffers(1, &_vertexBuffer);
    glBindBuffer(GL_ARRAY_BUFFER, _vertexBuffer);
    glBufferData(GL_ARRAY_BUFFER, sizeof(Vertices), Vertices, GL_STATIC_DRAW);
    
    glGenBuffers(1, &_indexBuffer);
    glBindBuffer(GL_ELEMENT_ARRAY_BUFFER, _indexBuffer);
    glBufferData(GL_ELEMENT_ARRAY_BUFFER, sizeof(Indices), Indices, GL_STATIC_DRAW);
    
    // New lines (were previously in draw)
    glEnableVertexAttribArray(GLKVertexAttribPosition);        
    glVertexAttribPointer(GLKVertexAttribPosition, 3, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Position));
//    glEnableVertexAttribArray(GLKVertexAttribColor);
//    glVertexAttribPointer(GLKVertexAttribColor, 4, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, Color));
    glEnableVertexAttribArray(GLKVertexAttribTexCoord0);
    glVertexAttribPointer(GLKVertexAttribTexCoord0, 2, GL_FLOAT, GL_FALSE, sizeof(Vertex), (const GLvoid *) offsetof(Vertex, TexCoord));
    
    // New line
    glBindVertexArrayOES(0);
}

- (void)tearDownGL {
    
    [EAGLContext setCurrentContext:self.context];
    
    glDeleteBuffers(1, &_vertexBuffer);
    glDeleteBuffers(1, &_indexBuffer);
    //glDeleteVertexArraysOES(1, &_vertexArray);
    
    self.effect = nil;    
    
}

// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    self.context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!self.context) {
        NSLog(@"Failed to create ES context");
    }
    
    GLKView *view = (GLKView *) self.view;
    view.context = self.context;
    
    [self setupGL];
    [self resetTransform];
}


- (void)viewDidUnload
{
    [super viewDidUnload];
    // Release any retained subviews of the main view.
    // e.g. self.myOutlet = nil;
    
    [self tearDownGL];

    
    if ([EAGLContext currentContext] == self.context) {
        [EAGLContext setCurrentContext:nil];
    }
    self.context = nil;
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation
{
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}


#pragma mark - GLKViewDelegate

- (void)glkView:(GLKView *)view drawInRect:(CGRect)rect {
    
    glClearColor(1.0, 1.0, 1.0, 1.0);
    glClear(GL_COLOR_BUFFER_BIT);
    
    [self.effect prepareToDraw];    
    
    glBindVertexArrayOES(_vertexArray);   
    glDrawElements(GL_TRIANGLES, sizeof(Indices)/sizeof(Indices[0]), GL_UNSIGNED_BYTE, 0);
}


#pragma mark - GLKViewControllerDelegate
static float const projectionNear = 0;
static float const projectionFar = 10.0;

- (void)update {
    
//    float aspect = fabsf(self.view.bounds.size.width / self.view.bounds.size.height);
//    GLKMatrix4 projectionMatrix = GLKMatrix4MakePerspective(GLKMathDegreesToRadians(65.0f), aspect, 0, 10);    
    
    CGRect rect = self.view.frame;
    GLKMatrix4 projectionMatrix = GLKMatrix4MakeOrtho(-1.0, 
                                                      1.0, 
                                                      -1.0 / (rect.size.width / rect.size.height), 
                                                      1.0 / (rect.size.width / rect.size.height), 
                                                      0.01, 
                                                      10000.0);
    self.effect.transform.projectionMatrix = projectionMatrix;
    
    GLKMatrix4 modelViewMatrix = GLKMatrix4MakeTranslation( _panX * 2/ (self.view.frame.size.width),
                                                           - _panY * 2/ (self.view.frame.size.width),
                                                           -1);

//    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(10), 0, 0, 1);    
    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 0, 0, 1);
//    if (_rotation > 0) {
//        modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, _rotation, 0, 0, 1);
////        _rotation = 0;        
//    }

    //KONG: we can use GLKMatrix4RotateZ, too
    
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, _zooming, _zooming, 1);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}


#pragma mark OpenGL Utilities
- (CGFloat)distanceFrom:(CGPoint)pointA to:(CGPoint)pointB {
	float x = pointB.x - pointA.x;
    float y = pointB.y - pointA.y;
    return sqrt(x * x + y * y);
}

- (CGPoint)vectorFrom:(CGPoint)pointA to:(CGPoint)pointB {
    return CGPointMake(pointB.x - pointA.x, pointB.y - pointA.y);
}

//- (CGFloat)angleFrom:(CGPoint)vectorA to:(CGPoint)vectorB {
//    // dot product of the 2 vectors
//    float dotProduct = vectorA.x * vectorB.x + vectorA.y * vectorB.y;   
//    // product of the squared lengths
//    float productOfLenghs = sqrt((vectorA.x * vectorA.x + vectorA.y * vectorA.y) * (vectorB.x * vectorB.x + vectorB.y * vectorB.y));
//    
//    
//    CGFloat angle;
//    if (productOfLenghs == 0) {
//        angle = 0;
//    } else {
//        angle = acos(dotProduct / productOfLenghs);
//    }
//    
//    NSLog(@"angle: %f", GLKMathRadiansToDegrees(angle));
//    
//    return angle;
//}

- (CGFloat)angleFrom:(CGPoint)vectorA to:(CGPoint)vectorB {
    // dot product of the 2 vectors

    CGFloat angle1 = atan2(vectorA.y, vectorA.x);
    NSLog(@"angle1: %f", GLKMathRadiansToDegrees(angle1));    
    CGFloat angle2 = atan2(vectorB.y, vectorB.x);    
    NSLog(@"angle2: %f", GLKMathRadiansToDegrees(angle2));    
    
    CGFloat angle = angle1 - angle2;
    NSLog(@"angle: %f", GLKMathRadiansToDegrees(angle));
    return angle;
}

- (CGPoint)translatePoint:(CGPoint)point withVector:(CGPoint)vector {
    return CGPointMake(point.x + vector.x, point.y + vector.y);
}


- (CGPoint)pointWithCameraEffect:(CGPoint)location {
    //KONG: 3 transformation:
    // move from bottom-left to center
    // scale
    // move from center back to bottom-left
    
    location.x = (location.x - _screenSize.width/2) * _zooming + _screenSize.width/2;
    location.y = (location.y - _screenSize.height/2) * _zooming + _screenSize.height/2;
    
    location.x += _panX;
    location.y += _panY;
    
    return location;
}

- (CGPoint)pointWithOutCameraEffect:(CGPoint)location {    
    location.x -= _panX;
    location.y -= _panY;
    
    //KONG: 3 transformation:
    // move from bottom-left to center
    // scale
    // move from center back to bottom-left
    
    location.x = (location.x - _screenSize.width/2)/_zooming + _screenSize.width/2;
    location.y = (location.y - _screenSize.height/2)/_zooming + _screenSize.height/2;
    return location;
}


- (CGPoint)convertToGL:(CGPoint)uiPoint {
	float newY = _screenSize.height - uiPoint.y;
    CGPoint glPoint = CGPointMake(uiPoint.x, newY );
	return glPoint;
}

- (CGPoint)revertFromGL:(CGPoint)glPoint {
    CGPoint uiPoint = CGPointMake(glPoint.x, glPoint.y);
	float newY = _screenSize.height - uiPoint.y;
    uiPoint = CGPointMake(uiPoint.x, newY);
    
	return uiPoint;
}

#pragma mark Handling Multi-touches Events

- (void)panWithVector:(CGPoint)vector {
//    NSLog(@"panWithVector: %@", NSStringFromCGPoint(vector));    
    _panX += (float)vector.x;
    _panY += (float)vector.y;
//    NSLog(@"panWithVector: %f %f", _panX, _panY);       
}

static const CGFloat kZoomMaxScale = 5;
static const CGFloat kZoomMinScale = 0.8;

- (void)zoomAtPoint:(CGPoint)center scale:(CGFloat)scale {
    NSLog(@"zoomAtPoint: %@ scale: %f", NSStringFromCGPoint(center), scale);
    
    CGPoint A_w = center;
    
    CGPoint A_d = [self pointWithOutCameraEffect:A_w];
    
    CGPoint A_gl = [self convertToGL:A_d];
    
    CGPoint A_t = CGPointMake(A_gl.x - _screenSize.width/2, A_gl.y - _screenSize.height/2);
    CGPoint Ao_t = CGPointMake(A_t.x * scale, A_t.y * scale); 
    CGPoint Ao_gl = CGPointMake(Ao_t.x + _screenSize.width/2, Ao_t.y + _screenSize.height/2); 
        
    CGPoint Ao_d = [self revertFromGL:Ao_gl];
    CGPoint Ao_w = [self pointWithCameraEffect:Ao_d];
    
    //KONG: moving Ao back to A
    [self panWithVector:CGPointMake((A_w.x - Ao_w.x), (A_w.y - Ao_w.y))];
    
    
    _zooming *= scale;
    
    if (_zooming < kZoomMinScale) {
        _zooming = kZoomMinScale;
    } else if (_zooming > kZoomMaxScale) {
      //  _zooming = kZoomMaxScale;
    }

}

- (void)rotateWithAngle:(float)radian {
    NSLog(@"rotateWithAngle: %f", radian);
    _rotation += radian;
    
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
    NSLog(@"touchesBegan: %@", NSStringFromCGPoint([[touches anyObject] locationInView:self.view]));
//    [self zoomAtPoint:CGPointMake(_screenSize.width/2, _screenSize.height/2) scale:1.5];
//    [self zoomAtPoint:CGPointMake(0, 0) scale:1.5];    
//    [self zoomAtPoint:[[touches anyObject] locationInView:self.view] scale:1.5];        
//    [self rotateWithAngle:30];
    NSLog(@"touches: %d", [touches count]);
    NSLog(@"event: %d", [[event allTouches] count]);
    return;
    
    //KONG: test
//    CGPoint pointA = CGPointMake(0, 0);    
//    CGPoint pointB = CGPointMake(10, 0);
//    
//    CGPoint pointA_ = CGPointMake(0, 0);
//    CGPoint pointB_ = CGPointMake(10, 10);


    CGPoint pointA = CGPointMake(0, 0);    
    CGPoint pointB = CGPointMake(10, 10);
    
    CGPoint pointA_ = CGPointMake(0, 0);
    CGPoint pointB_ = CGPointMake(10, 0);

    
    
    //- First. move A to A’ by using a Translation with vector AA’, B is also moved to B1
    CGPoint vectorAA_ = [self vectorFrom:pointA to:pointA_];
    [self panWithVector:vectorAA_];
    
    // Calculate B1
    CGPoint pointB1 = [self translatePoint:pointB withVector:vectorAA_];
    
    //- Second, move B1 to B2 by using a resize with origin in A’, scale A’B'/A’B1
    CGFloat scale = [self distanceFrom:pointA_ to:pointB_] / [self distanceFrom:pointA_ to:pointB1];
    [self zoomAtPoint:pointA_ scale:scale];
    
    
    // Calculate pointB2: vectorA_B2 = scale * vector A_B1
    //        CGPoint pointB2;
    //        pointB2.x = scale * (pointB1.x - pointA_.x) + pointA_.x;
    //        pointB2.y = scale * (pointB1.y - pointA_.y) + pointA_.y;
    
    //- Finally, use a Rotation with origin A’, angle (A’B2, A’B') to make vector A’B2 to same direction with A’B', B2 is moved to B’
    CGPoint vectorAB = [self vectorFrom:pointA to:pointB];
    CGPoint vectorA_B_ = [self vectorFrom:pointA_ to:pointB_];        
    //        [self rotateWithAngle:[self angleFrom:vectorA_B_ to:vectorAB]];
    [self rotateWithAngle:[self angleFrom:vectorAB to:vectorA_B_]];    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesMoved: %@", touches);    
//    return;

    //KONG: move from point A to A_
    NSArray *allTouches = [[event allTouches] allObjects];
    
    if ([allTouches count] == 1) {
        UITouch *touch = [allTouches objectAtIndex:0];
        CGPoint pointA_ = [touch locationInView:self.view];
        CGPoint pointA = [touch previousLocationInView:self.view];
        [self panWithVector:CGPointMake(pointA_.x - pointA.x, pointA_.y - pointA.y)];
    } else if ([allTouches count] == 2) {
        
        UITouch *touchA = [allTouches objectAtIndex:0];
        UITouch *touchB = [allTouches objectAtIndex:1];
        
        CGPoint pointA_ = [touchA locationInView:self.view];
        CGPoint pointA = [touchA previousLocationInView:self.view];
        
        CGPoint pointB_ = [touchB locationInView:self.view];
        CGPoint pointB = [touchB previousLocationInView:self.view];

        
        //KONG: test
//        CGPoint pointA_ = CGPointMake(0, 0);
//        CGPoint pointA = CGPointMake(0, 0);
//        
//        CGPoint pointB_ = CGPointMake(10, 0);
//        CGPoint pointB = CGPointMake(10, 10);

        
        
        //- First. move A to A’ by using a Translation with vector AA’, B is also moved to B1
        CGPoint vectorAA_ = [self vectorFrom:pointA to:pointA_];
        [self panWithVector:vectorAA_];
        
        // Calculate B1
        CGPoint pointB1 = [self translatePoint:pointB withVector:vectorAA_];
        
        //- Second, move B1 to B2 by using a resize with origin in A’, scale A’B'/A’B1
        CGFloat scale = [self distanceFrom:pointA_ to:pointB_] / [self distanceFrom:pointA_ to:pointB1];
        [self zoomAtPoint:pointA_ scale:scale];

        
        // Calculate pointB2: vectorA_B2 = scale * vector A_B1
//        CGPoint pointB2;
//        pointB2.x = scale * (pointB1.x - pointA_.x) + pointA_.x;
//        pointB2.y = scale * (pointB1.y - pointA_.y) + pointA_.y;
        
        //- Finally, use a Rotation with origin A’, angle (A’B2, A’B') to make vector A’B2 to same direction with A’B', B2 is moved to B’
        CGPoint vectorAB = [self vectorFrom:pointA to:pointB];
        CGPoint vectorA_B_ = [self vectorFrom:pointA_ to:pointB_];        
//        [self rotateWithAngle:[self angleFrom:vectorA_B_ to:vectorAB]];
        [self rotateWithAngle:[self angleFrom:vectorAB to:vectorA_B_]];        
    }
    
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesEnded: %@", touches);    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesCancelled: %@", touches);    
}

@end
