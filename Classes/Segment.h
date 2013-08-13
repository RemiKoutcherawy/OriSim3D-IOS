//
//  source: src/rk/or/Segment.java
//
//  Created by remi on 10/05/13.
//

@class OrPoint;
@class Vector3D;

#define Segment_EDGE 1
#define Segment_EPSILON 0.1
#define Segment_MOUNTAIN 2
#define Segment_PLAIN 0
#define Segment_TEMPORARY -1
#define Segment_VALLEY 3
#define Segment_serialVersionUID 1

@interface Segment : NSObject {
 @public
  OrPoint *p1, *p2;
  int id_, type;
  BOOL select, highlight;
  float lg2d, lg3d, angle;
}

+ (int)PLAIN;
+ (int)EDGE;
+ (int)MOUNTAIN;
+ (int)VALLEY;
+ (int)TEMPORARY;
- (id)initWithOrPoint:(OrPoint *)a
          withOrPoint:(OrPoint *)b
                withType:(int)type
                withId:(int)id_;
- (id)initWithVector3D:(Vector3D *)a
          withVector3D:(Vector3D *)b;
- (int)compareToWithId:(Segment *)o;
- (BOOL)equalsWithOrPoint:(OrPoint *)a
              withOrPoint:(OrPoint *)b;
- (float)compareToWithOrPoint:(OrPoint *)a
                  withOrPoint:(OrPoint *)b;
- (void)reverse;
- (float)lg3dCalc;
- (float)lg2dCalc;
- (Segment *)newClosestWithSegment:(Segment *)s;
- (Segment *)closestLine:(Segment *)s;
@end
