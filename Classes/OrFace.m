// Face to hold points, segments, normal,
// struts and triangles making the face.

#import "OrFace.h"
#import "Vector3D.h"
#import "OrPoint.h"
#import "Segment.h"
#define Face_EPSILON 0.01

@implementation OrFace

// A new face, no point, no segments
- (id) init {
  if ((self = [super init])) {
    normal = [[Vector3D alloc] initWithX:0 Y:0 Z:1];
    points = [[NSMutableArray alloc] init];
  }
  return self;
}
// dealloc
- (void) dealloc {
  [normal release];
  [points release];
  [super dealloc];
}
// We Override to select face from existing faces
- (BOOL) isEqual:(id)obj {
  return id_ == ((OrFace *) obj)->id_;
}
// Compute Face normal
- (Vector3D *) computeFaceNormal {
  if ([points count] < 3) {
    NSLog(@"%@", [NSString stringWithFormat:@"Pb Face<3pts:%@", self]);
    normal->x = 0;
    normal->y = 0;
    normal->z = 1;
  }
  for (int i = 0; i < [points count] - 2; i++) {
    OrPoint *p1 = [points objectAtIndex:i];
    OrPoint *p2 = [points objectAtIndex:i + 1];
    OrPoint *p3 = [points objectAtIndex:i + 2];
    float ux = p2->x-p1->x, uy = p2->y-p1->y, uz = p2->z-p1->z;
    float vx = p3->x-p1->x, vy = p3->y-p1->y, vz = p3->z-p1->z;
    normal->x = uy*vz - uz*vy;
    normal->y = uz*vx - ux*vz;
    normal->z = ux*vy - uy*vx;
    if (fabs(normal->x) + fabs(normal->y) + fabs(normal->z) > Face_EPSILON) {
      break;
    }
  }
  [OrFace normalizeWithVector3D:normal];
  return normal;
}
// Plane containing p1 p2 p3
// @return N = p2p1 x p1p3 : n = -N.p1
+ (Plane *) planeWithVector3D: (Vector3D *) p1
                        withVector3D:(Vector3D *)p2
                        withVector3D:(Vector3D *)p3 {
  Plane *r = [[Plane alloc] init];
  [r->n setWithX:0 Y:0 Z:0];
  float ux = p2->x-p1->x, uy = p2->y-p1->y, uz = p2->z-p1->z;
  float vx = p3->x-p1->x, vy = p3->y-p1->y, vz = p3->z-p1->z;
  r->n->x = uy * vz - uz * vy;
  r->n->y = uz * vx - ux * vz;
  r->n->z = ux * vy - uy * vx;
  r->d = -(r->n->x * p1->x + r->n->y * p1->y + r->n->z * p1->z);
  return r;
}
// Normalizes a vector
// v[3] = v[3]/||v[3]||
+ (void) normalizeWithVector3D: (Vector3D *)v {
  float d = sqrt(v->x * v->x + v->y * v->y + v->z * v->z);
  v->x = v->x / d;
  v->y = v->y / d;
  v->z = v->z / d;
}
// Compute Face center in 2D crease pattern
- (Vector3D *) newCenter2d {
  Vector3D *center = [[Vector3D alloc] init];
  for (OrPoint *p in points) {
    center->x = center->x + p->xf;
    center->y = center->y + p->yf;
  }
  center->x = center->x / [points count];
  center->y = center->y / [points count];
  return center;
}
// Compute Face center X coord in 3D view
- (int) center3Dx {
  int center = 0;
  for (OrPoint *p in points) {
    center += p->xv;
  }
  center /= [points count];
  return center;
}
// Compute Face center Y coord in 3D view
- (int)center3Dy {
  int center = 0;
  for (OrPoint *p in points) {
      center += p->yv;
  }
  center /= [points count];
  return center;
}
// Tests if the polygon is CCW
// @return > 0 if CCW
+ (float)isCCW:(NSArray *)poly2d {
  int n = (int) [poly2d count] / 2;
  // Take lowest
  float ymin = ((Vector3D *)[poly2d objectAtIndex:1])->y;
  int iymin = 0;
  for (int i = 0; i < n; i++) {
    if (((Vector3D *)[poly2d objectAtIndex:2 * i + 1])->y < ymin) {
      ymin = ((Vector3D *)[poly2d objectAtIndex:2 * i + 1])->y;
      iymin = i;
    }
  }
  // Take points on either side of lowest
  int next = (iymin == n - 1) ? 0 : iymin + 1;
  int previous = (iymin == 0) ? n - 1 : iymin - 1;
  // If not aligned ccw is of the sign of area
  float ccw = [OrFace area2:poly2d withInt:previous withInt:iymin withInt:next];
  if (ccw == 0) {
    // If horizontally aligned compare x
    ccw = ((Vector3D *)[poly2d objectAtIndex:2 * next])->x - ((Vector3D *)[poly2d objectAtIndex:2 * previous])->x;
  }
  return ccw;
}
// From Polygon V of XY coordinates take points of index A, B, C
// @return cross product Z = CA x CB ( > 0 means CCW)
+ (float)area2:(NSArray *)v
                             withInt:(int)a
                             withInt:(int)b
                             withInt:(int)c {
  int ax = 2 * a, bx = 2 * b, cx = 2 * c;
  int ay = 2 * a + 1, by = 2 * b + 1, cy = 2 * c + 1;
  // (v[ax]-v[cx])*(v[by]-v[cy]) - (v[ay]-v[cy])*(v[bx]-v[cx]);
  return (((((Vector3D *)[v objectAtIndex:ax])->x - ((Vector3D *)[v objectAtIndex:cx])->x))
  * ((((Vector3D *)[v objectAtIndex:by])->y - ((Vector3D *)[v objectAtIndex:cy])->x))
  - (((((Vector3D *)[v objectAtIndex:ay])->y - ((Vector3D *)[v objectAtIndex:cy])->y))
  * (((Vector3D *)[v objectAtIndex:bx])->x - ((Vector3D *)[v objectAtIndex:cx])->x)));
}
// Look if projected face contains point x,y in 3D view
// @return true if face contains (x,y) including border, false otherwise.
- (BOOL)contains3dWithDouble:(double)x
                  withDouble:(double)y {
  int hits = 0;
  int npts = (int)[points count];
  OrPoint *last = [points objectAtIndex:npts - 1];
  float lastx = last->xv, lasty = last->yv;
  float curx, cury;
  for (int i = 0; i < npts; lastx = curx, lasty = cury, i++) {
    curx = ((OrPoint *)[points objectAtIndex:i])->xv;
    cury = ((OrPoint *)[points objectAtIndex:i])->yv;
    if (cury == lasty) continue;
    double leftx;
    if (curx < lastx) {
      if (x >= lastx) continue;
      leftx = curx;
    }
    else {
      if (x >= curx) continue;
      leftx = lastx;
    }
    double test1, test2;
    if (cury < lasty) {
      if (y < cury || y >= lasty) continue;
      if (x < leftx) {
        hits++;
        continue;
      }
      test1 = x - curx;
      test2 = y - cury;
    }
    else {
      if (y < lasty || y >= cury) continue;
      if (x < leftx) {
        hits++;
        continue;
      }
      test1 = x - lastx;
      test2 = y - lasty;
    }
    if (test1 < (test2 / (lasty - cury) * (lastx - curx))) hits++;
  }
  return ((hits & 1) != 0);
}
@end

