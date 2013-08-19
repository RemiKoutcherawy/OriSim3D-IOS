//
//  source: src/rk/or/Model.java
//
//  Created by remi on 10/05/13.
//
// Model to hold Points, Segments, Faces

#import "OrFace.h"
#import "Model.h"
#import "Plane.h"
#import "OrPoint.h"
#import "Segment.h"
#import "Vector3D.h"

@implementation Model

// Constructs zero length arrays for points, faces, segments
- (id) init {
  if ((self = [super init])) {
    self->currentScale = 1.0f;
    points = [[NSMutableArray alloc] init];
    faces = [[NSMutableArray alloc] init];
    segments = [[NSMutableArray alloc] init];
    idPoint = idSegment = idFace = 0;
  }
  return self;
}
// Remove all from model
- (void) reinit {
  [points removeAllObjects];
  [faces removeAllObjects];
  [segments removeAllObjects];
  idPoint = idSegment = idFace = 0;
  self->currentScale = 1.0f;
}

// Initializes this orModel with a Square 200x200 CCW
- (void) initWithFloat:(float)x0
             withFloat:(float)y0
              withFloat:(float)x1
              withFloat:(float)y1
              withFloat:(float)x2
              withFloat:(float)y2
              withFloat:(float)x3
              withFloat:(float)y3 {
  idPoint = idSegment = idFace = 0;
  self->currentScale = 1.0f;
  OrPoint *p1 = [self addPointWithFloat:x0 withFloat:y0];
  OrPoint *p2 = [self addPointWithFloat:x1 withFloat:y1];
  OrPoint *p3 = [self addPointWithFloat:x2 withFloat:y2];
  OrPoint *p4 = [self addPointWithFloat:x3 withFloat:y3];
  [p1 release]; [p2 release]; [p3 release]; [p4 release];
  [self addSegmentWithOrPoint:p1 withOrPoint:p2 withInt:Segment_EDGE];
  [self addSegmentWithOrPoint:p2 withOrPoint:p3 withInt:Segment_EDGE];
  [self addSegmentWithOrPoint:p3 withOrPoint:p4 withInt:Segment_EDGE];
  [self addSegmentWithOrPoint:p4 withOrPoint:p1 withInt:Segment_EDGE];
  OrFace *f = [[OrFace alloc] init];
  [f->points addObject:p1];
  [f->points addObject:p2];
  [f->points addObject:p3];
  [f->points addObject:p4];
  [self addFace:f];
  [f release];
}
// Dealloc
- (void) dealloc {
  [points dealloc];
  [faces  dealloc];
  [segments dealloc];
  [super dealloc];
}

// Adds a point to this Model or return the point at x,y
- (OrPoint *)addPointWithFloat:(float)x
                     withFloat:(float)y {
  OrPoint *p = [[OrPoint alloc] initWithFloat:x withFloat:y];
  p->id_ = idPoint++;
  [points addObject:p];
  return p;
}
// Adds a point to this Model or return the point at x,y,z
- (OrPoint *)addPointWithOrPoint:(OrPoint *)pt {
  // If a point exists with same x,y,z return existing point
  for (OrPoint *p in points)  {
    if ([p compareToWithFloat:pt->x withFloat:pt->y withFloat:pt->z] == 0) {
      if ([p compareToWithFloat:pt->xf withFloat:pt->yf] == 0) {
        [pt dealloc];
        return p;
      }
    }
  }
  // If there's no point, we use passed point
  pt->id_ = idPoint++;
  [points addObject:pt];
  return pt;
}
// Adds a segment to this model
- (void)addSegmentWithOrPoint:(OrPoint *)a
                  withOrPoint:(OrPoint *)b
                  withInt:(int)type {
  // If a segment exists with same a,b return existing segment
  for (Segment *s in segments) {
    if ([s equalsWithOrPoint:a withOrPoint:b] || [s equalsWithOrPoint:b withOrPoint:a])
      return;
  }
  // If there's no segment, we use passed segment
  Segment *s = [[Segment alloc] initWithOrPoint:a withOrPoint:b withType:type withId:idSegment++];
  [segments addObject:s];
  s->id_ = idSegment++;
  [s release];
  return;
}
// Adds a face
- (void)addFace:(OrFace *)f {
  [faces addObject:f];
  f->id_ = idFace++;
  return;
}
// Splits Segment by a ratio k in  ]0 1[ counting from p1
- (void)splitSegmentWithSegment:(Segment *)s
                      withFloat:(float)k {
  OrPoint *p = [[OrPoint alloc] initWithFloat:s->p1->x + k * (s->p2->x - s->p1->x)
                                    withFloat:s->p1->y + k * (s->p2->y - s->p1->y)
                                    withFloat:s->p1->z + k * (s->p2->z - s->p1->z)];
  [self splitSegmentOnPointWithSegment:s withOrPoint:p];
}
// Split all or given faces Across two points
- (void)splitAcrossWithOrPoint:(OrPoint *)p1
                   withOrPoint:(OrPoint *)p2
                      withList:(NSArray *)list {
  Plane *pl = [[Plane alloc] init];
  [pl acrossWithOrPoint:p1 withOrPoint:p2];
  [self splitFacesByPlaneWithPlane:pl withList:list];
  [pl dealloc];
}
// Split all or given faces By two points
- (void)splitByWithOrPoint:(OrPoint *)p1
               withOrPoint:(OrPoint *)p2
                  withList:(NSArray *)list {
  Plane *pl = [[Plane alloc] init];
  [pl byWithOrPoint:p1 withOrPoint:p2];
  [self splitFacesByPlaneWithPlane:pl withList:list];
  [pl dealloc];
}
// Split faces by a plane Perpendicular to a Segment passing by a Point "p"
- (void)splitOrthoWithSegment:(Segment *)s
                  withOrPoint:(OrPoint *)p
                     withList:(NSArray *)list {
  Plane *pl = [[Plane alloc] init];
  [pl orthoWithSegment:s withOrPoint:p];
  [self splitFacesByPlaneWithPlane:pl withList:list];
  [pl dealloc];
}
// Split faces by a plane between two segments given by 3 points
- (void)splitLineToLineWithOrPoint:(OrPoint *)p0
                       withOrPoint:(OrPoint *)p1
                       withOrPoint:(OrPoint *)p2
                          withList:(NSArray *)list {
  float p0p1 = sqrt((p1->x-p0->x)*(p1->x-p0->x) + (p1->y-p0->y)*(p1->y-p0->y) + (p1->z-p0->z)*(p1->z-p0->z));
  float p1p2 = sqrt((p1->x-p2->x)*(p1->x-p2->x) + (p1->y-p2->y)*(p1->y-p2->y) + (p1->z-p2->z)*(p1->z-p2->z));
  float k = p0p1 / p1p2;
  float x = p1->x+ k * (p2->x- p1->x);
  float y = p1->y + k * (p2->y - p1->y);
  float z = p1->z + k * (p2->z - p1->z);
  OrPoint *e = [[OrPoint alloc] initWithFloat:x withFloat:y withFloat:z];
  Plane *pl = [[Plane alloc] init];
  [pl acrossWithOrPoint:p0 withOrPoint:e];
  [self splitFacesByPlaneWithPlane:pl withList:list];
  [e dealloc];
  [pl dealloc];
}
// Split listed faces by a plane between two segments
- (void)splitLineToLineWithSegment:(Segment *)s1
                       withSegment:(Segment *)s2
                          withList:(NSArray *)list {
  Segment *s = [s1 closestLine:s2];
  if ([s lg3dCalc] < 10) {
    // Segments cross themselves at c Center
    OrPoint *c = s->p1;
    // with s1
    Vector3D *s1p1c = [s1->p1 newTo:c];
    Vector3D *s1p2c = [s1->p2 newTo:c];
    OrPoint *a = [s1p1c length] > [s1p2c length] ? s1->p1 : s1->p2;
    [s1p1c dealloc];
    [s1p2c dealloc];
    // same with s2
    Vector3D *s2p1c = [s2->p1 newTo:c];
    Vector3D *s2p2c = [s2->p2 newTo:c];
    OrPoint *b = [s2p1c length] > [s2p2c length] ? s2->p1 : s2->p2;
    [s2p1c dealloc];
    [s2p2c dealloc];
    [self splitLineToLineWithOrPoint:a withOrPoint:c withOrPoint:b withList:list];
  }
  else {
    // Segments do not cross ... Very strange
    Plane *pl = [[Plane alloc] init];
    [pl acrossWithOrPoint:s->p1 withOrPoint:s->p2];
    [self splitFacesByPlaneWithPlane:pl withList:list];
    [pl dealloc];
  }
  [s dealloc];
}
// Split segments crossing on common point
- (void)splitSegmentCrossingWithSegment:(Segment *)s1
                            withSegment:(Segment *)s2 {
  Segment *c = [s1 newClosestWithSegment:s2];
  if (ABS( [c->p1 compareToWithId:c->p2] ) < 1) {
    OrPoint *p1 = [[OrPoint alloc] initWithFloat:c->p1->x withFloat:c->p1->y withFloat:c->p1->z];
    [self splitSegmentOnPointWithSegment:s1 withOrPoint:p1];
    OrPoint *p2 = [[OrPoint alloc] initWithFloat:c->p1->x withFloat:c->p1->y withFloat:c->p1->z];
    [self splitSegmentOnPointWithSegment:s2 withOrPoint:p2];
  }
  [c dealloc];
}
// Split a segment on a point, add this point to the model, and faces containing this segment
- (void)splitSegmentOnPointWithSegment:(Segment *)s1
                           withOrPoint:(OrPoint *)p {
  [self align2dFrom3dWithOrPoint:p withSegment:s1];
  OrFace *l = [self searchFaceWithSegment:s1 withFace:nil];
  if (l != nil && ![l->points containsObject:p]) {
    id pts = l->points;
    for (int i = 0; i < [pts count]; i++) {
      if ([pts objectAtIndex:i] == s1->p1 && [pts objectAtIndex:i == [pts count] - 1 ? 0 : i + 1] == s1->p2) {
        [pts insertObject:p atIndex:i + 1];
        break;
      }
      if ([pts objectAtIndex:i] == s1->p2 && [pts objectAtIndex:i == [pts count] - 1 ? 0 : i + 1] == s1->p1) {
        [pts insertObject:p atIndex:i + 1];
        break;
      }
    }
  }
  OrFace *r = [self searchFaceWithSegment:s1 withFace:l];
  if (r != nil && ![r->points containsObject:p]) {
    id pts = r->points;
    for (int i = 0; i < [pts count]; i++) {
      if ([pts objectAtIndex:i] == s1->p1 && [pts objectAtIndex:i == [pts count] - 1 ? 0 : i + 1] == s1->p2) {
        [pts insertObject:p atIndex:i + 1];
        break;
      }
      if ([pts objectAtIndex:i] == s1->p2 && [pts objectAtIndex:i == [pts count] - 1 ? 0 : i + 1] == s1->p1) {
        [pts insertObject:p atIndex:i + 1];
        break;
      }
    }
  }
  [self addPointWithOrPoint:p];
  [self splitSegmentWithSegment:s1 withOrPoint:p];
}
// Splits Segment on a point
- (void)splitSegmentWithSegment:(Segment *)s
                    withOrPoint:(OrPoint *)p {
  if ([s->p1 compareToWithId:p] == 0 || [s->p2 compareToWithId:p] == 0)
    return;
  [self addSegmentWithOrPoint:p withOrPoint:s->p2 withInt:s->type];
  s->p2 = p;
  [s lg2dCalc];
}
// Split listed faces by a plane
- (void)splitFacesByPlaneWithPlane:(Plane *)pl
                          withList:(NSArray *)list {
  list = (list == nil ? faces : [list count] == 0 ? faces : list);
  NSMutableArray *listToSplit = [[NSMutableArray alloc] init];
  for (OrFace *f in list) {
    for (int i = 0; i < [f->points count] - 1; i++) {
      Vector3D *vi =[pl intersectWithOrPoint:[f->points objectAtIndex:i] withOrPoint:[f->points objectAtIndex:i+1]];
      if ( vi != nil && ![listToSplit containsObject:f]) {
        [listToSplit addObject:f];
        [vi dealloc];
        break;
      }
    }
  }
  for (OrFace *f in listToSplit) {
    [self splitFaceByPlaneWithFace:f withPlane:pl];
  }
  [listToSplit dealloc];
}
// Rotate around axis Segment with angle list of Points
- (void)rotateWithSegment:(Segment *)s
                withFloat:(float)angle
                 withList:(NSArray *)list {
  angle *= M_PI / 180.0;
  float ax = s->p1->x, ay = s->p1->y, az = s->p1->z;
  float nx = s->p2->x - ax, ny = s->p2->y - ay, nz = s->p2->z - az;
  float n = (float) (1.0 / sqrt(nx * nx + ny * ny + nz * nz));
  nx *= n;
  ny *= n;
  nz *= n;
  float sin = sinf(angle), cos = cosf(angle);
  float c1 = 1.0f - cos;
  float c11 = c1 * nx * nx + cos, c12 = c1 * nx * ny - nz * sin, c13 = c1 * nx * nz + ny * sin;
  float c21 = c1 * ny * nx + nz * sin, c22 = c1 * ny * ny + cos, c23 = c1 * ny * nz - nx * sin;
  float c31 = c1 * nz * nx - ny * sin, c32 = c1 * nz * ny + nx * sin, c33 = c1 * nz * nz + cos;
  for (OrPoint *p in list) {
    float ux = p->x - ax, uy = p->y - ay, uz = p->z - az;
    p->x = ax + c11 * ux + c12 * uy + c13 * uz;
    p->y = ay + c21 * ux + c22 * uy + c23 * uz;
    p->z = az + c31 * ux + c32 * uy + c33 * uz;
  }
}
// Turn model around 1:X axis 2:Y axis 3:Z axis
- (void)turnWithFloat:(float)angle
              withInt:(int)axe {
  angle *= M_PI / 180.0;
  float ax = 0, ay = 0, az = 0;
  float nx = 0.0f, ny = 0.0f, nz = 0.0f;
  if (axe == 1) nx = 1.0f;
  else if (axe == 2) ny = 1.0f;
  else if (axe == 3) nz = 1.0f;
  float n = (float) (1.0 / sqrt(nx * nx + ny * ny + nz * nz));
  nx *= n;
  ny *= n;
  nz *= n;
  float sin = sinf(angle), cos = cosf(angle);
  float c1 = 1.0f - cos;
  float c11 = c1 * nx * nx + cos, c12 = c1 * nx * ny - nz * sin, c13 = c1 * nx * nz + ny * sin;
  float c21 = c1 * ny * nx + nz * sin, c22 = c1 * ny * ny + cos, c23 = c1 * ny * nz - nx * sin;
  float c31 = c1 * nz * nx - ny * sin, c32 = c1 * nz * ny + nx * sin, c33 = c1 * nz * nz + cos;
  for (OrPoint *p in points) {
    float ux = p->x - ax, uy = p->y - ay, uz = p->z - az;
    p->x = ax + c11 * ux + c12 * uy + c13 * uz;
    p->y = ay + c21 * ux + c22 * uy + c23 * uz;
    p->z = az + c31 * ux + c32 * uy + c33 * uz;
  }
}
// Adjust list of Points
- (float)adjustwithList:(NSArray *)list {
  float dmax = 100;
  for (int i = 0; dmax > 0.001f && i < 10; i++) {
    dmax = 0;
    for (OrPoint *p in list) {
      float d = [self adjustWithOrPoint:p withList:nil];
      if (d > dmax) dmax = d;
    }
  }
  return dmax;
}
// Adjust one of Point with list of segments
- (float)adjustSegmentsWithOrPoint:(OrPoint *)p
                          withList:(NSArray *)segs {
  float dmax = 100;
  for (int i = 0; dmax > 0.001f && i < 10; i++) {
    dmax = 0;
    float d = [self adjustWithOrPoint:p withList:segs];
    if (d > dmax) dmax = d;
  }
  return dmax;
}
// Adjust one Point on its (eventually given) segments
- (float)adjustWithOrPoint:(OrPoint *)p
                  withList:(NSArray *)segts {
  // Take all segments containing point p or given list
  BOOL isListMadeWithPoint = segts == nil;
  NSArray *segs = segts == nil ? [self searchSegmentsListWithOrPoint:p] : segts;
  float count = [segs count];
  float dmax = 100;
  // Kaczmarz
  // Iterate while length difference between 2d and 3d is > 1e-3
  // Pm is the medium point
  Vector3D *pm = [[Vector3D alloc] init];
  int imax = 0;
  for (int i = 0; dmax > 0.001f && i < 20; i++) {
    dmax = 0;
    // Iterate over all segments
    // Pm is the medium point
    [pm setWithX:0 Y:0 Z:0];
    for (Segment *s in segs) {
      float lg3d = [s lg3dCalc] / self->currentScale;
      float lg2d = [s lg2dCalc];
      float d = lg2d - lg3d;
      if (fabs(d) > dmax)
        dmax = fabs(d);
      float r = lg2d / lg3d;
      if (s->p2->id_ == p->id_) {
        // move p2
        pm->x += s->p1->x + (s->p2->x - s->p1->x) * r;
        pm->y += s->p1->y + (s->p2->y - s->p1->y) * r;
        pm->z += s->p1->z + (s->p2->z - s->p1->z) * r;
      }
      else if (s->p1->id_ == p->id_) {
        // move p1
        pm->x += s->p2->x + (s->p1->x - s->p2->x) * r;
        pm->y += s->p2->y + (s->p1->y - s->p2->y) * r;
        pm->z += s->p2->z + (s->p1->z - s->p2->z) * r;
      }
    }
    // Average position taking all segments
    if (count != 0) {
      p->x = pm->x / count;
      p->y = pm->y / count;
      p->z = pm->z / count;
    }
    imax = i;
  }
  if (isListMadeWithPoint)
    [segs dealloc];
  [pm dealloc];
  return dmax;
}
// Select (highlight) points
- (void)selectPtsWithList:pts {
  for (OrPoint *p in pts) {
    p->select ^= YES;
  }
}
// Select (highlight) segments
- (void)selectSegsWithList:segs {
  for (Segment *s in segs) {
    s->select ^= YES;
  }
}
// Move list of points by dx,dy,dz
- (void)moveBydx:(float)dx
              dy:(float)dy
              dz:(float)dz
        withList:(NSArray *)pts {
  pts = pts == nil ? points : [pts count] == 0 ? points : pts;
  for (OrPoint *p in pts) {
    p->x += dx;
    p->y += dy;
    p->z += dz;
  }
}
// Move on a point P0 all following points, k from 0 to 1 for animation
- (void)moveOnWithOrPoint:(OrPoint *)p0
                withFloat:(float)k1
                withFloat:(float)k2
                 withList:(NSArray *)pts {
  for (OrPoint *p in pts) {
    p->x = p0->x * k1 + p->x * k2;
    p->y = p0->y * k1 + p->y * k2;
    p->z = p0->z * k1 + p->z * k2;
  }
}
// Move on a line S0 all following points, k from 0 to 1 for animation
- (void)moveOnLineWithSegment:(Segment *)s
                    withFloat:(float)k1
                    withFloat:(float)k2
                     withList:(NSArray *)pts {
  for (OrPoint *p in pts) {
    // Point n = s0->closestLine(new Segment(p,p))->p1;
    // First case if there is a segment joining point p and s search point common pc
    OrPoint *pc = nil, *pd = nil;
    for (Segment *si in segments) {
      if ([((Segment *) si) equalsWithOrPoint:p withOrPoint:s->p1]) {
        pc = si->p2;
        pd = s->p2;
        break;
      }
      else if ([((Segment *) si) equalsWithOrPoint:p withOrPoint:s->p2]) {
        pc = si->p2;
        pd = s->p1;
        break;
      }
      else if ([((Segment *) si) equalsWithOrPoint:s->p1 withOrPoint:p]) {
        pc = si->p1;
        pd = s->p2;
        break;
      }
      else if ([((Segment *) si) equalsWithOrPoint:s->p2 withOrPoint:p]) {
        pc = si->p1;
        pd = s->p1;
        break;
      }
    }
    // If we have pc point common and pd point distant
    if (pc != nil) {
      // Turn p on pc pd (keep distance from Pc to P
      float pcp = (float) sqrt((pc->x-p->x)*(pc->x-p->x) + (pc->y-p->y)*(pc->y-p->y) + (pc->z-p->z)*(pc->z-p->z));
      float pcpd = (float) sqrt((pc->x-pd->x)*(pc->x-pd->x) + (pc->y-pd->y)*(pc->y-pd->y) + (pc->z-pd->z)*(pc->z- pd->z));
      float k = pcp / pcpd;
      p->x = (pc->x + k *(pd->x-pc->x))*k1 + p->x*k2;
      p->y = (pc->y + k *(pd->y-pc->y))*k1 + p->y*k2;
      p->z = (pc->z + k *(pd->z-pc->z))*k1 + p->z*k2;
      return;
    }
    // Second case
    else {
      // Project point
      Segment *ss = [[Segment alloc] initWithVector3D:p withVector3D:p];
      Segment *sc = [s closestLine:ss];
      OrPoint *pp = sc->p1;
      // Move point p on projected pp
      p->x = (p->x + (pp->x - p->x)) * k1 + p->x * k2;
      p->y = (p->y + (pp->y - p->y)) * k1 + p->y * k2;
      p->z = (p->z + (pp->z - p->z)) * k1 + p->z * k2;
      [sc release];
      [ss release];
    }
    return;
  }
}
// Move given or all points to z = 0
- (void)flatWithList:pts {
  id lp = [pts count] == 0 ? points : pts;
  for (OrPoint *p in lp) {
    p->z = 0;
  }
}
// Offset by dz all following faces according to Z
- (void)offsetWithFloat:(float)dz
               withList:(NSArray *)lf {
  for (OrFace *f in lf) {
    f->offset = dz * (f->normal->z >= 0 ? 1 : -1);
  }
}
// Offset all faces either behind zero plane or above zero plane
- (void)offsetDecalWithFloat:(float)dcl
                    withList:(NSArray *)list {
  list = [list count] == 0 ? faces : list;
  float max = dcl < 0 ? -1000 : 1000;
  float o = 0;
  for (OrFace *f in list) {
    [f computeFaceNormal];
    o = f->offset * (f->normal->z >= 0 ? 1 : -1);
    if (dcl < 0 && o > max) max = o;
    if (dcl > 0 && o < max) max = o;
  }
  for (OrFace *f in list) {
    f->offset -= (max - dcl) * (f->normal->z >= 0 ? 1 : -1);
  }
}
//  Add offset dz to all following faces according to Z
- (void)offsetAddWithFloat:(float)dz
                  withList:(NSArray *)list {
  id lf = [list count] == 0 ? faces : list;
  for (OrFace *f in lf) {
    f->offset += dz * (f->normal->z >= 0 ? 1 : -1);
  }
}
//  Multiply offset by k for all faces or only listed
- (void)offsetMulWithFloat:(float)k
                  withList:(NSArray *)list {
  id lf = [list count] == 0 ? faces : list;
  for (OrFace *f in lf) {
    f->offset *= k;
  }
}
// Divide offset around average offset, to fold between
- (void)offsetBetweenwithList:(NSArray *)list {
  float average = 0;
  int n = 0;
  for (OrFace *f in list) {
    average += f->offset * (f->normal->z >= 0 ? 1 : -1);
    n++;
  }
  average /= n;
  for (OrFace *f in faces) {
    f->offset -= average * (f->normal->z >= 0 ? 1 : -1);
  }
  for (OrFace *f in list) {
    f->offset /= 2;
  }
}
//  Split face f by plane pl and add Points to joint faces
- (void)splitFaceByPlaneWithFace:(OrFace *)f1
                       withPlane:(Plane *)pl {
  Vector3D *i = nil;
  OrPoint *p1 = nil, *p2 = nil;
  NSMutableArray *frontSide = [[NSMutableArray alloc] init]; // Front side
  NSMutableArray *backSide  = [[NSMutableArray alloc] init]; // Back side
  
  // Begin with last point
  OrPoint *a = ((OrPoint *) [f1->points objectAtIndex:[f1->points count] - 1]);
  int aSide = [pl classifyPointToPlaneWithVector3D:a];
  for (int n = 0; n < [f1->points count]; n++) {
    // 9 cases to deal with : behind -1, on 0, in front +1
  	// Segment from previous 'a'  to current 'b'
  	// output to Front points 'fb' and  Back points 'bp'
    //  	  a  b Inter front back
  	// c1) -1  1 i     i b   i
  	// c2)  0  1 a     b     .
  	// c3)  1  1 .     b     .
  	// c4)  1 -1 i     i     i b
  	// c5)  0 -1 a     .     a b
  	// c6) -1 -1 .           b
  	// c7)  1  0 b     b     .
  	// c8)  0  0 a b   b     .
  	// c9) -1  0 b     b     b
    OrPoint *b = ((OrPoint *) [f1->points objectAtIndex:n]);
    int bSide = [pl classifyPointToPlaneWithVector3D:b];
    if (bSide == 1) { // b in front
      if (aSide == -1) { // a behind
        // c1) b in front, a behind => edge cross
        if (i != nil) [i dealloc];
        i = [pl intersectWithOrPoint:b withOrPoint:a];
        // Create intersection point 'p', add to joint face, split segment
        OrPoint *p = [self addPointToJointFaceWithFace:f1 withVector3D:i withOrPoint:a withOrPoint:b];
        // Add 'p' to front and back sides
        [frontSide addObject:p];
        [backSide addObject:p];
        [p release];
        // Keep new point 'p' for the new segment
        if (p1 == nil) p1 = p;
        else if (p2 == nil) p2 = p;
        // Check
        else NSLog(@"%@", [NSString stringWithFormat:@"Three intersections:%@ %@ %@", p1, p2, p]);
        // Check
        if ([pl classifyPointToPlaneWithVector3D:p] != 0)
          NSLog(@"%@", [NSString stringWithFormat:@"Intersection not in plane ! p:%@", p]);
      }
      else if (aSide == 0) {
        // c2) 'b' in front, 'a' on
        // Keep last point 'a' for the new segment
        // leaving thickness
        if (p1 == nil) p1 = a;
        else if (p2 == nil) p2 = a;
        // Check
        else NSLog(@"%@", [NSString stringWithFormat:@"Three intersections:%@ %@ %@", p1, p2, a]);
      }
      // c3) 'b' in front 'a' in front
      // In all three cases add 'b' to front side
      [frontSide addObject:b];
    }
    else if (bSide == -1) { // b behind
      if (aSide == 1) { // a in front
        // c4) edge cross add intersection to both sides
        if (i != nil) [i dealloc];
        i = [pl intersectWithOrPoint:b withOrPoint:a];
        // Create intersection point 'p', add to joint face, split segment
        OrPoint *p = [self addPointToJointFaceWithFace:f1 withVector3D:i withOrPoint:a withOrPoint:b];
        // Add 'p' to front and back sides
        [frontSide addObject:p];
        [backSide addObject:p];
        [p release];
        // Keep new point p for the new segment
        if (p1 == nil) p1 = p;
        else if (p2 == nil) p2 = p;
        // Check
        else NSLog(@"%@", [NSString stringWithFormat:@"Three intersections:%@ %@ %@", p1, p2, p]);
      }
      else if (aSide == 0) {
        // c5) 'a' on 'b' behind
        // Keep point 'a' for the new segment
        // leaving thickness
        if (p1 == nil) p1 = a;
        else if (p2 == nil) p2 = a;
        // Check
        else NSLog(@"%@", [NSString stringWithFormat:@"Three intersections:%@ %@ %@", p1, p2, a]);
        // Add 'a' to back side when [a,b] goes from 'on' to 'behind'
        [backSide addObject:a];
      }
      // c6) 'a' behind 'b' behind
      // In all 3 cases add current point 'b' to back side
      [backSide addObject:b];
    }
    else {
      // bSide == 0 'b' is 'on'
      // c7) 'a' front 'b' on c8) 'a' on 'b' on
      // Add 'b' to back side only if 'a' was in back face
      if (aSide == -1) {
        // c9 'a' behind 'b' on
        [backSide addObject:b];
      }
      // In all 3 cases, add 'b' to front side
      [frontSide addObject:b];
    }
    // Next edge
    a = b;
    aSide = bSide;
  }
  if (i != nil) [i dealloc];
  
  // Only if two different intersections has been found
  if (p1 != nil && p2 != nil) {
    // New back Face
    OrFace *f2 = [[OrFace alloc] init];
    f2->offset = f1->offset;
    [f2->points addObjectsFromArray:backSide];
    [self addFace:f2];
    [f2 release];
    // New segment
    [self addSegmentWithOrPoint:p1 withOrPoint:p2 withInt:Segment_PLAIN];
    // Updated front Face
    [f1->points removeAllObjects];
    [f1->points addObjectsFromArray:frontSide];
  }
  [frontSide dealloc];
  [backSide dealloc];
  return;
}
// Look if the point A is already in the face, if not add it and return true
- (OrPoint *)addPointToJointFaceWithFace:(OrFace *)f
                            withVector3D:(Vector3D *)i
                             withOrPoint:(OrPoint *)a
                             withOrPoint:(OrPoint *)b {
  // If the point is already in the model no need to do anything
  for (OrPoint *p in f->points ) {
    if ([p compareToWithFloat:i->x withFloat:i->y withFloat:i->z] == 0.0f) {
      NSLog(@"%@", [NSString stringWithFormat:@"PB increase plane thickness p:%@ near:%@", p, i]);
      return p;
    }
  }
  // Point i, not found, create, use to split segment, and add to the joint face
  // Create new Point
  OrPoint *pnew = [[OrPoint alloc] initWithFloat:i->x withFloat:i->y withFloat:i->z];
  // Get the segment to split
  Segment *s = [self searchSegmentWithOrPoint:a withOrPoint:b];
  // Set 2D coordinates from 3D
  [self align2dFrom3dWithOrPoint:pnew withSegment:s];
  // Add this as a new Point to the model and dealloc newPoint if there is already one.
  OrPoint *p = [self addPointWithOrPoint:pnew];
  // Search joint face containing s->p1 and s->p2
  OrFace *jf = [self searchFaceWithSegment:s withFace:f];
  // If there is a joint face and without the new point 'p' between a, b
  if (jf != nil)
    if (![jf->points containsObject:p]) {
      // Add after a or b for the left face
      if ([jf->points indexOfObject:a] == [jf->points indexOfObject:b] - 1)
        [jf->points insertObject:p atIndex:[jf->points indexOfObject:b]];
      else if ([jf->points indexOfObject:a] == [jf->points indexOfObject:b] + 1)
        [jf->points insertObject:p atIndex:[jf->points indexOfObject:a]];
      else if ([jf->points indexOfObject:a] == 0)
        [jf->points insertObject:p atIndex:0];
      else if ([jf->points indexOfObject:b] == 0)
        [jf->points insertObject:p atIndex:0];
      else {
        NSLog(@"%@", [NSString stringWithFormat:@"Face contains points a,b but not the segment [a,b] jf:%@ a:%@ b:%@", jf, a, b]);
        NSLog(@"%@", [NSString stringWithFormat:@"jf->points->contains(a):%d", [jf->points containsObject:a]]);
        NSLog(@"%@", [NSString stringWithFormat:@"jf->points->indexOf(a):%d", [jf->points indexOfObject:a]]);
    }
  }
  // Now we can shorten s to p
  [self splitSegmentWithSegment:s withOrPoint:p];
  return p;
}
// Align Point PB on segment s in 2D from coordinates in 3D
- (void)align2dFrom3dWithOrPoint:(OrPoint *)pb
                     withSegment:(Segment *)s {
  // Align point B in 2D from 3D
  float lg3d = sqrtf((s->p1->x-pb->x)*(s->p1->x-pb->x) +(s->p1->y-pb->y)*(s->p1->y-pb->y) +(s->p1->z-pb->z)*(s->p1->z-pb->z));
  float t = lg3d / [s lg3dCalc];
  pb->xf = s->p1->xf + t * (s->p2->xf - s->p1->xf);
  pb->yf = s->p1->yf + t * (s->p2->yf - s->p1->yf);
}
// Compute angle between faces of given segment
- (float)computeAngleWithSegment:(Segment *)s {
  OrPoint *a = s->p1, *b = s->p2;
  // Find faces left and right
  OrFace *left = [self faceLeftWithOrPoint:a withOrPoint:b];
  OrFace *right = [self faceRightWithOrPoint:a withOrPoint:b];
  // Compute angle in Degrees at this segment
  if (s->type == Segment_EDGE)
    return 0;
  if (right == nil || left == nil) {
    NSLog(@"%@", [NSString stringWithFormat:@"PB no right or left face for %@ left %@ right %@", self, left, right]);
    return 0;
  }
  Vector3D *nL = [left computeFaceNormal];
  Vector3D *nR = [right computeFaceNormal];
  // Cross product nL nR
  float cx = nL->y*nR->z - nL->z*nR->y;
  float cy = nL->z*nR->x - nL->x*nR->z;
  float cz = nL->x*nR->y - nL->y*nR->x;
  // Segment vector
  float vx = s->p2->x - s->p1->x;
  float vy = s->p2->y - s->p1->y;
  float vz = s->p2->z - s->p1->z;
  // Scalar product between segment and cross product, normed
  float sin = (cx*vx + cy*vy + cz*vz) / sqrtf(vx*vx + vy*vy + vz*vz);
  // Scalar between normals
  float cos = nL->x*nR->x +nL->y*nR->y +nL->z*nR->z;
  if (cos > 1.0f) cos = 1.0f;
  if (cos < -1.0f) cos = -1.0f;
  s->angle = (float) (acosf(cos) / M_PI * 180.0);
  if (isnan(s->angle)) {
    s->angle = 0.0f;
  }
  if (sin < 0)
    s->angle = -s->angle;
  // To follow the convention folding in front is positive
  s->angle = -s->angle;
  return s->angle;
}
// Find face on the right
- (OrFace *)faceRightWithOrPoint:(OrPoint *)a
                     withOrPoint:(OrPoint *)b {
  int ia, ib;
  OrFace *right = nil;
  for (OrFace *f in faces) {
    // Both points are in face
    if (((ia = [f->points indexOfObject:a]) >= 0)
        && ((ib = [f->points indexOfObject:b]) >= 0)) {
      // a is after b, the face is on the right
      if (ia == ib + 1 || (ib == [f->points count] - 1 && ia == 0)) {
        right = f;
        break;
      }
    }
  }
  return right;
}
// Find face on the left
- (OrFace *)faceLeftWithOrPoint:(OrPoint *)a
                  withOrPoint:(OrPoint *)b {
  int ia, ib;
  OrFace *left = nil;
  for (OrFace *f in faces) {
    // Both points are in face
    if (((ia = [f->points indexOfObject:a]) >= 0)
        && ((ib = [f->points indexOfObject:b]) >= 0)) {
      // b is after a, the face is on the left
      if (ib == ia + 1 || (ia == [f->points count] - 1 && ib == 0)) {
        left = f;
        break;
      }
    }
  }
  return left;
}
// Search face containing a and b but which is not f0
- (OrFace *)searchFaceWithSegment:(Segment *)s
                       withFace:(OrFace *)f0 {
  OrPoint *a = s->p1, *b = s->p2;
  for (OrFace *f in faces) {
    if (![f isEqual:f0]
        && ([f->points containsObject:a]) && ([f->points containsObject:b])) {
      return f;
    }
  }
  return nil;
}
// Search segment containing a and b
- (Segment *) searchSegmentWithOrPoint:(OrPoint *)a
                          withOrPoint:(OrPoint *)b {
  for (Segment *s in segments) {
    if ([s equalsWithOrPoint:a withOrPoint:b] || [s equalsWithOrPoint:b withOrPoint:a])
      return s;
  }
  return nil;
}
// Search segments containing a
- (NSArray *) searchSegmentsListWithOrPoint:(OrPoint *)a {
  id l = [[NSMutableArray alloc] init];
  for (Segment *s in segments) {
    if (s->p1->id_ == a->id_ || s->p2->id_ == a->id_)
      [l addObject:s];
  }
  return l;
}
// 2D Boundary [xmin, ymin, xmax, ymax]
- (float *) get2DBounds {
  float xmax = -100.0f, xmin = 100.0f;
  float ymax = -100.0f, ymin = 100.0f;
  for (OrPoint *p in points) {
      float x = p->xf, y = p->yf;
      if (x > xmax) xmax = x;
      if (x < xmin) xmin = x;
      if (y > ymax) ymax = y;
      if (y < ymin) ymin = y;
  }
  float *ret = (float *)malloc(4 * sizeof(float));
//  float boundsvalues[] = {xmin, ymin, xmax, ymax};
//  memccpy(ret, boundsvalues, 4, sizeof(float));
  ret[0]=xmin; ret[1]=ymin; ret[2]=xmax; ret[3]=ymax;
  return ret;
}
// Fit the model to -200 +200
- (void) zoomFit {
  float *b = [self get3DBounds];
  float w = 400;
  float scale = w / MAX(b[2] - b[0], b[3] - b[1]);
  float cx = -(b[0] + b[2]) / 2, cy = -(b[1] + b[3]) / 2;
  [self moveBydx:cx dy:cy dz:0 withList:nil];
  [self scaleModelWithFloat:scale];
  free(b);
}
// Scale model
- (void) scaleModelWithFloat:(float)scale {
  for (OrPoint *p in points) {
    p->x *= scale;
    p->y *= scale;
    p->z *= scale;
  }
  self->currentScale *= scale;
}
// 3D Boundary View [xmin, ymin, xmax, ymax]
- (float *) get3DBounds {
  float xmax = -200.0f, xmin = 200.0f;
  float ymax = -200.0f, ymin = 200.0f;
  for (OrPoint *p in points) {
    float x = p->x;
    float y = p->y;
    if (x > xmax) xmax = x;
    if (x < xmin) xmin = x;
    if (y > ymax) ymax = y;
    if (y < ymin) ymin = y;
  }
  // Malloc => caller must free returned pointer
  float *ret = (float*)malloc(4 * sizeof(float));
  ret[0]=xmin; ret[1]=ymin;
  ret[2]=xmax; ret[3]=ymax;
  return ret;
}

- (NSData *)getSerialized {
//  JavaIoByteArrayOutputStream *bs = [[JavaIoByteArrayOutputStream alloc] init];
//  JavaIoObjectOutputStream *oos;
//  @try {
//    oos = [[JavaIoObjectOutputStream alloc] initWithJavaIoOutputStream:bs];
//    [((JavaIoObjectOutputStream *) oos) writeObjectWithId:self];
//    [((JavaIoObjectOutputStream *) oos) close];
//  }
//  @catch (JavaIoIOException *e) {
//    [((JavaIoIOException *) e) printStackTrace];
//  }
//  return [((JavaIoByteArrayOutputStream *) bs) toByteArray];
    return nil;
}
// Debug
- (NSString *)description {
  NSString *sb = [NSString stringWithFormat:@"Points[%d] : ", [points count]];
  for (OrPoint *p in points) {
    [[sb stringByAppendingFormat:@"%@", p] stringByAppendingString:@"\n"];
  }
  [sb stringByAppendingString:[NSString stringWithFormat:@"Segments[%d] : ", [segments count]]];
  for (Segment *s in segments ) {
      [[sb stringByAppendingFormat:@"%@",s] stringByAppendingString:@"\n"];
  }
  [sb stringByAppendingString:[NSString stringWithFormat:@"Faces[%d] : ", [faces count]]];
  for (OrFace *f in faces) {
      [[sb stringByAppendingFormat:@"%@",f] stringByAppendingString:@"\n"];
  }
  return sb;
}

@end
