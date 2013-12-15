// Point to hold Points
// 3D : x y z
// Flat CreasePattern : xf, yf
// View 2D : xv, yv (unused in iPhone)

#import "OrPoint.h"
#import "OrFace.h"

#import "math.h" // Only for MAXFLOAT

@implementation OrPoint

// Construct a point with 2D coordinates, z = 0
- (id)initWithFloat:(float)xi
          withFloat:(float)yi {
  if ((self = [super initWithX:xi Y:yi Z:0])) {
    xf = xi;
    yf = yi;
  }
  return self;
}
// Constructs a point with 3D coordinates
- (id)initWithFloat:(float)xi
          withFloat:(float)yi
          withFloat:(float)zi {
  if ((self = [super initWithX:xi Y:yi Z:zi])) {
    xf = MAXFLOAT;
    yf = MAXFLOAT;
  }
  return self;
}
// Constructs a point with antoher Vector3D
- (id)initWithVector3D:(Vector3D *)v{
  if ((self = [super initWithX:v->x Y:v->y Z:v->z])) {
    xf = x;
    yf = y;
  }
  return self;
}
// Constructs a point with antoher OrPoint
- (id)initWithOrPoint:(OrPoint *)v{
  if ((self = [super initWithX:v->x Y:v->y Z:v->z])) {
    xf = v->xf;
    yf = v->yf;
    id_ =v->id_;
  }
  return self;
}
// dealloc
- (void) dealloc{
  [super dealloc];
}

// We Override to select point from existing points
- (BOOL)isEqual:(id)p {
  return id_ == ((OrPoint *) p)->id_;
}
// Compares this points with arg in 2D
- (int)compareToWithId:(OrPoint *)p {
  return (int) [self compareToWithFloat:p->x withFloat:p->y withFloat:p->z];
}
// Compare this point with x,y in 2D
- (float)compareToWithFloat:(float)xc
                  withFloat:(float)yc {
  float dx2 = fabsf((xf - xc) * (xf - xc));
  float dy2 = fabsf((yf - yc) * (yf - yc));
  float d = sqrtf(dx2 + dy2);
  if (d > 3.0f)
    return d;
  return 0;
}

@end
