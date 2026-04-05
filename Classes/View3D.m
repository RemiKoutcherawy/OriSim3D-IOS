#import <MetalKit/MetalKit.h>
#import <math.h>

#import "View3D.h"
#import "Commands.h"
#import "Model.h"
#import "OrFace.h"
#import "OrPoint.h"
#import "Vector3D.h"
#import "Segment.h"
typedef struct {
  simd_float4x4 mvp;
  simd_float4 color;
  uint32_t useTexture;
} Uniforms;
static simd_float4x4 matFrustum(float l, float r, float b, float t, float n, float f) {
  return (simd_float4x4){{
    {2*n/(r-l), 0, 0, 0},
    {0, 2*n/(t-b), 0, 0},
    {(r+l)/(r-l), (t+b)/(t-b), -f/(f-n), -1},
    {0, 0, -f*n/(f-n), 0}
  }};
}
static simd_float4x4 matTranslate(float x, float y, float z) {
  simd_float4x4 m = matrix_identity_float4x4;
  m.columns[3] = simd_make_float4(x, y, z, 1);
  return m;
}
static simd_float4x4 matRotate(float deg, float x, float y, float z) {
  float a = deg * M_PI / 180.0f;
  float c = cosf(a), s = sinf(a);
  simd_float3 ax = simd_normalize(simd_make_float3(x, y, z));
  simd_float4x4 m = matrix_identity_float4x4;
  m.columns[0] = simd_make_float4(c + ax.x*ax.x*(1-c),   ax.y*ax.x*(1-c)+ax.z*s, ax.z*ax.x*(1-c)-ax.y*s, 0);
  m.columns[1] = simd_make_float4(ax.x*ax.y*(1-c)-ax.z*s, c + ax.y*ax.y*(1-c),   ax.z*ax.y*(1-c)+ax.x*s, 0);
  m.columns[2] = simd_make_float4(ax.x*ax.z*(1-c)+ax.y*s, ax.y*ax.z*(1-c)-ax.x*s, c + ax.z*ax.z*(1-c),  0);
  return m;
}
@implementation View3D
    int texfront, texback;

@synthesize commands;
@synthesize model; // model is my Model not the one defined in UIDevice

// Load image
- (void)loadImageFile:(NSString *)name ofType:(NSString *)extension texture:(uint32_t)texture {
  // Load original
  UIImage *image =[UIImage imageWithContentsOfFile:[[NSBundle mainBundle] pathForResource:name ofType:extension]];
	if (image == nil) {
		NSLog(@"Failed to load %@.%@", name, extension);
		return;
	}
	// Get image informations
	CGImageRef cgImage = [image CGImage];
	int width = (int)CGImageGetWidth(cgImage);
	int height = (int)CGImageGetHeight(cgImage);
  int wpot = width;
  int hpot = height;

  // Create new bitmap
  GLubyte *data = (GLubyte *)malloc(wpot * hpot * 4); // GL_RGBA : 4 bytes per pixel
  // 32-bit pixel format and RGB color space, you would specify a value of 8 bits per component
  CGColorSpaceRef colorSpace = CGColorSpaceCreateDeviceRGB();
  // GL_RGBA 8 bits per component, 4 components => 4 bytes per pixel
  // RGB 32 bpp, 8 bpc, kCGImageAlphaPremultipliedLast Mac OS X, iO => OK
    CGContextRef cgContext = CGBitmapContextCreate(data, wpot, hpot, 8, 4*wpot, colorSpace, (CGBitmapInfo)kCGImageAlphaPremultipliedLast);
    if (!cgContext) {
        CGColorSpaceRelease(colorSpace);
        free(data);
        return;
    }
  // Set the blend mode to copy.

  // Draw
  CGContextDrawImage(cgContext, CGRectMake(0, 0, wpot, hpot), cgImage);
  // Release
  CGContextRelease(cgContext);
  CGColorSpaceRelease(colorSpace);

  // Generate texture
    MTLTextureDescriptor *desc = [MTLTextureDescriptor
      texture2DDescriptorWithPixelFormat:MTLPixelFormatRGBA8Unorm
      width:wpot height:hpot mipmapped:NO];
    textures[texture] = [mtlDevice newTextureWithDescriptor:desc];
    MTLRegion region = MTLRegionMake2D(0, 0, wpot, hpot);
    [textures[texture] replaceRegion:region mipmapLevel:0
      withBytes:data bytesPerRow:4 * wpot];
    free(data);
}

// Load 5 textures (change is done in setPliage())
- (void)loadTextures {
  [self loadImageFile:@"hulk400x566" ofType:@"jpg"  texture:texfront1];
  [self loadImageFile:@"ville822x679" ofType:@"jpg" texture:texback1];
  wTexFront = 400;
  hTexFront = 566;

  [self loadImageFile:@"demon676x956" ofType:@"jpg"  texture:texfront2];
  [self loadImageFile:@"fee964x1364" ofType:@"jpg" texture:texback2];
  wTexBack = 400;
  hTexBack = 566;

	[self loadImageFile:@"background256x256" ofType:@"jpg" texture:texbackground];
}

// Init with frame
- (id)initWithFrame:(CGRect)frame {
  mtlDevice = MTLCreateSystemDefaultDevice();
  if ((self = [super initWithFrame:frame device:mtlDevice])) {
    self.delegate = self;
    self.colorPixelFormat = MTLPixelFormatBGRA8Unorm;
    self.depthStencilPixelFormat = MTLPixelFormatDepth32Float;
    self.clearColor = MTLClearColorMake(0.5, 0.5, 0.5, 1.0);
    self.paused = YES;
    self.enableSetNeedsDisplay = NO;
    commandQueue = [mtlDevice newCommandQueue];
    [self buildPipelines];
    [self buildDepthStencilState];
    angleX = angleY = angleZ = 0.0f;
    mdx = mdy = mdz = 0.0f;
    texfront = texfront1;
    texback = texback1;
    texturesON = YES;
    [self loadTextures];
    [self setMultipleTouchEnabled:YES];
    linesON = TRUE;
    model = [[Model alloc] init];
    commands = [[Commands alloc] initWithView3D:self];
    NSMutableString *cde = [[NSMutableString alloc] init];
    [cde appendString:@"read cocotte"];
    [commands commandWithNSString:cde];
    [cde release];
  }
  return self;
}
- (void)buildPipelines {
  id<MTLLibrary> library = [mtlDevice newDefaultLibrary];
  MTLRenderPipelineDescriptor *desc = [[MTLRenderPipelineDescriptor alloc] init];
  desc.colorAttachments[0].pixelFormat = MTLPixelFormatBGRA8Unorm;
  desc.depthAttachmentPixelFormat = MTLPixelFormatDepth32Float;
  desc.vertexFunction = [library newFunctionWithName:@"vertexTextured"];
  desc.fragmentFunction = [library newFunctionWithName:@"fragmentTextured"];
  NSError *err = nil;
  pipelineTextured = [mtlDevice newRenderPipelineStateWithDescriptor:desc error:&err];
  if (err) NSLog(@"pipelineTextured error: %@", err);
  desc.vertexFunction = [library newFunctionWithName:@"vertexColored"];
  desc.fragmentFunction = [library newFunctionWithName:@"fragmentColored"];
  pipelineColored = [mtlDevice newRenderPipelineStateWithDescriptor:desc error:&err];
  if (err) NSLog(@"pipelineColored error: %@", err);
    MTLSamplerDescriptor *sd = [[MTLSamplerDescriptor alloc] init];
    sd.minFilter = MTLSamplerMinMagFilterLinear;
    sd.magFilter = MTLSamplerMinMagFilterLinear;
    sd.sAddressMode = MTLSamplerAddressModeRepeat;
    sd.tAddressMode = MTLSamplerAddressModeRepeat;
    samplerRepeat = [mtlDevice newSamplerStateWithDescriptor:sd];
    sd.sAddressMode = MTLSamplerAddressModeClampToEdge;
    sd.tAddressMode = MTLSamplerAddressModeClampToEdge;
    samplerLinear = [mtlDevice newSamplerStateWithDescriptor:sd];
    [sd release];
  [desc release];
  [library release];
}

- (void)buildDepthStencilState {
  MTLDepthStencilDescriptor *desc = [[MTLDepthStencilDescriptor alloc] init];
  desc.depthCompareFunction = MTLCompareFunctionLess;
  desc.depthWriteEnabled = YES;
  depthStencilState = [mtlDevice newDepthStencilStateWithDescriptor:desc];
  [desc release];
}

// Called from ChoiceController
- (void)setPliage:(NSString *)pliage {
  if ([pliage isEqualToString:@"notexture"]){
    // Second call
    if (texturesON == NO) {
      if (linesON == TRUE){
        // No texture No Lines
        linesON = FALSE;
      } else {
        linesON = TRUE;
      }
    }
    texturesON = NO;
  }
  else if ([pliage isEqualToString:@"texture"]){
    if (texfront == texfront1) {
      texfront = texfront2;
      texback = texback2;
    } else {
      texfront = texfront1;
      texback = texback1;
    }
    texturesON = YES;
  }
  else {
    // Read pliage
    NSMutableString *cde = [[NSMutableString alloc] init];
    [cde appendString:@"read "];
    [cde appendString:pliage];

    // Restore view
    angleX = angleY = angleZ = 0.0f;
    mdx = mdy = mdz = 0.0f;

    // Launch
    [commands commandWithNSString:cde];
    [cde release];
  }
  [self setMyNeedsDisplay];
}

// Called from commands
- (void)setMyNeedsDisplay {
  self.paused = NO;
}

- (void)drawInMTKView:(MTKView *)view {
  [self drawModel];
  self.paused = YES;
  if (animated) {
    animated = [commands anim];
    [self setMyNeedsDisplay];
  }
}

- (void)mtkView:(MTKView *)view drawableSizeWillChange:(CGSize)size {
}

// Called by Commands when animation needs a redraw
- (void)animateWithCommands:(Commands *)thecommands {
  self->commands = thecommands;
  self->animated = YES;
  [self setMyNeedsDisplay];
}

// Initialize from model
// Called by onDrawFrame each time the model need to be drawn
- (void)initFromModel {
  nbPts = 0;
  for (OrFace *f in model->faces)
    for (int i = 2; i < [f->points count]; i++)
      nbPts += 3;
  nbPtsLines = 0;
  for (Segment *s in model->segments)
    if (s->select || !texturesON)
      nbPtsLines += 2;
  totalPts = nbPts + nbPtsLines;
  if (totalPts == 0) return;
  if (previousNbPts != totalPts) {
    vertexBuffer  = [mtlDevice newBufferWithLength:totalPts * 3 * sizeof(float) options:MTLResourceStorageModeShared];
    texBufferFront = [mtlDevice newBufferWithLength:nbPts * 2 * sizeof(float) options:MTLResourceStorageModeShared];
    texBufferBack  = [mtlDevice newBufferWithLength:nbPts * 2 * sizeof(float) options:MTLResourceStorageModeShared];
    previousNbPts = totalPts;
  }
  float *vb = (float *)vertexBuffer.contents;
  float *tf = (float *)texBufferFront.contents;
  float *tb = (float *)texBufferBack.contents;
  int ip = 0, it = 0;
    for (OrFace *f in model->faces) {
        NSArray *pts = f->points;
        [f computeFaceNormal];
        Vector3D *n = f->normal;
        OrPoint *c = [pts objectAtIndex:0];
        OrPoint *p = [pts objectAtIndex:1];
        for (int i = 2; i < [pts count]; i++) {
            OrPoint *s = [f->points objectAtIndex:i];
            vb[ip++]=c->x+f->offset*n->x;
            vb[ip++]=c->y+f->offset*n->y;
            vb[ip++]=c->z+f->offset*n->z;
            tf[it]=(200+c->xf)/wTexFront;
            tf[it+1]=(hTexFront-200-c->yf)/hTexFront;
            tb[it]=(200+c->xf)/wTexBack;
            tb[it+1]=(hTexBack-200-c->yf)/hTexBack;
            it+=2;

            vb[ip++]=p->x+f->offset*n->x;
            vb[ip++]=p->y+f->offset*n->y;
            vb[ip++]=p->z+f->offset*n->z;
            tf[it]=(200+p->xf)/wTexFront;
            tf[it+1]=(hTexFront-200-p->yf)/hTexFront;
            tb[it]=(200+p->xf)/wTexBack;
            tb[it+1]=(hTexBack-200-p->yf)/hTexBack;
            it+=2;

            vb[ip++]=s->x+f->offset*n->x;
            vb[ip++]=s->y+f->offset*n->y;
            vb[ip++]=s->z+f->offset*n->z;
            tf[it]=(200+s->xf)/wTexFront;
            tf[it+1]=(hTexFront-200-s->yf)/hTexFront;
            tb[it]=(200+s->xf)/wTexBack;
            tb[it+1]=(hTexBack-200-s->yf)/hTexBack;
            it+=2;

            p = s; // next triangle
        }
    }
    for (Segment *s in model->segments) {
        if (s->select || !texturesON) {
            vb[ip++]=s->p1->x;
            vb[ip++]=s->p1->y;
            vb[ip++]=s->p1->z;
            vb[ip++]=s->p2->x;
            vb[ip++]=s->p2->y;
            vb[ip++]=s->p2->z;
        }
    }
}

// Setup background arrays
- (void)drawBackground:(id<MTLRenderCommandEncoder>)encoder mvp:(simd_float4x4)mvp {
  static const float verts[] = {
    -2000,-2000,-2000,  2000, 2000,-2000, -2000, 2000,-2000,
    -2000,-2000,-2000,  2000,-2000,-2000,  2000, 2000,-2000
  };
  static const float uvs[] = {
    0,0,  10,10,  0,10,
    0,0,  10,0,   10,10
  };
  Uniforms u;
  u.mvp = mvp;
  u.color = simd_make_float4(1,1,1,1);
  u.useTexture = 1;
  [encoder setRenderPipelineState:pipelineTextured];
  [encoder setDepthStencilState:depthStencilState];
  [encoder setCullMode:MTLCullModeNone];
  [encoder setFrontFacingWinding:MTLWindingCounterClockwise];
  [encoder setVertexBytes:verts length:sizeof(verts) atIndex:0];
  [encoder setVertexBytes:uvs length:sizeof(uvs) atIndex:1];
  [encoder setVertexBytes:&u length:sizeof(Uniforms) atIndex:2];
  [encoder setFragmentBytes:&u length:sizeof(Uniforms) atIndex:2];
  [encoder setFragmentTexture:textures[texbackground] atIndex:0];
  [encoder setFragmentSamplerState:samplerRepeat atIndex:0];
  [encoder drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:6];
}

// Main drawing
- (void)drawModel {
  id<MTLCommandBuffer> cmdBuffer = [commandQueue commandBuffer];
  MTLRenderPassDescriptor *rpd = self.currentRenderPassDescriptor;
  if (!rpd) { [cmdBuffer commit]; return; }
  [self initFromModel];
  CGSize sz = self.drawableSize;
  float bw = sz.width, bh = sz.height;
  float ratio = bw / bh, fov = 30.0f, near = 60, far = 12000;
  float top, bottom, left, right;
  if (ratio >= 1.0f) {
    top = near * tanf(fov * M_PI / 360.0f);
    bottom = -top; left = bottom * ratio; right = top * ratio;
  } else {
    right = near * tanf(fov * M_PI / 360.0f);
    left = -right; top = right / ratio; bottom = left / ratio;
  }
  simd_float4x4 proj = matFrustum(left, right, bottom, top, near, far);
  simd_float4x4 view = matTranslate(0, 0, -900);
  simd_float4x4 rotZ  = matRotate(angleZ, 0, 0, 1);
  simd_float4x4 trans = matTranslate(mdx, mdy, mdz);
  simd_float4x4 rotXY = matrix_multiply(matRotate(angleX, 0, 1, 0), matRotate(angleY, 1, 0, 0));
  simd_float4x4 mvpBg    = matrix_multiply(proj, view);
  simd_float4x4 mvpModel = matrix_multiply(matrix_multiply(matrix_multiply(proj, matrix_multiply(view, matrix_multiply(rotZ, trans))), rotXY), matrix_identity_float4x4);
  id<MTLRenderCommandEncoder> enc = [cmdBuffer renderCommandEncoderWithDescriptor:rpd];
  [self drawBackground:enc mvp:mvpBg];
  if (totalPts == 0) {
    [enc endEncoding];
    [cmdBuffer presentDrawable:self.currentDrawable];
    [cmdBuffer commit];
    return;
  }
  Uniforms u;
  u.mvp = mvpModel;
  [enc setDepthStencilState:depthStencilState];
  if (nbPts > 0) {
    if (texturesON) {
      [enc setRenderPipelineState:pipelineTextured];
      [enc setFragmentSamplerState:samplerLinear atIndex:0];
      u.useTexture = 1;
      u.color = simd_make_float4(1,1,1,1);
      [enc setFrontFacingWinding:MTLWindingCounterClockwise];
      [enc setCullMode:MTLCullModeBack];
      [enc setVertexBuffer:vertexBuffer offset:0 atIndex:0];
      [enc setVertexBuffer:texBufferFront offset:0 atIndex:1];
      [enc setVertexBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentTexture:textures[texfront] atIndex:0];
      [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:nbPts];
      [enc setFrontFacingWinding:MTLWindingClockwise];
      [enc setVertexBuffer:texBufferBack offset:0 atIndex:1];
      [enc setVertexBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentTexture:textures[texback] atIndex:0];
      [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:nbPts];
    } else {
      [enc setRenderPipelineState:pipelineColored];
      u.useTexture = 0;
      u.color = simd_make_float4(145.0/255, 199.0/255, 1, 1);
      [enc setFrontFacingWinding:MTLWindingCounterClockwise];
      [enc setCullMode:MTLCullModeBack];
      [enc setVertexBuffer:vertexBuffer offset:0 atIndex:0];
      [enc setVertexBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentBytes:&u length:sizeof(u) atIndex:2];
      [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:nbPts];
      u.color = simd_make_float4(1, 249.0/255, 145.0/255, 1);
      [enc setFrontFacingWinding:MTLWindingClockwise];
      [enc setVertexBytes:&u length:sizeof(u) atIndex:2];
      [enc setFragmentBytes:&u length:sizeof(u) atIndex:2];
      [enc drawPrimitives:MTLPrimitiveTypeTriangle vertexStart:0 vertexCount:nbPts];
    }
  }
  if (linesON && nbPtsLines > 0) {
    [enc setRenderPipelineState:pipelineColored];
    u.useTexture = 0;
    u.color = simd_make_float4(0, 0, 0, 1);
    [enc setCullMode:MTLCullModeNone];
    [enc setVertexBuffer:vertexBuffer offset:0 atIndex:0];
    [enc setVertexBytes:&u length:sizeof(u) atIndex:2];
    [enc setFragmentBytes:&u length:sizeof(u) atIndex:2];
    [enc drawPrimitives:MTLPrimitiveTypeLine vertexStart:nbPts vertexCount:nbPtsLines];
  }
  [enc endEncoding];
  [cmdBuffer presentDrawable:self.currentDrawable];
  [cmdBuffer commit];
}

- (void)layoutSubviews {
  [self drawModel];
  [self setMyNeedsDisplay];
}

- (void)dealloc {
  [model release];
  [commands release];
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
	CGPoint pointA, pointB, prevA, prevB;
  static float lastDownTime, lastUpTime, lastUpUpTime;
  static BOOL wasRunning;

  float currentTime = CACurrentMediaTime();

	if ([touches count] == 1) {
    touchA = [[touches allObjects] objectAtIndex:0];

		pointA = [touchA locationInView:self];
		pointB = [touchA previousLocationInView:self];
    angleX += (pointA.x - pointB.x) * 180.0f / 320;
    angleY += (pointA.y - pointB.y) * 180.0f / 320;

    // One Pointer up
    if ([touchA phase] == UITouchPhaseEnded){
      // Triple tap undo - UpUpTime is set by double tap
      if ((currentTime - lastUpUpTime) < 0.500f){
        [commands commandWithNSString:@"u"];
      }
      // Double tap restore rotation and zoom fit
      else if ((currentTime - lastUpTime) < 0.500f){
        lastUpUpTime = currentTime;
        angleX = angleY = angleZ = 0.0f;
        mdx = mdy = mdz = 0.0f;
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
	}
  // Two fingers Zoom, Translate, Rotates around Z axis
	else if ([touches count] == 2) {
    touchA = [[touches allObjects] objectAtIndex:0];
		touchB = [[touches allObjects] objectAtIndex:1];

		pointA = [touchA locationInView:self];
		pointB = [touchB locationInView:self];

    // First second pointer down
    if ([touchB phase] == UITouchPhaseBegan) {
      lastDownTime = currentTime;
    }
    // Touch and tap, undo, and restore view
    // Second pointer up short after pointer down
    else if ([touchB phase] == UITouchPhaseEnded
             && (currentTime - lastDownTime) < 0.500f){
      [commands commandWithNSString:@"u"];
      lastUpUpTime = currentTime;
      angleX = angleY = angleZ = 0.0f;
      mdx = mdy = mdz = 0.0f;

      [commands commandWithNSString:@"zf"];
    }
    // Zoom rotate with two fingers
    // Not the first second pointer down, not pointer up
    else {
      // Delta distance
      prevA = [touchA previousLocationInView:self];
      prevB = [touchB previousLocationInView:self];
      float vx0 = prevB.x - prevA.x;
      float vy0 = prevB.y - prevA.y;
      float vx1 = pointB.x - pointA.x;
      float vy1 = pointB.y - pointA.y;
      float lastd = (float) sqrt(vx0*vx0 + vy0*vy0);
      float d = (float) sqrt(vx1*vx1 + vy1*vy1);
      float dd = (d - lastd) * 2; // arbitraire
      // Delta Center
      float dx = ((pointB.x + pointA.x)-(prevB.x + prevA.x)) /2;
      float dy = ((pointB.y + pointA.y)-(prevB.y + prevA.y)) /2;
      // Delta angle
      float cz = vx1*vy0-vy1*vx0; // Cross product = v0 v1 sin
      float sp = vx0*vx1+vy0*vy1; // Scalar product = v0 v1 cos
      float v0v1 = (float) (sqrt(vx0*vx0+vy0*vy0) * sqrt(vx1*vx1+vy1*vy1));
      float sin = cz / v0v1;
      float cos = sp / v0v1;
      if (cos > 1.0f )
        cos = 1.0f;
      if (cos < -1.0f )
        cos = -1.0f;
      float angle = (float)(acos(cos) * 180/M_PI);
      if (sin < 0)
        angle = -angle;

      // Set
      angleZ += angle;
      mdx += dx;
      mdy -= dy;
      mdz += dd;
    }
	}

  // Draw result
    [self setMyNeedsDisplay];
}

@end
