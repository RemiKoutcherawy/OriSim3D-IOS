#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import <math.h>

#import "View3D.h"
#import "Commands.h"
#import "Model.h"
#import "OrFace.h"
#import "OrPoint.h"
#import "Vector3D.h"
#import "Segment.h"

#define GetGLError()									\
{														\
GLenum err = glGetError();							\
while (err != GL_NO_ERROR) {						\
NSLog(@"GLError set in File:%s Line:%d\n",	\
__FILE__,	__LINE__);								\
err = glGetError();								\
}													\
}

@implementation View3D

+ (Class) layerClass {
  return [CAEAGLLayer class];
}

@synthesize context;
@synthesize commands;
@synthesize model;      // model is my Model not the one defined in UIDevice


// Return true if not a power of two
- (BOOL) isNotPower2:(int) n {
  return 2*n != (n ^ (n-1)) + 1;
}
// Find the smallest power of two >= the input value.
- (int) roundUpPower2:(int) x
{
  x = x - 1;
  x = x | (x >> 1);  x = x | (x >> 2);
  x = x | (x >> 4);  x = x | (x >> 8);
  x = x | (x >>16);
  return x + 1;
}

// Load image, pad it to the next power of two
- (void)loadImageFile:(NSString *)name ofType:(NSString *)extension texture:(uint32_t)texture {
  // Load original
  UIImage *image =[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:extension]];
	if (image == nil) {
		NSLog(@"Failed to load %@.%@", name, extension);
		return;
	}
	// Get image informations
	CGImageRef cgImage = [image CGImage];
	int width = CGImageGetWidth(cgImage);
	int height = CGImageGetHeight(cgImage);
  
  // Default assume power of two
  int wpot = width;
  int hpot = height;
  
  // Check if w or h is not a power of two, then round up to next POT
  if ([self isNotPower2:width] || [self isNotPower2:height]){
    // Extend dimensions to power of two
    wpot = [self roundUpPower2:width];
    hpot = [self roundUpPower2:height];
  }

  // Create new bitmap
  GLubyte *data = (GLubyte *)malloc(wpot * hpot * 4); // GL_RGBA : 4 bytes per pixel
  // 32-bit pixel format and RGB color space, you would specify a value of 8 bits per component
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  // GL_RGBA 8 bits per component, 4 components => 4 bytes per pixel
  // RGB 32 bpp, 8 bpc, kCGImageAlphaNoneSkipLast Mac OS X, iOS
  // RGB 32 bpp, 8 bpc, kCGImageAlphaPremultipliedLast Mac OS X, iO => OK
  // void *data, width, height, bitsPerComponent(8), bytesPerRow(4*row), CGColorSpaceRef, CGBitmapInfo
	CGContextRef cgContext = CGBitmapContextCreate(data, wpot, hpot, 8, 4*wpot, colorSpace, kCGImageAlphaPremultipliedLast);
  // Set the blend mode to copy.
  CGContextSetBlendMode(cgContext, kCGBlendModeCopy);
  // Draw upsidedown (the 0,0 is bottom left in OpenGL, top left in CGContext draw)
  // w->wpot so instead of h->hpot we use the same ratio as w->wpot: wpot/w applied to h
  int ws, hs;
//  float k = (float) hpot /(float) height;
//  if (width > height){
//    hs = (height * wpot * 400/566)/width;
//    ws = wpot;
//  }
//  else {
  hs = hpot; //height *k;
  ws = wpot; //width *k;
//  }

  CGContextTranslateCTM(cgContext, 0.0, hs);
  CGContextScaleCTM(cgContext, 1, -1);
  // Begin at the top (bottom in OpenGL) with original size keep ratio
  // Tiled ? Textures use GL_REPEAT so 1=>hpot should point to a cropped h not a tiled
  // h:624 w:441 new h:512 for hpot:1024 wpot:512

  CGContextDrawTiledImage(cgContext, CGRectMake(0, 0, ws, hs), cgImage); //(height*wpot)/width
  // Set new dimensions, all models have a width of 400 and a height of 400 or 566
  if (texture == texfront){
    wTexFront = 400;
    hTexFront = (int)((height * 400) / (float) width);
  }
  else if (texture == texback) {
    wTexBack = 400;
    hTexBack = (int)((height * 400) / (float) width);
  }
  CGContextRelease(cgContext);
	CGColorSpaceRelease(colorSpace);
  
  // Generate texture
  glGenTextures(1, &(textures[texture]));
  glBindTexture(GL_TEXTURE_2D, textures[texture]);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR);
  glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, wpot, hpot, 0, GL_RGBA, GL_UNSIGNED_BYTE, data);
  
  // Check
  GetGLError();
	free(data);
}

// Load 3 textures
- (void)loadTextures {
  [self loadImageFile:@"hulk400x566" ofType:@"jpg" texture:texfront];
  [self loadImageFile:@"fillebleue400x600" ofType:@"jpg"  texture:texback];
	[self loadImageFile:@"background256x256" ofType:@"jpg" texture:texbackground];
}


// Init with frame
- (id)initWithFrame:(CGRect)frame {
  if ((self = [super initWithFrame:frame])) {
    // Get the layer
    eaglLayer = (CAEAGLLayer *)super.layer;
    eaglLayer.opaque = YES;
    eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
                                    [NSNumber numberWithBool:FALSE], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
    backingWidth = CGRectGetWidth(frame);
    backingHeight = CGRectGetHeight(frame);
    
    // init context
    context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
    if (!context || ![EAGLContext setCurrentContext:context]) {
      NSLog(@"View3D initWithFrame failed");
      [self release];
      return nil;
    }
    
    // To trigger OpenGL rendering
    displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(drawView:)];
    [displayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
    
    scale = 1.0f;
		rotate = 0.0f;
    angleX = 0.0f;
    angleY = 0.0f;
    
		[self loadTextures];
		[self setMultipleTouchEnabled:YES];
    
    // Model
    model = [[Model alloc] init] ;
    
    // Commands
    commands = [[Commands alloc] initWithView3D:self];
    
    // First commands
    NSString *modelName = @"test";
    NSMutableString *cde = [[NSMutableString alloc] init];
    [cde appendString:@"read "];
    [cde appendString:modelName];
    
    // Launch
    [commands commandWithNSString:cde];
    [cde release];
    
    // Textures on
    texturesON = YES;
  }
  return self;
}

// Called from ChoiceController
- (void)setPliage:(NSString *)pliage {
  // Read pliage
  NSMutableString *cde = [[NSMutableString alloc] init];
  [cde appendString:@"read "];
  [cde appendString:pliage];

  // Restore view
  scale = 1.0;
  rotate = 0.0;
  angleX = 0;
  angleY = 0;
  
  // Launch
  [commands commandWithNSString:cde];
  [cde release];
  [self setMyNeedsDisplay];
}
// Called from commands 
- (void) setMyNeedsDisplay {
  displayLink.paused = FALSE;
}

// Called by sytem
- (void) drawView:(CADisplayLink *)displayLinka {
  [self drawModel];
  [context presentRenderbuffer:GL_RENDERBUFFER_OES];
  displayLink.paused = YES; 
  
  // Call back Commands if animated
  if (animated) {
    animated = [commands anim];
    [self setMyNeedsDisplay];
  }
}

// Called from Commands when animation needs a redraw
- (void)animateWithCommands:(Commands *)thecommands {
  self->commands = thecommands;
  self->animated = YES;
  [self setMyNeedsDisplay];
}

GLfloat *mFVertexBuffer = nil;
GLfloat *mTexBufferFront=nil, *mTexBufferBack=nil;
int nbPts, nbPtsLines, previousNbPts;

// Initialize from model
// Call from onDrawFrame each time the model need to be drawn
// The buffers are allocated only if the number of points changed
// The points are copied to the buffers
- (void) initFromModel {
  // Number of points, for each point of each face add 3 coord points
  nbPts = 0;
  for (OrFace *f in model->faces){
    for (int i = 2; i < [f->points count]; i++)
      // Each time we add one point, we add a triangle with 3 points
      nbPts += 3;
  }
  nbPtsLines = 0;
  for (Segment *s in model->segments) {
    if (s->select || !texturesON)
      // Each line has 2 points
      nbPtsLines += 2;
  }
  if (previousNbPts != (nbPts + nbPtsLines)) {
    // Vertex for faces and lines x 3 coordinates
    if (mFVertexBuffer != nil)
      free(mFVertexBuffer);
    mFVertexBuffer = (GLfloat*) malloc((nbPts + nbPtsLines) * 3 * sizeof(GLfloat));
    if (texturesON) {
      if (mTexBufferFront != nil)
        free(mTexBufferFront);
      if (mTexBufferBack != nil)
        free(mTexBufferBack);
      
      // Texture coordinates for each point of faces x 2 coordinates x 4 bytes
      mTexBufferFront = (GLfloat*) malloc(nbPts * 2 * sizeof(GLfloat));
      mTexBufferBack = (GLfloat*) malloc(nbPts * 2 * sizeof(GLfloat));
    }
  }
  previousNbPts = (nbPts + nbPtsLines);

//  // Index for each point of faces x 2 bytes for short
//  ByteBuffer ibbf = ByteBuffer.allocateDirect(nbPts * 2);
//  ibbf.order(ByteOrder.nativeOrder());
//  mIndexBufferFront = ibbf.asShortBuffer();
//  ByteBuffer ibbb = ByteBuffer.allocateDirect(nbPts * 2);
//  ibbb.order(ByteOrder.nativeOrder());
//  mIndexBufferBack = ibbb.asShortBuffer();
//  
//  // Index for each point of line x 2 bytes for short
//  ByteBuffer ibbl = ByteBuffer.allocateDirect(nbPtsLines * 2);
//  ibbl.order(ByteOrder.nativeOrder());
//  mIndexBufferLines = ibbl.asShortBuffer();
//  
  short indexPts = 0;
  short indexPtsLines = 0;
  short indexTex = 0;
  
  // Put Faces
  for (OrFace *f in model->faces) {
    NSArray *pts = f->points;
    [f computeFaceNormal];
    Vector3D *n = f->normal;
    // Triangle FAN can be used only because of convex CCW face
    // using GL_TRIANGLE_FAN would simplify
    OrPoint *c = [pts objectAtIndex:0]; // center
    OrPoint *p = [pts objectAtIndex:1]; // previous
    for (int i = 2; i < [pts count]; i++) {
      OrPoint *s = [f->points objectAtIndex:i]; // second
      mFVertexBuffer[indexPts++] = c->x + f->offset * n->x;
      mFVertexBuffer[indexPts++] = c->y + f->offset * n->y;
      mFVertexBuffer[indexPts++] = c->z + f->offset * n->z;
//      mFNormalsFront.put(n[0]); mFNormalsFront.put(n[1]); mFNormalsFront.put(n[2]);
//      mFNormalsBack.put(-n[0]); mFNormalsBack.put(-n[1]); mFNormalsBack.put(-n[2]);
      if (texturesON) {
        mTexBufferFront[indexTex] = (200 + c->xf)/wTexFront;
        mTexBufferFront[indexTex+1] = (200 + c->yf)/hTexFront;
        
        mTexBufferBack[indexTex++] = (200 + c->xf)/wTexBack;
        mTexBufferBack[indexTex++] = (hTexBack -200 - c->yf)/hTexBack;
      }
//      mIndexBufferFront.put(index);
//      mIndexBufferBack.put(index);
//      index++;
      mFVertexBuffer[indexPts++] = p->x + f->offset * n->x;
      mFVertexBuffer[indexPts++] = p->y + f->offset * n->y;
      mFVertexBuffer[indexPts++] = p->z + f->offset * n->z;
//      mFNormalsFront.put(n[0]); mFNormalsFront.put(n[1]); mFNormalsFront.put(n[2]);
//      mFNormalsBack.put(-n[0]); mFNormalsBack.put(-n[1]); mFNormalsBack.put(-n[2]);
      if (texturesON) {
        mTexBufferFront[indexTex] = (200 + p->xf)/wTexFront;
        mTexBufferFront[indexTex+1] = (200 + p->yf)/hTexFront;
        
        mTexBufferBack[indexTex++] = (200 + p->xf)/wTexBack;
        mTexBufferBack[indexTex++] = (hTexBack -200 - p->yf)/hTexBack;
      }
//      mIndexBufferFront.put(index);
//      mIndexBufferBack.put((short) (index+1));
//      index++;
      mFVertexBuffer[indexPts++] = s->x + f->offset * n->x;
      mFVertexBuffer[indexPts++] = s->y + f->offset * n->y;
      mFVertexBuffer[indexPts++] = s->z + f->offset * n->z;
//      mFNormalsFront.put(n[0]); mFNormalsFront.put(n[1]); mFNormalsFront.put(n[2]);
//      mFNormalsBack.put(-n[0]); mFNormalsBack.put(-n[1]); mFNormalsBack.put(-n[2]);
      if (texturesON) {
        mTexBufferFront[indexTex] = (200 + s->xf)/wTexFront;
        mTexBufferFront[indexTex+1] = (200 + s->yf)/hTexFront;
        
        mTexBufferBack[indexTex++] = (200 + s->xf)/wTexBack;
        mTexBufferBack[indexTex++] = (hTexBack -200 - s->yf)/hTexBack;
      }
//      mIndexBufferFront.put(index);
//      mIndexBufferBack.put((short) (index-1));
//      index++;
      p = s; // next triangle
    }
  }
  // Put segments in the same vertex buffer, only index is different
  indexPtsLines = indexPts; // start where we left
  for (Segment *s in model->segments) {
    if (s->select || !texturesON) {
      mFVertexBuffer[indexPtsLines++]=s->p1->x;
      mFVertexBuffer[indexPtsLines++]=s->p1->y;
      mFVertexBuffer[indexPtsLines++]=s->p1->z;
//      mIndexBufferLines.put(index++);
      mFVertexBuffer[indexPtsLines++]=s->p2->x;
      mFVertexBuffer[indexPtsLines++]=s->p2->y;
      mFVertexBuffer[indexPtsLines++]=s->p2->z;
//      mIndexBufferLines.put(index++);
    }
  }
}

// Setup background arrays
- (void) drawBackground {
  // Background 2 triangles =  6 Vertex(3), 6 Normal(3)  6 Texture(2)
  const GLfloat vertices[] = {
    -2000.0f, -2000.0f, -2000.0f,
    2000.0f, 2000.0f, -2000.0f,
    -2000.0f, 2000.0f, -2000.0f,
    
    -2000.0f, -2000.0f, -2000.0f,
    2000.0f, -2000.0f, -2000.0f,
    2000.0f, 2000.0f, -2000.0f
  };
  const GLfloat texCoords[] = {
    0, 0,    10, 10,    0, 10,
    0, 0,    10, 0,    10, 10
  };
  const GLfloat normals[] = {
    0, 0, 1,    0, 0, 1,    0, 0, 1,
    0, 0, 1,    0, 0, 1,    0, 0, 1,
  };
  // begin textures
  glEnable(GL_TEXTURE_2D);
  glFrontFace(GL_CCW);
  
  glVertexPointer(3, GL_FLOAT, 0, vertices);
  glEnableClientState(GL_VERTEX_ARRAY);
  // Check
  GetGLError();
  
  glNormalPointer(GL_FLOAT, 0, normals);
  glEnableClientState(GL_NORMAL_ARRAY);
  // Check
  GetGLError();
  
  glTexCoordPointer(2, GL_FLOAT, 0, texCoords);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
	glBindTexture(GL_TEXTURE_2D, textures[texbackground]);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  
  glDrawArrays(GL_TRIANGLES, 0, 6);
}

// Main drawing
- (void) drawModel {
//  glClearColor(1.0f, 0.5f, 0.5f, 1);
//  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);

  // Un rectangle 400x572 -200+200 x -286+286
  [EAGLContext setCurrentContext:context];
  GetGLError();
  
  glViewport(0, 0, backingWidth, backingHeight);
  GetGLError();
  
  glMatrixMode(GL_PROJECTION);
  glLoadIdentity();
  
  //	glFrustumf(-1.0f, 1.0f, -1.5, 1.5, 1.0f, 10.0f);
  //  GLU.gluPerspective(gl, 30, ratio, 1, 4000); Android source Bugged !! Should be :
  //  GLU.gluPerspective(gl, 30, (float) w /h, 1, 4000);
  //  600 1200 semble OK mais le zoom coupe l'image...
  float ratio = (float) backingWidth / backingHeight, fov = 30.0f, near = 60, far = 12000, top, bottom, left, right;
  if (ratio >= 1.0f){
    top = near * (float) tan(fov * (M_PI / 360.0));
    bottom = -top;
    left = bottom * ratio;
    right = top * ratio;
  } else {
    right = near * (float) tan(fov * (M_PI / 360.0));
    left = -right;
    top = right / ratio;
    bottom = left / ratio;
  }
  glFrustumf(left, right, bottom, top, near, far);
  glTranslatef(0.0f, -20.0f, -900.0f);// -40.0f en y
  
  // Switch to ModelView to draw background
  glPushMatrix();
  glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();

  // Clear
  glClearColor(0.5f, 0.5f, 0.5f, 1.0f);
  glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
  
  // Draw Background
  [self drawBackground];
  
  // Switch to Projection to handle rotation
  glMatrixMode(GL_PROJECTION);
  glPopMatrix();

  // Handle rotation (in GL_PROJECTION assured to be centered )
  glRotatef(angleX, 0, 1, 0);// Yes there is an inversion between X and Y
  glRotatef(angleY, 1, 0, 0);
  
  // Switch to ModelView to draw model
  glMatrixMode(GL_MODELVIEW);
	glLoadIdentity();
  
  // Handle scale in modelview
	glScalef(scale, scale, 1.0f);
  // Draw only one side of triangle
  glEnable(GL_CULL_FACE);
  
  // Set points arrays *mFVertexBuffer
  // Set texture arrays *mTexBufferFront, *mTextBufferBack
  // from model
  [self initFromModel];
  
  // Begin textures
  glEnable(GL_TEXTURE_2D);
  glEnableClientState(GL_TEXTURE_COORD_ARRAY);
  glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_REPEAT);
	glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_REPEAT);
  glEnableClientState(GL_VERTEX_ARRAY);
  
  // Enable depth test
  glEnable(GL_DEPTH_TEST);

  // Front face
  glFrontFace(GL_CCW);
  glVertexPointer(3, GL_FLOAT, 0, mFVertexBuffer);
  // Front Texture
  glTexCoordPointer(2, GL_FLOAT, 0, mTexBufferFront);
	glBindTexture(GL_TEXTURE_2D, textures[texfront]);
  // Draw front face
  glDrawArrays(GL_TRIANGLES, 0, nbPts); // GL_TRIANGLE_FAN ?
  
  // Back face
  glFrontFace(GL_CW);
  glVertexPointer(3, GL_FLOAT, 0, mFVertexBuffer);
  // Back texture
  glTexCoordPointer(2, GL_FLOAT, 0, mTexBufferBack);
	glBindTexture(GL_TEXTURE_2D, textures[texback]);
  // Draw back face
  glDrawArrays(GL_TRIANGLES, 0, nbPts);
  
  // end textures
	glDisable(GL_TEXTURE_2D);
  GetGLError();
  
  // Lines - a mess to get black lines => no texture no light
  glColor4f(0.0f, 0.0f, 0.0f, 1.0f); // rgba => black
  glDisable(GL_TEXTURE_2D);
  glDisable(GL_LIGHTING);
  glLineWidth(3.0f);
  glClear(GL_DEPTH_BUFFER_BIT); // See through faces
  glVertexPointer(3, GL_FLOAT, 0, mFVertexBuffer);
  glDrawArrays(GL_LINES, nbPts, nbPtsLines);
  glColor4f(1.0f, 1.0f, 1.0f, 1.0f); // rgba => white
//  glDrawElements(GL_LINES, nbPtsLines, GL_UNSIGNED_SHORT, mIndexBufferLines);

  // Render
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
//  [context presentRenderbuffer:GL_RENDERBUFFER_OES];
  
	// Check
  GetGLError();
}

- (void)layoutSubviews {
  [EAGLContext setCurrentContext:context];
  [self destroyFramebuffer];
  [self createFramebuffer];
  [self drawModel];
  [self setMyNeedsDisplay];
}

- (BOOL)createFramebuffer {
  glGenFramebuffersOES(1, &framebuffer);
  glGenRenderbuffersOES(1, &renderbuffer);

  glBindFramebufferOES(GL_FRAMEBUFFER_OES, framebuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, renderbuffer);
  [context renderbufferStorage:GL_RENDERBUFFER_OES fromDrawable:(CAEAGLLayer*)self.layer];
  glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_COLOR_ATTACHMENT0_OES, GL_RENDERBUFFER_OES, renderbuffer);

  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_WIDTH_OES, &backingWidth);
  glGetRenderbufferParameterivOES(GL_RENDERBUFFER_OES, GL_RENDERBUFFER_HEIGHT_OES, &backingHeight);
  GetGLError();
  
  glGenRenderbuffersOES(1, &depthRenderbuffer);
  glBindRenderbufferOES(GL_RENDERBUFFER_OES, depthRenderbuffer);
  glRenderbufferStorageOES(GL_RENDERBUFFER_OES, GL_DEPTH_COMPONENT16_OES, backingWidth, backingHeight);
  glFramebufferRenderbufferOES(GL_FRAMEBUFFER_OES, GL_DEPTH_ATTACHMENT_OES, GL_RENDERBUFFER_OES, depthRenderbuffer);
  GetGLError();

  if(glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES) != GL_FRAMEBUFFER_COMPLETE_OES) {
    NSLog(@"failed to make complete framebuffer object %x", glCheckFramebufferStatusOES(GL_FRAMEBUFFER_OES));
    return NO;
  }
  return YES;
}

- (void)destroyFramebuffer {
  glDeleteFramebuffersOES(1, &framebuffer);
  framebuffer = 0;
  glDeleteRenderbuffersOES(1, &renderbuffer);
  renderbuffer = 0;
  glDeleteRenderbuffersOES(1, &depthRenderbuffer);
  depthRenderbuffer = 0;
}

- (void)dealloc {
  if ([EAGLContext currentContext] == context)
    [EAGLContext setCurrentContext:nil];
	if (textures[texfront] != 0)
		glDeleteTextures(1, &textures[texfront]);
  if (textures[texback] != 0)
		glDeleteTextures(1, &textures[texback]);
  [context release];
  [model release];
  [commands release];
  free(mFVertexBuffer);
  free(mTexBufferBack);
  free(mTexBufferFront);
  [super dealloc];
}
// -------------
// Touch handler
// -------------
- (float)distanceFromPoint:(CGPoint)pointA toPoint:(CGPoint)pointB {
	float xD = fabs(pointA.x - pointB.x);
	float yD = fabs(pointA.y - pointB.y);
	
	return sqrt(xD*xD + yD*yD);
}
- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event {
  [self touchesMoved:touches withEvent:event];
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event {
  [self touchesMoved:touches withEvent:event];
}
- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event {
	UITouch *touchA, *touchB;
	CGPoint pointA, pointB;
  static float lastDownTime, lastUpTime, lastUpUpTime;
  static BOOL wasRunning;
  
	if ([touches count] == 1) {
    touchA = [[touches allObjects] objectAtIndex:0];
    
		pointA = [touchA locationInView:self];
		pointB = [touchA previousLocationInView:self];
		
		float yDistance = pointA.y - pointB.y;
		
		rotate += 0.5 * yDistance;
    angleX += (pointA.x - pointB.x) * 180.0f / 320;
    angleY += (pointA.y - pointB.y) * 180.0f / 320;
    
    float currentTime = CACurrentMediaTime();
    
    // One Pointer up
    if ([touchA phase] == UITouchPhaseEnded){
      // Triple tap undo - UpUpTime is set by double tap
      if ((currentTime - lastUpUpTime) < 0.500f){
        [commands commandWithNSString:@"u"];
      }
      // Double tap restore rotation and zoom fit
      else if ((currentTime - lastUpTime) < 0.500f){
        lastUpUpTime = currentTime;
        scale = 1.0f;
        rotate = 0.0f;
        angleX = 0;
        angleY = 0;
        [commands commandWithNSString:@"zf"];
      }
      // Simple tap continue, if we we were not already running and paused by touch down
      else	if ((currentTime - lastDownTime) < 0.500f){
        lastUpTime = currentTime;
        if (!wasRunning){
          [commands commandWithNSString:@"co"];
        }
      }
    }
    // One first touch, switch to pause
    else if ([touchA phase] == UITouchPhaseBegan) {
      lastDownTime = currentTime;
      if (commands->state == running
          || commands->state == anim) {
        wasRunning = true;
        [commands commandWithNSString:@"pa"];
      } else
        // We were already in pause, touch up should continue
        wasRunning = false;
    }
    // Rotate with one finger
	}
	else if ([touches count] == 2) {
    touchA = [[touches allObjects] objectAtIndex:0];
		touchB = [[touches allObjects] objectAtIndex:1];
    
		pointA = [touchA locationInView:self];
		pointB = [touchB locationInView:self];
		
		float currDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		pointA = [touchA previousLocationInView:self];
		pointB = [touchB previousLocationInView:self];
		
		float prevDistance = [self distanceFromPoint:pointA toPoint:pointB];
		
		scale += 0.005 * (currDistance - prevDistance);
		
		if (scale > 10.0f)
			scale = 10.0f;
		else if (scale < 0.025f)
			scale = 0.025f;
	}
  [self drawModel];
  [self setMyNeedsDisplay];
}

@end
