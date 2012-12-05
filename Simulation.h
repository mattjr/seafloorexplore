//
//  Simulation.h
//  VTDemo
//
//  Created by Julian Mayer on 31.07.09.
/*	Copyright (c) 2010 A. Julian Mayer
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "Core3D.h"
#import "VirtualTexturingNode.h"
#import "LODNode.h"
#import "Skybox.h"
#import "CollideableMesh.h"
typedef enum { TEXTURED,SHADED, } GLVisualizationType;
@class Scene;
typedef enum {
    kNoLog,
    kPanning,
    kZoom,
    kTilt,
    kDoubleClick,
} MovementType;
@interface Simulation :  NSObject
{
	int frames;
	float speedModifier;
	NSMutableArray *meshes;
    CATransform3D currentCalculatedMatrix;
	BOOL isAutorotating;
	BOOL isFirstDrawingOfModel, isFrameRenderingFinished;
	//CADisplayLink *displayLink;
	CFTimeInterval previousTimestamp;
	BOOL shouldResizeDisplay;
    
	NSUInteger stepsSinceLastRotation;
    double _modelScale;
    double _minimumZoomScale;
    double _maxZoomScale;
    double _tilt,_targetTilt,_lastValidTilt;
    NSTimeInterval _dt;
    double _targetDistance;
    double _zoomStartDist;
    double       _distance;
    vector4f _unprojected_orig;
	//UIInterfaceOrientation interfaceOrientation;

    //void Pan(float x,float y);
//    void Zoom(float percent);
    double _panKeyDist,_cameraPanAcceleration;
    double   _center[3];
	double  _targetCenter[3];
    double  _lastValidCenter[3];
    double _lastValidDist;
    vector3f bbox[2];
    BOOL goneOutOfFrame;
   // void SlerpToTargetOrientation(double percent);
  	double _targetHeading,_lastValidHeading;
	double _heading;
    	CATransform3D _invMat;
	CATransform3D orientation;
    NSTimeInterval startTime;
    double _cameraSlerpPercentage;
   double _minalt;
    float cameraRotationSpeed;
    bool _invertMouse;
	GLVisualizationType renderMode;
	VirtualTexturingNode *vtnode;
    CGPoint ranges;
    bool _firstPan;
    double _radius;
    double lastValidCenter[3];
    vector3f _meshcent;
    bool donePanning;
    vector3f extentsMesh;
    CGPoint _lastPt;
    float _maxDist;
    Scene *scene;
    MovementType logOnNextUpdate;
    NSArray *movementStrings;
    NSString *basename;
    
}
@property (atomic)     MovementType logOnNextUpdate;


-(void) centeratPt: (CGPoint) pt;
- (void)mouseDragged:(CGPoint)pos withFlags:(uint32_t)flags;
- (void)scrollWheel:(float)delta;
- (void)dealloc;
- (void)clearObjs;


- (void)update;
- (void)render;
- (void)resetCamera;
- (bool)isDoneMoving;
- (void)apply3DTransformD:(CATransform3D *)transform3D toPoint:(double *)sourcePoint result:(double *)resultingPoint;
- (void)apply3DTransform:(CATransform3D *)transform3D toPoint:(vector3f)sourcePoint result:(vector3f)resultingPoint;
- (id)initWithString:(NSString *)name withScene:(Scene *)newscene;

- (void)SlerpToTargetOrientation:(float) percent;
-(void) pan: (CGPoint)pt;
-(void) zoomcont: (float) percent;
-(void) zoomstart ;
-(void) orient: (CGPoint) pt;
-(void) setRenderMode: (GLVisualizationType) rt;
-(GLVisualizationType) getRenderMode;
-(void) panstart: (CGPoint) pt;
-(void) pancont: (CGPoint)pt;
- (void)printMatrix:(GLfloat *)matrix;

-(void)logCameraPosition:(MovementType)type ;

-(void)setValidPos;
-(void) checkInFrame;
-(vector3f) center;
-(float) radius;
-(vector3f) minbb;
-(vector3f) maxbb;
- (CC3Plane)centeredPlane;
-(BOOL) intersectOctreeNodeWithRay:(int)nodeNumber withRay:(CC3Ray)ray inter:(float *)pt;
matrix44f_c CATransform3DSetField(CATransform3D transform );

-(BOOL)anyTrianlgesInFrustum:(const GLfloat [6][4])frustum;
-(vector4f)pickPt:(Camera *)cam pick:(CGPoint)pt;

@end
