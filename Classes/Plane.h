// Plane defined by an origin point R and a normal vector N
// a point P is in plane iff RP.N = 0 that is if OP.N = d with d = OR.N

@class OrPoint;
@class Segment;
@class Vector3D;

#define Plane_THICKNESS 10.0

@interface Plane : NSObject {
@public
  Vector3D *n;
  float d;
}

+ (float)THICKNESS;
- (Plane *)acrossWithOrPoint:(OrPoint *)p1 withOrPoint:(OrPoint *)p2;
- (Plane *)byWithOrPoint:(OrPoint *)p1 withOrPoint:(OrPoint *)p2;
- (Plane *)orthoWithSegment:(Segment *)s withOrPoint:(OrPoint *)p;
- (Vector3D *)newIntersectWithSegment:(Segment *)s;
- (Vector3D *)intersectWithOrPoint:(OrPoint *)a withOrPoint:(OrPoint *)b;
- (int)classifyPointToPlaneWithVector3D:(Vector3D *)i;
- (NSString *)description;
- (id)init;
@end
