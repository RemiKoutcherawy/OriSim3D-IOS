// Segment to hold Segments
// Two points p1 p2

#import "OrPoint.h"
#import "Segment.h"
#import "Vector3D.h"

@implementation Segment

// Types of segments
+ (int)PLAIN {      return Segment_PLAIN; }
+ (int)EDGE {       return Segment_EDGE;}
+ (int)MOUNTAIN {   return Segment_MOUNTAIN;}
+ (int)VALLEY {     return Segment_VALLEY;}
+ (int)TEMPORARY {  return Segment_TEMPORARY;}

// Constructs a segment with 2 points
- (id)initWithOrPoint:(OrPoint *)a
          withOrPoint:(OrPoint *)b
                withType:(int)typei
                withId:(int)idi {
  if ((self = [super init])) {
    p1 = a;
    p2 = b; 
    type = typei;
    lg2d = (float) sqrt((p1->xf - p2->xf) * (p1->xf - p2->xf) + (p1->yf - p2->yf) * (p1->yf - p2->yf));
    id_ = idi;
  }
  return self;
}
// Construct a segment with two point given as Vector3D
- (id)initWithVector3D:(Vector3D *)a
          withVector3D:(Vector3D *)b {
  if ((self = [super init])) {
    p1 = [[OrPoint alloc] initWithVector3D:a];
    p2 = [[OrPoint alloc] initWithVector3D:b];
    type = Segment_TEMPORARY;
    id_ = -1;
  }
  return self;
}
// dealloc
- (void) dealloc {
  if (type == Segment_TEMPORARY){
    [p1 dealloc];
    [p2 dealloc];
  }
  [super dealloc];
}

// We compare this segment with passed segment
- (int)compareToWithId:(Segment *)o {
  return [self compareToWithOrPoint:o->p1 withOrPoint:o->p2];
}
// We compare based on id this segment with segment passed as 2 points
- (BOOL)equalsWithOrPoint:(OrPoint *)a
              withOrPoint:(OrPoint *)b {
  return p1->id_ == a->id_
      && p2->id_ == b->id_;
}
// We compare this segment with segment passed as 2 points min distance is 3
- (float)compareToWithOrPoint:(OrPoint *)a
                  withOrPoint:(OrPoint *)b {
  float d1 = [p1 compareToWithId:a];
  float d2 = [p2 compareToWithId:b];
  float d = 0.0f;
  if (fabsf(d1) > 3) d = d1;
  else if (fabsf(d2) > 3) d = d2;
  return d;
}

- (void)reverse {
  OrPoint *p = p1;
  p1 = p2;
  p2 = p;
}

- (float)lg3dCalc {
  self->lg3d = (float) sqrt((p1->x-p2->x)*(p1->x-p2->x) + (p1->y-p2->y)*(p1->y-p2->y) + (p1->z-p2->z)*(p1->z-p2->z));
  return self->lg3d;
}

- (float)lg2dCalc {
  self->lg2d = (float) sqrt((p1->xf-p2->xf)*(p1->xf-p2->xf) + (p1->yf-p2->yf)*(p1->yf-p2->yf));
  return lg2d;
}

- (Segment *)newClosestWithSegment:(Segment *)s {
  float t1, t2;
  Vector3D *v1 = [[Vector3D alloc] initWithX:p2->x-p1->x Y:p2->y-p1->y Z:p2->z-p1->z];
  Vector3D *v2 = [[Vector3D alloc] initWithX:s->p2->x-s->p1->x Y:s->p2->y-s->p1->y Z:s->p2->z-s->p1->z];
  Vector3D *r = [[Vector3D alloc] initWithX:p1->x-s->p1->x Y:p1->y-s->p1->y Z:p1->z-s->p1->z];
  float a = [v1 dotWithVector3D:v1];
  float e = [v2 dotWithVector3D:v2];
  float f = [v2 dotWithVector3D:r];
  if (a <= Segment_EPSILON && e <= Segment_EPSILON) {
    [r dealloc];
    [v1 dealloc];
    [v2 dealloc];
    Segment *seg = [[Segment alloc] initWithOrPoint:p1 withOrPoint:s->p1 withType:Segment_TEMPORARY withId:-1];
    return seg;
  }
  if (a <= Segment_EPSILON) {
    t1 = 0.0f;
    t2 = f / e;
    t2 = t2 < 0 ? 0 : t2 > 1 ? 1 : t2;
  }
  else {
    float c = [v1 dotWithVector3D:r];
    if (e <= Segment_EPSILON) {
      t2 = 0.0f;
      t1 = -c / a;
      t1 = t1 < 0 ? 0 : t1 > 1 ? 1 : t1;
    }
    else {
      float b = [v1 dotWithVector3D:v2];
      float denom = a * e - b * b;
      if (denom != 0.0f) {
        t1 = (b * f - c * e) / denom;
        t1 = t1 < 0 ? 0 : t1 > 1 ? 1 : t1;
      }
      else {
        t1 = 0;
      }
      t2 = (b * t1 + f) / e;
      if (t2 < 0.0f) {
        t2 = 0.0f;
        t1 = -c / a;
        t1 = t1 < 0 ? 0 : t1 > 1 ? 1 : t1;
      }
      else if (t2 > 1.0f) {
        t2 = 1.0f;
        t1 = (b-c) / a;
        t1 = t1 < 0 ? 0 : t1 > 1 ? 1 : t1;
      }
    }
  }
  [r dealloc];
  [v1 dealloc];
  [v2 dealloc];
  
  Vector3D *c1 = [p1 addWithVector3D:[v1 scaleThisWithFloat:t1]];
  Vector3D *c2 = [(s->p1) addWithVector3D:[v2 scaleThisWithFloat:t2]];
  Segment *seg =  [[Segment alloc] initWithVector3D:c1 withVector3D:c2];
  [c1 dealloc];
  [c2 dealloc];
  return seg;
}

- (Segment *)closestLine:(Segment *)s {
  float t1, t2;
  Vector3D *v1 = [[Vector3D alloc] initWithX:p2->x-p1->x Y:p2->y-p1->y Z:p2->z-p1->z];
  Vector3D *v2 = [[Vector3D alloc] initWithX:(s->p2)->x-(s->p1)->x Y:(s->p2)->y-(s->p1)->y Z:(s->p2)->z-(s->p1)->z];
  Vector3D *r = [[Vector3D alloc] initWithX:p1->x-(s->p1)->x Y:p1->y-(s->p1)->y Z:p1->z-(s->p1)->z];
  float a = [v1 dotWithVector3D:v1];
  float e = [v2 dotWithVector3D:v2];
  float f = [v2 dotWithVector3D:r];
  if (a <= Segment_EPSILON && e <= Segment_EPSILON) {
    Segment *seg = [[Segment alloc] initWithOrPoint:p1 withOrPoint:s->p1 withType:Segment_TEMPORARY withId:-1];
    [v1 release];
    [v2 release];
    [r release];
    return seg;
  }
  if (a <= Segment_EPSILON) {
    t1 = 0.0f;
    t2 = f / e;
  }
  else {
    float c = [v1 dotWithVector3D:r];
    if (e <= Segment_EPSILON) {
      t2 = 0.0f;
      t1 = -c / a;
    }
    else {
      float b = [v1 dotWithVector3D:v2];
      float denom = a * e - b * b;
      if (denom != 0.0f) {
        t1 = (b * f - c * e) / denom;
      }
      else {
        t1 = 0;
      }
      t2 = (b * t1 + f) / e;
    }
  }
  Vector3D *c1 = [p1 addWithVector3D:[v1 scaleThisWithFloat:t1]];
  Vector3D *c2 = [(s->p1) addWithVector3D:[v2 scaleThisWithFloat:t2]];
  [v1 release];
  [v2 release];
  [r dealloc];
  Segment *seg = [[Segment alloc] initWithVector3D:c1 withVector3D:c2];
  [c1 release];
  [c2 release];
  return seg;
}
@end
