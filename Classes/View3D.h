#import <UIKit/UIKit.h>

#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGL.h>
#import <OpenGLES/EAGLDrawable.h>
#import <OpenGLES/ES1/gl.h>
#import <OpenGLES/ES1/glext.h>

#import "Model.h"
#import "Commands.h"

enum
{
	texfront,
	texback,
  texbackground,
  kNumTextures
};

@class Commands;
@class Model;

@interface View3D : UIView
{
  Model *model;
  Commands *commands;
  BOOL animated;
  
  // The pixel dimensions of the backbuffer
  GLint backingWidth;
  GLint backingHeight;
  
  // EAGLontext and EAGLLayer
  EAGLContext *context;
  CAEAGLLayer *eaglLayer;
  
  // OpenGL names for the renderbuffer and framebuffers used to render to this view
  GLuint renderbuffer, framebuffer;
  // OpenGL name for the depth buffer that is attached to viewFramebuffer, if it exists (0 if it does not exist)
  GLuint depthRenderbuffer;
  
  // CADisplayLink is a timer
  CADisplayLink *displayLink;
  
  // Texture dimensions
  int wTexFront, hTexFront, wTexBack, hTexBack;
  BOOL texturesON;

  // 3D settings
	GLfloat scale, rotate, angleX, angleY;
	GLuint textures[kNumTextures];
}

@property(nonatomic,retain) Model *model;
@property(nonatomic,retain) Commands *commands;
@property (nonatomic, retain) EAGLContext *context;


- (void)drawView:(CADisplayLink *)displayLink;
- (void)drawModel;
- (void)setMyNeedsDisplay;
- (void)animateWithCommands:(Commands *)thecommands;
- (id)initWithFrame:(CGRect)frame;
- (void)setPliage:(NSString *)pliage;

- (BOOL)createFramebuffer;
- (void)destroyFramebuffer;

@end
