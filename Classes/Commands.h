// Commands interpretor

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
}

@property (nonatomic, strong) View3D *view3d;
@property (nonatomic, strong) id<Interpolator> interpolator;

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