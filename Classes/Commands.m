// Commands are interpreted here
// this class deals with animation, undo, pause with a state machine

#import "Commands.h"
#import "Model.h"
#import "OrFace.h"
#import "Segment.h"
#import "OrPoint.h"
#import "Interpolator.h"
#import "View3D.h"

@implementation Commands

@synthesize view3d;
@synthesize interpolator;

// Constructor initializes array lists and keep a reference to View3D to send redraw
- (id)initWithView3D:(View3D *)panel {
  if ((self = [super init])) {
    self->state = idle;
    undoInProgress = NO;
    pauseDuration = 0;
    tni = 1.0f;
    tpi = 0.0f;
    za = (float*) malloc(4 * sizeof(float));
    [Interpolator choose:LinearInterpolator];
    kOffset = 0.2f;
    view3d = panel;
    undo = [[NSMutableArray alloc] init];
    done = [[NSMutableArray alloc] init];
    todo = [[NSMutableArray alloc] init];
  }
  return self;
}
// dealloc
- (void) dealloc {
  [undo dealloc];
  [done dealloc];
  [todo dealloc];
  free(za);
  [super dealloc];
}

// Main entry point on state machine
- (void)commandWithNSString:(NSString *)cde {
   @synchronized(self) { // @synchronized(self)
    {
      // read stop everything
      if ([cde hasPrefix:@"read"]) {
        self->state = idle;
        // no return => continue with execute on idle state
      }
// -- State Idle tokenize list of command
      if (self->state == idle) {
        // undo 
        if ([cde isEqualToString:@"u"]) {
          NSEnumerator *enumerator = [done reverseObjectEnumerator];
          for (NSString *element in enumerator) {
            [todo addObject:element];
          }
          [self undoCde]; // We are exploring todo[]
          return;
        }
        // read 
        else if ([cde hasPrefix:@"read"]) {
          NSString *filename = [cde substringFromIndex:5]; // "read "+"filename"
          cde = [self initReadWithNSString:filename]; // appends ".txt" read all in cde
          [done removeAllObjects];
          [undo removeAllObjects];
          // no return => continue with execute
          // the "d" command will remove all from model
        }
        // pause or continue
        else if ([cde isEqualToString:@"co"] || [cde isEqualToString:@"pa"]) {
          // In idle, no job, continue, or pause are irrelevant
          return;
        }
        // Clean and tokenize cde
        [todo removeAllObjects];
        NSArray *tokens = [self tokenizeNSString:cde];
        [todo addObjectsFromArray:tokens];
        [tokens release];
        // Execute
        self->state = running;
        iTok = 0;
        [self commandLoop];
        return;
      }
// -- State Run execute list of command
      if (self->state == running) {
        [self commandLoop];
        return;
      }
// -- State Animation execute up to ')' or pause
      if (self->state == anim) {
        // "Pause"
        if ([cde isEqualToString:@"pa"]) {
          self->state = paused;
          return;
        }
      }
// -- State Paused in animation
      if (self->state == paused) {
         // "Continue"
        if ([cde isEqualToString:@"co"]) {
          // Continue animation
          // Note the duration of the pause
          pauseDuration = CACurrentMediaTime() - pauseStart;
          [view3d animateWithCommands:self];
          self->state = anim;
        }
        else if ([cde isEqualToString:@"u"]) {
          // Undo one step
          self->state = undoing;
          [self undoCde];
        }
        return;
      }
// -- State undo
      if (self->state == undoing) {
        if (undoInProgress == NO) {
          if ([cde isEqualToString:@"u"]) {
            // Ok continue to undo
            [self undoCde];
          }
          else if ([cde isEqualToString:@"co"]) {
            // Switch back to run
            self->state = running;
            [self commandLoop];
          }
          else if ([cde isEqualToString:@"pa"]) {
            // Forbidden ignore pause
          }
        }
        return;
      }
    }
  }
}

// Loop to execute commands
- (void)commandLoop {
  while (iTok < (int) [todo count]) {
    // Breaks loop to launch animation on 't'
    if ([[todo objectAtIndex:iTok] isEqualToString:@"t"]) {
      // Mark
      [self pushUndo];
      // Time t duration ... )
      [done addObject:[todo objectAtIndex:iTok++]];
      // iTok will be incremented by duration = get()
      [done addObject:[todo objectAtIndex:iTok]];
      duration = [self get];
      pauseDuration = 0;
      self->state = anim;
      [self animStart];
      // Return breaks the loop, giving control to anim
      return;
    }
    // Finish pushing command 
    else if ([[todo objectAtIndex:iTok] isEqualToString:@")"]) {
      [done addObject:[todo objectAtIndex:iTok++]];
      continue;
    }
    int iBefore = iTok;
    // Execute one command
    int iReached = [self execute];
    // Push modified model
    [self pushUndo];
    // Add done commands to done list
    while (iBefore < iReached) {
      [done addObject:[todo objectAtIndex:iBefore++]];
    }
    // Post an event to repaint
    // The repaint will not occur till next animation, or end Cde
    [view3d setMyNeedsDisplay];
  }
  if (self->state == running) {
    self->state = idle;
  }
}
// Sets a flag in View3D to call anim() at each redraw
- (void) animStart {
  // Call View3D.animate() witch sets a flag animated=yes and calls repaint()
  // The flag animated=yes if tested after each draw() and if true call anim()
  tstart = CACurrentMediaTime();
  [view3d animateWithCommands:self];
  // time preceeding index: tpi
  tpi = 0.0f;
}
// Called from View3D at each redraw
//  return true if anim should continue false if anim should end
- (BOOL) anim {
  if (self->state == undoing) {
    int index = [self popUndo];
    BOOL ret = (index > iTok) ? YES : NO;
    // Stop undo if undo mark reached and switch to repaint
    if (ret == NO) {
      undoInProgress = NO;
      [view3d setMyNeedsDisplay];
    }
    return ret;
  }
  else if (self->state == paused) {
    pauseStart = CACurrentMediaTime();
    return NO;
  }
  else if (self->state != anim) {
    return NO;
  }
  // We are in anim, just continue to animate
  float t = CACurrentMediaTime();
  // Compute tn varying from 0 to 1
  // The duration read in file is given in milliseconds, and time is in seconds
  float tn = (t - tstart - pauseDuration) / (duration / 1000);
  if (tn > 1.0f)
    tn = 1.0f;
  tni = [Interpolator interpolate:tn];

  // Execute commands just after t xxx up to including ')'
  iBeginAnim = iTok;
  while (![[todo objectAtIndex:iTok] isEqualToString:@")"]) {
    [self execute];
  }
  // For undoing animation
  // We are only interested in model, not in command
  [self pushUndo];
  // Keep t preceding tn
  tpi = tni;
  // If Animation will finish, set end values
  if (tn >= 1.0f) { // tn
    tni = 1.0f;
    tpi = 0.0f;
    // Push done
    while (iBeginAnim < iTok) {
      // Time t duration ... )
      [done addObject:[todo objectAtIndex:iBeginAnim++]];
    }
    // Switch back to run and launch next cde
    self->state = running;
    [self commandLoop];
    // If commandLoop has launched another animation we continue
    if (self->state == anim)
      return YES;
    // OK we stop anim
    return NO;
  }
  // Rewind to continue animation
  iTok = iBeginAnim;
  return YES;
}
// Undo
- (void)undoCde {
  if ([undo count] == 0) {
    return;
  }
  // We should be Only in states : idle pause undo
  // Rewind to last 't' or 'd' command from done
  if (self->state == idle) {
    iTok = (int) [todo count] - 1;
  }
  while (iTok >= 0) {
    iTok--;
    [done removeLastObject];
    NSString *tok = [todo objectAtIndex:iTok];
    // Undo Mark, t or beginning Define
    if ([tok isEqualToString:@"d"] || [tok isEqualToString:@"t"])
      break;
  }
  // We have rewound to 't' or 'd', launch the sequence to undo to iTok
  tni = 1.0f;
  tpi = 0.0f;
  self->state = undoing;
  undoInProgress = YES;
  // Launch animation to popUndo until iTok reached
  [view3d animateWithCommands:self];
  return;
}

// Push undo
- (void)pushUndo {
//  [undo addObject:[((Model *) mainPane.model) getSerialized]];
//  [undo addObject:[self getSerializedWithInt:[done size]]];
}

// Serial encoder for index in todo string.
// Returns byte[] array with one Integer for the int parameter
- (NSData *)initGetSerializedWithInt:(int)i {
  NSData *bs = [[NSData alloc] init];
//  JavaIoObjectOutputStream *oos;
//  @try {
//    oos = [[JavaIoObjectOutputStream alloc] initWithJavaIoOutputStream:bs];
//    [((JavaIoObjectOutputStream *) oos) writeObjectWithId:[JavaLangInteger valueOfWithInt:i]];
//    [((JavaIoObjectOutputStream *) oos) close];
//  }
//  @catch (JavaIoIOException *e) {
//    [((JavaIoIOException *) e) printStackTrace];
//  }
  return bs;
}
// Serial decoder for index
// Returns int from the byte[] array  parameter
- (int)deserializeWithNSData:(NSData *)buf {
//  JavaLangInteger *ret = [JavaLangInteger valueOfWithInt:0];
//  JavaIoByteArrayInputStream *bais = [[JavaIoByteArrayInputStream alloc] initWithJavaLangByteArray:buf];
//  JavaIoObjectInputStream *dec;
//  @try {
//    dec = [[JavaIoObjectInputStream alloc] initWithJavaIoInputStream:bais];
//    ret = (JavaLangInteger *) [((JavaIoObjectInputStream *) dec) readObject];
//    [((JavaIoObjectInputStream *) dec) close];
//  }
//  @catch (JavaLangException *e) {
//    [((JavaLangException *) e) printStackTrace];
//  }
  return 0;
}
// Pop undo index, model and return index
- (int)popUndo {
  // removeLastObject returns void lastObject
  NSData *index = [undo lastObject];
  [undo removeLastObject];
//  IOSByteArray *model = ((IOSByteArray *) [undo poll]);
  if (index == nil) return 0;
//  JavaIoByteArrayInputStream *bais = [[JavaIoByteArrayInputStream alloc] initWithJavaLangByteArray:model];
//  JavaIoObjectInputStream *dec;
//  @try {
//    dec = [[JavaIoObjectInputStream alloc] initWithJavaIoInputStream:bais];
//    ((AndroidModelView *) mainPane).model = (Model *) [((JavaIoObjectInputStream *) dec) readObject];
//    [((JavaIoObjectInputStream *) dec) close];
//  }
//  @catch (JavaLangException *e) {
//    [((JavaLangException *) e) printStackTrace];
//  }
  return [self deserializeWithNSData:index];
}

// Execute one command token on model
- (int)execute {
  // Work on View3D model (beware do not confuse with model already defined in UIView)
  Model *model= [view3d model];
  // Commands
//  NSLog(@"cde:%@ at iTok:%d", [todo objectAtIndex:iTok], iTok);

  if ([[todo objectAtIndex:iTok] isEqualToString:@"d"]) {
    // Define sheet by 4 points x,y CCW
    iTok++;
    [model reinit];
    [model initWithFloat:[self get] withFloat:[self get] withFloat:[self get] withFloat:[self get]
               withFloat:[self get] withFloat:[self get] withFloat:[self get] withFloat:[self get]];
  }
  // Origami splits
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"b"]) {
    // Split by two points all (or listed) faces
    iTok++;
    OrPoint *a = [model->points objectAtIndex:(int) [self get]];
    OrPoint *b = [model->points objectAtIndex:(int) [self get]];
    NSArray *list = [self listFacesWithModel:model];
    [model splitByWithOrPoint:a withOrPoint:b withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"c"]) {
    // Split across two points all (or just listed) faces
    iTok++;
    OrPoint *a = [model->points objectAtIndex:(int) [self get]];
    OrPoint *b = [model->points objectAtIndex:(int) [self get]];
    NSArray *list = [self listFacesWithModel:model];
    [model splitAcrossWithOrPoint:a withOrPoint:b withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"p"]) {
    // Split perpendicular of line by point all (or listed) faces
    iTok++;
    Segment *s = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    OrPoint *p1 = [model->points objectAtIndex:(int) [self get]];
    NSArray *list = [self listFacesWithModel:model];
    [model splitOrthoWithSegment:s withOrPoint:p1 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"lol"]) {
    // Split by a plane passing between segments (line on line) all (or listed) faces
    iTok++;
    Segment *s0 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    Segment *s1 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    NSArray *list = [self listFacesWithModel:model];
    [model splitLineToLineWithSegment:s0 withSegment:s1 withList:list];
    [list dealloc];
  }
  
  // Segments splits
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"s"]) {
    // Split segment by N/D
    iTok++;
    Segment *s = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    float n = [self get];
    float d = [self get];
    [model splitSegmentWithSegment:s withFloat:n / d];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"sc"]) {
    // Split segment where they cross
    iTok++;
    Segment *s1 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    Segment *s2 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    [model splitSegmentCrossingWithSegment:s1 withSegment:s2];
  }
  
  // Animation commands use tni tpi
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"r"]) {
    // Rotate Seg Angle Points with animation
    iTok++;
    Segment *s = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    float angle = (float) ([self get] * (tni - tpi));
    NSArray *list = [self listPointsWithModel:model];
    [model rotateWithSegment:s withFloat:angle withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"f"]) {
    // "f : fold to angle"
    iTok++;
    Segment *s = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    // Cache current angle at start of animation
    // TODO accept multiple folds, multiples angles in one animation
    if (tpi == 0)
      angleBefore = [model computeAngleWithSegment:s];
    float angle = (float) (([self get] - angleBefore) * (tni - tpi));
    NSArray *list = [self listPointsWithModel:model];
    if (tpi == 0 && [model faceRightWithOrPoint:s->p1 withOrPoint:s->p2] != nil
        && [[model faceRightWithOrPoint:s->p1 withOrPoint:s->p2]->points containsObject:[list objectAtIndex:0]])
      [s reverse];
    [model rotateWithSegment:s withFloat:angle withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"a"]) {
    iTok++;
    NSArray *list = [self listPointsWithModel:model];
    [model adjustwithList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"as"]) {
    iTok++;
    OrPoint *p0 = [model->points objectAtIndex:(int) [self get]];
    NSArray *list = [self listSegmentsWithModel:model];
    [model adjustSegmentsWithOrPoint:p0 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"flat"]) {
    iTok++;
    NSArray *list = [self listPointsWithModel:model];
    [model flatWithList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"o"]) {
    iTok++;
    float dz = [self get] * kOffset;
    NSArray *list = [self listFacesWithModel:model];
    [model offsetWithFloat:dz withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"od"]) {
    iTok++;
    float dz = [self get] * kOffset;
    NSArray *list = [self listFacesWithModel:model];
    [model offsetDecalWithFloat:dz withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"oa"]) {
    iTok++;
    float dz = [self get] * kOffset;
    NSArray *list = [self listFacesWithModel:model];
    [model offsetAddWithFloat:dz withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"om"]) {
    iTok++;
    float k = [self get];
    NSArray *list = [self listFacesWithModel:model];
    [model offsetMulWithFloat:k withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"ob"]) {
    iTok++;
    NSArray *list = [self listFacesWithModel:model];
    [model offsetBetweenwithList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"m"]) {
    iTok++;
    float dx =[self get], dy = [self get], dz = [self get];
    NSArray *list = [self listPointsWithModel:model];
    [model moveBydx:dx*(tni-tpi) dy:dy*(tni-tpi) dz:dz*(tni-tpi) withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"mo"]) {
    iTok++;
    OrPoint *p0 = [model->points objectAtIndex:(int) [self get]];
    float k2 = (float) ((1 - tni) / (1 - tpi));
    float k1 = (float) (tni - tpi * k2);
    NSArray *list = [self listPointsWithModel:model];
    [model moveOnWithOrPoint:p0 withFloat:k1 withFloat:k2 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"mol"]) {
    iTok++;
    Segment *p0 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    float k2 = (float) ((1 - tni) / (1 - tpi));
    float k1 = (float) (tni - tpi * k2);
    NSArray *list = [self listPointsWithModel:model];
    [model moveOnLineWithSegment:p0 withFloat:k1 withFloat:k2 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"stp"]) {
    iTok++;
    OrPoint *p0 = [model->points objectAtIndex:(int) [self get]];
    NSArray *list = [self listPointsWithModel:model];
    [model moveOnWithOrPoint:p0 withFloat:1 withFloat:0 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"stl"]) {
    iTok++;
    Segment *p0 = ((Segment *) [model->segments objectAtIndex:(int) [self get]]);
    NSArray *list = [self listPointsWithModel:model];
    [model moveOnLineWithSegment:p0 withFloat:1 withFloat:0 withList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"tx"]) {
    iTok++;
    [model turnWithFloat:[self get] * (tni - tpi) withInt:1];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"ty"]) {
    iTok++;
    [model turnWithFloat:[self get] * (tni - tpi) withInt:2];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"tz"]) {
    iTok++;
    [model turnWithFloat:[self get] * (tni - tpi) withInt:3];
  }
  // Zooms
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"z"]) {
    iTok++;
    // for animation
    float scale = [self get], x = [self get], y = [self get];
    float ascale = (float) ((1 + tni * (scale - 1)) / (1 + tpi * (scale - 1)));
    float bfactor = (float) (scale * (tni / ascale - tpi));
    [model moveBydx:x * bfactor dy:y * bfactor dz:0 withList:nil];
    [model scaleModelWithFloat:ascale];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"zf"]) {
    // "zf : Zoom Fit"
    iTok++;
    if (tpi == 0) {
      float *b = [model get3DBounds];
      float w = 400.0f;
      za[0] = w / (b[2]-b[0]); // ? MAX(b[2]-b[0], b[3]-b[1]);
      za[1] = -(b[0]+b[2])/2;
      za[2] = -(b[1]+b[3])/2;
      free(b);
    }
    float scale = (1.0f+tni*(za[0]-1.0f)) / (1.0f+tpi*(za[0]-1.0f));
    float bfactor = za[0] * (tni/scale - tpi);
    [model moveBydx:za[1] * bfactor dy:za[2] * bfactor dz:0 withList:nil];
    [model scaleModelWithFloat:scale];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"il"]) {
    iTok++;
    [Interpolator choose:LinearInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"ib"]) {
    iTok++;
    [Interpolator choose:BounceInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"io"]) {
    iTok++;
    [Interpolator choose:OvershootInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"ia"]) {
    iTok++;
    [Interpolator choose:AnticipateInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"iao"]) {
    iTok++;
    [Interpolator choose:AnticipateOvershootInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"iad"]) {
    iTok++;
    [Interpolator choose:AccelerateDecelerateInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"iso"]) {
    iTok++;
    [Interpolator choose:SpringOvershootInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"isb"]) {
    iTok++;
    [Interpolator choose:SpringBounceInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"igb"]) {
    iTok++;
    [Interpolator choose:GravityBounceInterpolator];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"pt"]) {
    iTok++;
    NSArray *list = [self listPointsWithModel:model];
    [model selectPtsWithList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"seg"]) {
    iTok++;
    NSArray *list = [self listSegmentsWithModel:model];
    [model selectSegsWithList:list];
    [list dealloc];
  }
  else if ([[todo objectAtIndex:iTok] isEqualToString:@"t"] || [[todo objectAtIndex:iTok] isEqualToString:@")"] || [[todo objectAtIndex:iTok] isEqualToString:@"u"] || [[todo objectAtIndex:iTok] isEqualToString:@"co"] || [[todo objectAtIndex:iTok] isEqualToString:@"end"]) {
    iTok++;
    return -1;
  }
  else {
    iTok++;
  }
  return iTok;
}

- (NSArray *)listPointsWithModel:(Model *)model {
  NSMutableArray *list = [[NSMutableArray alloc] init];
  while (!isnan([self get])) @try {
    [list addObject:[model->points objectAtIndex:p]];
  }
  @catch (NSException *e) {
    NSLog(@"%@", [NSString stringWithFormat:@"Ignore Point:%d", p]);
  }
  return list;
}

- (NSArray *)listSegmentsWithModel:(Model *)model {
  NSMutableArray *list = [[NSMutableArray alloc] init];
  while (!isnan([self get])) @try {
    [list addObject:[model->segments objectAtIndex:p]];
  }
  @catch (NSException *e) {
    NSLog(@"%@", [NSString stringWithFormat:@"Ignore Segment:%d", p]);
  }
  return list;
}

- (NSMutableArray *)listFacesWithModel:(Model *)model {
  NSMutableArray *list = [[NSMutableArray alloc] init];
  while (!isnan([self get])) @try {
    [list addObject:[model->faces objectAtIndex:p]];
  }
  @catch (NSException *e) {
    NSLog(@"Ignore Face:%d", p);
  }
  return list;
}
// Tokenize, split the String in Array of String
- (NSMutableArray *)tokenizeNSString:(NSString *)input {
  // Array of token
  NSMutableArray *matchList = [[NSMutableArray alloc] init];
  // One Token
  NSMutableString *sb = [[NSMutableString alloc] init];
  BOOL lineComment = NO;
  for (int i = 0; i < [input length]; i++) {
    unichar c = [input characterAtIndex:i];
    if (c == ' ' || c == 0x000d || c == 0x000a) {
      // keep token before space or end of line
      if ([sb length] != 0)
        [matchList addObject:[NSString stringWithString:sb]];
      if ([sb isEqualToString:@"end"])
        break;
      // done with this token if any, rewind buffer
      [sb deleteCharactersInRange:NSMakeRange(0, sb.length)];
      lineComment = NO;
    }
    else if (c == ')') {
      // keep string before parent
      if ([sb length] != 0)
        [matchList addObject:[NSString stringWithString:sb]];
      // add parent
      [matchList addObject:@")"];
      // done with this two token
      [sb deleteCharactersInRange:NSMakeRange(0, sb.length)];
    }
    else if (c == '/') {
      // Skip to the end of line
      for (; [input characterAtIndex:i] != 0x000a && i < [input length] - 1; i++) ;
      lineComment = YES;
    }
    else {
      // keep character to form the token
      [sb appendFormat:@"%c",c];
    }
  }
  unichar c = [input characterAtIndex:[input length] - 1];
  if (c != ' ' && c != 0x000d && c != 0x000a && c != ')' && !lineComment) {
    [matchList addObject:[NSString stringWithString:sb]];
  }
  [sb release];
  return matchList;
}
// Helper to get token.
// Returns float and set p as int or return NAN
- (float) get {
  float val;
  if ([todo count] == iTok)
       return NAN;
  NSScanner *theScanner = [NSScanner scannerWithString:[todo objectAtIndex:iTok]];
  if ([theScanner isAtEnd] == NO && [theScanner scanFloat:&val]){
    iTok++;
    p = (int) val;
    return val;
  }
  return NAN;
}
// Read a File (.txt UTF8) in a String
- (NSString *)initReadWithNSString:(NSString *)name {
  NSString *path = [[NSBundle mainBundle] pathForResource:name ofType:@"txt"];
  NSError *error = nil;
	NSString *txt = [[NSString alloc] initWithContentsOfFile:path encoding:NSUTF8StringEncoding error:&error];
  return txt;
}
@end
