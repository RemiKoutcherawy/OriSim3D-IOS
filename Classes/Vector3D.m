//
//  source: src/rk/or/Vector3D.java
//
//  Created by remi on 10/05/13.
//
// A simple vector to hold 3 coordinates
// x, y, z float values

#import "Vector3D.h"

@implementation Vector3D

// Initialize with 3 values
- (id)init {
  self = [super init];
  if (self) {
    x = 0.0f;
    y = 0.0f;
    z = 0.0f;
  }
  return self;
}
// New vector with coordinates x,y,z
- (id)initWithX:(float)xi
          Y:(float)yi
          Z:(float)zi {
  if ((self = [super init])) {
    x = xi;
    y = yi;
    z = zi;
  }
  return self;
}
// New vector with coordinates of v
- (id)initWithVector3D:(Vector3D *)v {
  if ((self = [super init])) {
    x = v->x;
    y = v->y;
    z = v->z;
  }
  return self;
}
// dealloc
- (void)dealloc {
  [super dealloc];
}

// Sets this vector with coordinates x,y,z
- (void)setWithX:(float)xs
           Y:(float)ys
           Z:(float)zs {
  x = xs;
  y = ys;
  z = zs;
}
// Sets this vector with coordinates v
- (void)setWithVector3D:(Vector3D *)v {
  x = v->x;
  y = v->y;
  z = v->z;
}
// Sets this vector with coordinates of p
- (void)moveToWithVector3D:(Vector3D *)p {
  x = p->x;
  y = p->y;
  z = p->z;
}
// Return a new Vector this * t
- (Vector3D *)scaleWithFloat:(float)t {
  return ([[Vector3D alloc] initWithX:x * t Y:y * t Z:z * t]);
}
// Return this * t
- (Vector3D *)scaleThisWithFloat:(float)t {
  x *= t;
  y *= t;
  z *= t;
  return self;
}
// New Vector from this to B
- (Vector3D *) newTo:(Vector3D *)B {
  return ([[Vector3D alloc] initWithX:B->x - x Y:B->y - y Z:B->z - z]);
}
// New Vector this + A
- (Vector3D *) addWithVector3D:(Vector3D *)A {
  return ([[Vector3D alloc] initWithX:A->x + x Y:A->y + y Z:A->z + z]);
}
// This Vector this + A
- (Vector3D *) addToThisWithVector3D:(Vector3D *)A {
  x += A->x;
  y += A->y;
  z += A->z;
  return self;
}
// This Vector this - A
- (Vector3D *) subToThisWithVector3D:(Vector3D *)A {
  x -= A->x;
  y -= A->y;
  z -= A->z;
  return self;
}
// Dot this with B
- (float)dotWithVector3D:(Vector3D *)B {
  return (x * B->x + y * B->y + z * B->z);
}
// Dot this with Bx,By,Bz
- (float)dotWithFloat:(float)Bx
            withFloat:(float)By
            withFloat:(float)Bz {
  return (x * Bx + y * By + z * Bz);
}
// Dot A.B
+ (float)dotWithVector3D:(Vector3D *)A
            withVector3D:(Vector3D *)B {
  return (A->x * B->x + A->y * B->y + A->z * B->z);
}
// New Vector Cross this with B
- (Vector3D *)crossWithVector3D:(Vector3D *)B {
  return [[Vector3D alloc] initWithX:y * B->z - z * B->y Y:z * B->x - x * B->z Z:x * B->y - y * B->x];
}
// New Vector Cross this with Bx, By, Bz
- (Vector3D *)crossWithFloat:(float)Bx
                       withFloat:(float)By
                       withFloat:(float)Bz {
  return [[Vector3D alloc] initWithX:y * Bz - z * By Y:z * Bx - x * Bz Z:x * By - y * Bx];
}
// New Vector Cross AxB
+ (Vector3D *)crossWithVector3D:(Vector3D *)A
                       withVector3D:(Vector3D *)B {
  return [[Vector3D alloc] initWithX:A->y * B->z - A->z * B->y Y:A->z * B->x - A->x * B->z Z:A->x * B->y - A->y * B->x];
}
// New Vector Cross AxB
+ (float)scalarTripleWithVector3D:(Vector3D *)A
                     withVector3D:(Vector3D *)B
                     withVector3D:(Vector3D *)C {
  return (A->y * B->z - A->z * B->y) * C->x + (A->z * B->x - A->x * B->z) * C->y + (A->x * B->y - A->y * B->x) * C->z;
}
// sqrt(this.this)
- (float)length {
  return (float) sqrt(x * x + y * y + z * z);
}
// Squared Length = dot(this.this)
- (float)lengthSquared {
  return x * x + y * y + z * z;
}
// sqrt(A.A)
+ (float)lengthWithVector3D:(Vector3D *)A {
  return (float) sqrt(A->x * A->x + A->y * A->y + A->z * A->z);
}
// This/Squared(this.this)
- (void)normalize {
  float t = x * x + y * y + z * z;
  if (t != 0 && t != 1) t = (float) (1.0 / sqrt(t));
  x *= t;
  y *= t;
  z *= t;
}
// New Vector A/sqrt(A.A)
+ (Vector3D *)normalizeWithVector3D:(Vector3D *)A {
  float t = A->x * A->x + A->y * A->y + A->z * A->z;
  if (t != 0 && t != 1) t = (float) (1.0 / sqrt(t));
  return [[Vector3D alloc] initWithX:A->x * t Y:A->y * t Z:A->z * t];
}
// Compares two points in 3D
// @return Negative if this down or left of P,
// Positive if this up or right of P, 0 equals
- (float)compareToWithVector3D:(Vector3D *)p {
  return [self compareToWithFloat:p->x withFloat:p->y withFloat:p->z];
}
// Return 0 if Point is near x,y,z
- (float)compareToWithFloat:(float)xc
                  withFloat:(float)yc
                  withFloat:(float)zc {
  float dx2 = (float) fabs((x - xc) * (x - xc));
  float dy2 = (float) fabs((y - yc) * (y - yc));
  float dz2 = (float) fabs((z - zc) * (z - zc));
  float d = (float) sqrt(dx2 + dy2 + dz2);
  if (d > 3) // Points closer than 3 pixels are considered the same
    return d;
  else
    return 0.0f;
}

@end
