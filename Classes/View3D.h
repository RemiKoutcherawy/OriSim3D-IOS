#import <UIKit/UIKit.h>
#import <MetalKit/MetalKit.h>
#import <simd/simd.h>
#import "Model.h"
#import "Commands.h"

enum {
  texfront1, texfront2,
  texback1,  texback2,
  texbackground,
  kNumTextures
};
extern int texfront, texback;

@class Commands;
@class Model;

@interface View3D : MTKView <MTKViewDelegate>
{
  Model *model;
  Commands *commands;
  BOOL animated;
  id<MTLDevice> mtlDevice;
  id<MTLCommandQueue> commandQueue;
  id<MTLRenderPipelineState> pipelineTextured;
  id<MTLRenderPipelineState> pipelineColored;
  id<MTLDepthStencilState> depthStencilState;
  id<MTLTexture> textures[kNumTextures];
  id<MTLBuffer> vertexBuffer;
  id<MTLBuffer> texBufferFront;
  id<MTLBuffer> texBufferBack;
    id<MTLSamplerState> samplerRepeat;
    id<MTLSamplerState> samplerLinear;
  int nbPts, nbPtsLines, previousNbPts, totalPts;
  int wTexFront, hTexFront, wTexBack, hTexBack;
  BOOL texturesON, linesON;
  float angleX, angleY, angleZ, mdx, mdy, mdz;
}

@property(nonatomic, retain) Model *model;
@property(nonatomic, retain) Commands *commands;

- (void)drawModel;
- (void)setMyNeedsDisplay;
- (void)animateWithCommands:(Commands *)thecommands;
- (void)setPliage:(NSString *)pliage;

@end
