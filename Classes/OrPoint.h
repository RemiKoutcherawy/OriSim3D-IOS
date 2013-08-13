//
//  source: src/rk/or/Point.java
//
//  Created by remi on 10/05/13.
//

#import "Vector3D.h"

@interface OrPoint : Vector3D {
 @public
  float xf, yf; // xy flat in crease pattern
  int xv, yv;   // xy view in view 2D
  int id_;      // identifier number don't confuse with (id)
  int type;     // type 
  BOOL select, highlight, fixed; // used to show in 3D
}

- (id)initWithFloat:(float)x
          withFloat:(float)y;
- (id)initWithFloat:(float)x
          withFloat:(float)y
          withFloat:(float)z;
- (id)initWithVector3D:(Vector3D *)v;
- (id)initWithOrPoint:(OrPoint *)p;
- (BOOL)isEqual:(id)p;
- (int)compareToWithId:(OrPoint *)p;
- (float)compareToWithFloat:(float)x
                  withFloat:(float)y;
@end
