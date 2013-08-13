//
//  source: src/rk/or/Interpolator.java
//
//  Created by remi on 10/05/13.
//
@class Interpolator ;

@interface Interpolator : NSObject 
+ (float) interpolate:(float)t;
+ (void) choose:(float (*)(float))ptf;
@end

// Different kinds of interpolators
float LinearInterpolator(float t);
float AccelerateDecelerateInterpolator(float t);
float SpringOvershootInterpolator(float t);
float SpringBounceInterpolator(float t);
float GravityBounceInterpolator(float t);
float BounceInterpolator(float t);
float OvershootInterpolator(float t);
float AnticipateInterpolator(float t);
float AnticipateOvershootInterpolator(float t);