// Plane defined by an origin point R and a normal vector N
// a point P is in plane iff RP.N = 0 that is if OP.N = d with d = OR.N

#import "Plane.h"
#import "OrPoint.h"
#import "Segment.h"
#import "Vector3D.h"

@implementation Plane

+ (float)THICKNESS {
  return Plane_THICKNESS;
}
// Construct with a normal and a distance
- (id)init {
  if ((self = [super init])) {
    n = [[Vector3D alloc] initWithX:0 Y:0 Z:0];
    d = 0;
  }
  return self;
}
// dealloc
- (void)dealloc
{
  [n dealloc];
  [super dealloc];
}

// Define a plane across 2 points
- (Plane *)acrossWithOrPoint:(OrPoint *)p1
                     withOrPoint:(OrPoint *)p2 {
  Vector3D *o = [[Vector3D alloc] initWithX:(p1->x + p2->x) / 2 Y:(p1->y + p2->y) / 2 Z:(p1->z + p2->z) / 2];
  [n setWithX:p2->x-p1->x Y:p2->y-p1->y Z:p2->z-p1->z];
  d = [o dotWithVector3D:n];
  [o dealloc];
  return self;
}
// Define a plane by 2 points along Z
- (Plane *)byWithOrPoint:(OrPoint *)p1
                 withOrPoint:(OrPoint *)p2 {
  Vector3D *o = [[Vector3D alloc] initWithX:p1->x Y:p1->y Z:p1->z];
  [n setWithX:-(p2->y-p1->y) Y:(p2->x-p1->x) Z:0];
  d = [o dotWithVector3D:n];
  [o dealloc];
  return self;
}
// Plane orthogonal to Segment and passing by Point
- (Plane *)orthoWithSegment:(Segment *)s
                      withOrPoint:(OrPoint *)p {
  [n setWithX:s->p2->x-s->p1->x Y:s->p2->y-s->p1->y Z:s->p2->z-s->p1->z];
  d = [p dotWithVector3D:n];
  return self;
}
// Intersection of This plane with Segment
- (Vector3D *)newIntersectWithSegment:(Segment *)s {
  Vector3D *ab = [[Vector3D alloc] initWithX:s->p2->x - s->p1->x Y:s->p2->y - s->p1->y Z:s->p2->z - s->p1->z];
  float abn = [ab dotWithVector3D:n];
  if (abn == 0){
    [ab dealloc];
    return nil;
  }
  float t = (d - [s->p1 dotWithVector3D:n]) / abn;
  if (t >= 0 && t <= 1.0){
    [[ab scaleThisWithFloat:t] addToThisWithVector3D:s->p1];
    return ab;
  }
  [ab dealloc];
  return nil;
}
// Intersection of This plane with segment defined by two points
- (Vector3D *)intersectWithOrPoint:(OrPoint *)a
                           withOrPoint:(OrPoint *)b {
  // (A+tAB).N=d <=> t=(d-A.N)/(AB.N) then Q=A+tAB 0<t<1
  Vector3D *ab = [[Vector3D alloc] initWithX:b->x-a->x Y:b->y-a->y Z:b->z-a->z];
  float abn = [ab dotWithVector3D:n] ;
  // segment parallel to plane
  if (abn == 0){
    [ab dealloc];
    return nil;
  }
  // segment crossing
  float t = (d - [a dotWithVector3D:n]) / abn;
  if (t >= 0 && t <= 1.0){
    [[ab scaleThisWithFloat:t] addToThisWithVector3D:a];
    return ab;
  }
  [ab dealloc];
  return nil;
}
// Classify point to thick plane 1 in front 0 on -1 behind
- (int)classifyPointToPlaneWithVector3D:(Vector3D *)i {
  float dist = d - [Vector3D dotWithVector3D:n withVector3D:i];
  if (dist > Plane_THICKNESS) return 1;
  if (dist < -Plane_THICKNESS) return -1;
  return 0;
}
// Return Pl normal:n distance:d 
- (NSString *)description {
  return [NSString stringWithFormat:@"Pl n:%@ d:%f", n, d];
}

@end
