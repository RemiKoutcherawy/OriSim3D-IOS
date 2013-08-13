//
//  source: src/rk/or/OrFace.java
//
//  Created by remi on 10/05/13.
//

@class NSArray;
@class Segment;

#import "Vector3D.h"
#import "Plane.h"

@interface OrFace : NSObject {
 @public
  NSMutableArray *points;
  int id_;
  Vector3D *normal;
  BOOL select, highlight;
  float offset;
}

- (id)init;
- (BOOL)isEqual:(id)obj;
- (Vector3D *)computeFaceNormal;
+ (Plane *)planeWithVector3D:(Vector3D *)p1
                        withVector3D:(Vector3D *)p2
                        withVector3D:(Vector3D *)p3;
+ (void)normalizeWithVector3D:(Vector3D *)v;
- (NSArray *)newCenter2d;
- (int)center3Dx;
- (int)center3Dy;
+ (float)isCCW:(NSArray *)poly2d;
+ (float)area2:(NSArray *)v
                             withInt:(int)a
                             withInt:(int)b
                             withInt:(int)c;
- (BOOL)contains3dWithDouble:(double)x
                  withDouble:(double)y;
@end
