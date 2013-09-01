// Model to hold Points, Segments, Faces

@class OrFace;
@class Plane;
@class OrPoint;
@class Segment;
@class Vector3D;

#define Model_serialVersionUID 1

@interface Model : NSObject {
  
 @public
  NSMutableArray *points, *faces, *segments;
  int idPoint, idSegment, idFace;
  
 @private
  float currentScale;
}

- (id)init;
- (void)reinit;
- (void)initWithFloat:(float)x0
              withFloat:(float)y0
              withFloat:(float)x1
              withFloat:(float)y1
              withFloat:(float)x2
              withFloat:(float)y2
              withFloat:(float)x3
              withFloat:(float)y3 ;
- (OrPoint *)addPointWithFloat:(float)x
                       withFloat:(float)y;
- (OrPoint *)addPointWithOrPoint:(OrPoint *)pt;
- (void)addSegmentWithOrPoint:(OrPoint *)p1
                           withOrPoint:(OrPoint *)p2
                                 withInt:(int)type;
- (void)addFace:(OrFace *)f;
- (void)splitSegmentWithSegment:(Segment *)s
                          withFloat:(float)k;
- (void)splitAcrossWithOrPoint:(OrPoint *)p1
                   withOrPoint:(OrPoint *)p2
                withList:list;
- (void)splitByWithOrPoint:(OrPoint *)p1
               withOrPoint:(OrPoint *)p2
            withList:list;
- (void)splitOrthoWithSegment:(Segment *)s
                    withOrPoint:(OrPoint *)p
                 withList:list;
- (void)splitLineToLineWithOrPoint:(OrPoint *)p0
                       withOrPoint:(OrPoint *)p1
                       withOrPoint:(OrPoint *)p2
                    withList:list;
- (void)splitLineToLineWithSegment:(Segment *)s1
                       withSegment:(Segment *)s2
                      withList:list;
- (void)splitSegmentCrossingWithSegment:(Segment *)s1
                            withSegment:(Segment *)s2;
- (void)splitSegmentOnPointWithSegment:(Segment *)s1
                             withOrPoint:(OrPoint *)p;
- (void)splitSegmentWithSegment:(Segment *)s
                      withOrPoint:(OrPoint *)p;
- (void)splitFacesByPlaneWithPlane:(Plane *)pl
                      withList:list;
- (void)rotateWithSegment:(Segment *)s
                    withFloat:(float)angle
             withList:list;
- (void)turnWithFloat:(float)angle
              withInt:(int)axe;
- (float)adjustwithList:list;
- (float)adjustSegmentsWithOrPoint:(OrPoint *)p
                    withList:segs;
- (float)adjustWithOrPoint:(OrPoint *)p
            withList:segments;
- (void)selectPtsWithList:pts;
- (void)selectSegsWithList:segs;
- (void)moveBydx:(float)dx
            dy:(float)dy
            dz:(float)dz
     withList:pts;
- (void)moveOnWithOrPoint:(OrPoint *)p0
                  withFloat:(float)k1
                  withFloat:(float)k2
           withList:pts;
- (void)moveOnLineWithSegment:(Segment *)s
                        withFloat:(float)k1
                        withFloat:(float)k2
                 withList:pts;
- (void)flatWithList:pts;
- (void)offsetWithFloat:(float)dz
       withList:lf;
- (void)offsetDecalWithFloat:(float)dcl
            withList:list;
- (void)offsetAddWithFloat:(float)dz
          withList:list;
- (void)offsetMulWithFloat:(float)k
          withList:list;
- (void)offsetBetweenwithList:list;
- (void)splitFaceByPlaneWithFace:(OrFace *)f1
                       withPlane:(Plane *)pl;
- (OrPoint *)addPointToJointFaceWithFace:(OrFace *)f
                              withVector3D:(Vector3D *)i
                                 withOrPoint:(OrPoint *)a
                                 withOrPoint:(OrPoint *)b;
- (void)align2dFrom3dWithOrPoint:(OrPoint *)pb
                   withSegment:(Segment *)s;
- (float)computeAngleWithSegment:(Segment *)s;
- (OrFace *)faceRightWithOrPoint:(OrPoint *)a
                       withOrPoint:(OrPoint *)b;
- (OrFace *)faceLeftWithOrPoint:(OrPoint *)a
                      withOrPoint:(OrPoint *)b;
- (OrFace *)searchFaceWithSegment:(Segment *)s
                           withFace:(OrFace *)f0;
- (Segment *)searchSegmentWithOrPoint:(OrPoint *)a
                              withOrPoint:(OrPoint *)b;
- searchSegmentsListWithOrPoint:(OrPoint *)a;
- (float *)get2DBounds;
- (void)zoomFit;
- (void)scaleModelWithFloat:(float)scale;
- (float *)get3DBounds;
- (NSData *)getSerialized;
- (NSString *)description;
@end
