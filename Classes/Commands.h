//
//  source: src/rk/or/Commands.java
//
//  Created by remi on 10/05/13.
//
#import "View3D.h"

@class NSArray;
@class View3D;
@class Model;
@protocol Interpolator;

// States
typedef enum State  { // : NSInteger
  idle = 0,
  running = 1,
  anim = 2,
  paused = 3,
  undoing = 4
} state;

@interface Commands : NSObject {
 @public
  View3D *view3d;
  enum State state;
 @private
  NSMutableArray *undo;
  NSMutableArray *done;
  BOOL undoInProgress;
  NSMutableArray *todo;
  int iTok, p, iBeginAnim;
  float tstart, duration, pauseStart, pauseDuration;
  float tni, tpi;
  float *za;
  id<Interpolator> interpolator;
  float angleBefore;
  float kOffset;
//@public
//  // States
//  enum State  { // : NSInteger
//    idle = 0,
//    running = 1,
//    anim = 2,
//    paused = 3,
//    undoing = 4
//  } state;
}

@property (nonatomic, strong) View3D *view3d;
//@property (nonatomic, strong) NSMutableArray *undo;
//@property (nonatomic, strong) NSMutableArray *done;
//@property (nonatomic, assign) BOOL undoInProgress;
//@property (nonatomic, strong) NSMutableArray *todo;
//@property (nonatomic, assign) int iTok;
//@property (nonatomic, assign) int p;
//@property (nonatomic, assign) int iBeginAnim;
//@property (nonatomic, assign) float tni;
//@property (nonatomic, assign) float tpi;
//@property (nonatomic, assign) float *za;
@property (nonatomic, strong) id<Interpolator> interpolator;
//@property (nonatomic, assign) float angleBefore;
//@property (nonatomic, assign) float kOffset;

- (id)initWithView3D:(View3D *)panel;
- (void)commandWithNSString:(NSString *)cde;
- (void)commandLoop;
- (void)animStart;
- (BOOL)anim;
- (void)undoCde;
- (void)pushUndo;
- (NSData *)initGetSerializedWithInt:(int)i;
- (int)deserializeWithNSData:(NSData *)buf;
- (int)popUndo;
- (int)execute;
- listPointsWithModel:(Model *)model;
- listSegmentsWithModel:(Model *)model;
- listFacesWithModel:(Model *)model;
- (NSMutableArray *)tokenizeNSString:(NSString *)input;
- (float)get;
- (NSString *)initReadWithNSString:(NSString *)name;
@end