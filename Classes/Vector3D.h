// A simple vector to hold 3 coordinates
// x, y, z float values

@interface Vector3D : NSObject {
 @public
  float x, y, z;
}

- (id)initWithX:(float)x
          Y:(float)y
          Z:(float)z;
- (id)initWithVector3D:(Vector3D *)v;
- (void)setWithX:(float)x
           Y:(float)y
           Z:(float)z;
- (void)setWithVector3D:(Vector3D *)v;
- (void)moveToWithVector3D:(Vector3D *)p;
- (Vector3D *)scaleWithFloat:(float)t;
- (Vector3D *)scaleThisWithFloat:(float)t;
- (Vector3D *)newTo:(Vector3D *)B;
- (Vector3D *)addWithVector3D:(Vector3D *)A;
- (Vector3D *)addToThisWithVector3D:(Vector3D *)A;
- (Vector3D *)subToThisWithVector3D:(Vector3D *)A;
- (float)dotWithVector3D:(Vector3D *)B;
- (float)dotWithFloat:(float)Bx
            withFloat:(float)By
            withFloat:(float)Bz;
+ (float)dotWithVector3D:(Vector3D *)A
            withVector3D:(Vector3D *)B;
- (Vector3D *)crossWithVector3D:(Vector3D *)B;
- (Vector3D *)crossWithFloat:(float)Bx
                       withFloat:(float)By
                       withFloat:(float)Bz;
+ (Vector3D *)crossWithVector3D:(Vector3D *)A
                       withVector3D:(Vector3D *)B;
+ (float)scalarTripleWithVector3D:(Vector3D *)A
                     withVector3D:(Vector3D *)B
                     withVector3D:(Vector3D *)C;
- (float)length;
- (float)lengthSquared;
+ (float)lengthWithVector3D:(Vector3D *)A;
- (void)normalize;
+ (Vector3D *)normalizeWithVector3D:(Vector3D *)A;
- (float)compareToWithVector3D:(Vector3D *)p;
- (float)compareToWithFloat:(float)x
                  withFloat:(float)y
                  withFloat:(float)z;
@end
