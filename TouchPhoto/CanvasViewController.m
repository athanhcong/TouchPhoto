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
    _rotation = 90;
    _zooming = 4;
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

    modelViewMatrix = GLKMatrix4Rotate(modelViewMatrix, GLKMathDegreesToRadians(_rotation), 0, 0, 1);    
    //KONG: we can use GLKMatrix4RotateZ, too
    
    modelViewMatrix = GLKMatrix4Scale(modelViewMatrix, 1, 1, 1);
    self.effect.transform.modelviewMatrix = modelViewMatrix;
}

#pragma mark Handle Multitouch

- (void)panWithVector:(CGPoint)vector {
//    NSLog(@"panWithVector: %@", NSStringFromCGPoint(vector));    
    _panX += (float)vector.x;
    _panY += (float)vector.y;
//    NSLog(@"panWithVector: %f %f", _panX, _panY);       
}



- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {	
//    NSLog(@"touchesBegan: %@", touches);
    
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesMoved: %@", touches);    
//    return;
    UITouch *touch = [touches anyObject];
    //KONG: move from point A to A_
    CGPoint pointA_ = [touch locationInView:self.view];
    CGPoint pointA = [touch previousLocationInView:self.view];
    [self panWithVector:CGPointMake(pointA_.x - pointA.x, pointA_.y - pointA.y)];
}

- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesEnded: %@", touches);    
}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event {
//    NSLog(@"touchesCancelled: %@", touches);    
}

@end
