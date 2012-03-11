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

@interface Simulation :  NSObject
{
	int frames;
	float speedModifier;
	CollideableMesh *mesh;
    CATransform3D currentCalculatedMatrix;
	BOOL isAutorotating;
	BOOL isFirstDrawingOfMolecule, isFrameRenderingFinished;
	//CADisplayLink *displayLink;
	CFTimeInterval previousTimestamp;
	BOOL shouldResizeDisplay;
    
	NSUInteger stepsSinceLastRotation;
    double _modelScale;
    double _minimumZoomScale;
    double _maxZoomScale;
    double _tilt,_targetTilt;
    NSTimeInterval _dt;
    double _targetDistance;
    double _zoomStartDist;
    double       _distance;
	UIInterfaceOrientation interfaceOrientation;

    //void Pan(float x,float y);
//    void Zoom(float percent);
    double _panKeyDist,_cameraPanAcceleration;
    double   _center[3];
	double  _targetCenter[3];
   // void SlerpToTargetOrientation(double percent);
  	double _targetHeading;
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


}

- (void)mouseDragged:(vector2f)delta withFlags:(uint32_t)flags;
- (void)scrollWheel:(float)delta;
- (void)dealloc;
- (void)clearObjs;

- (void)update;
- (void)render;
- (void)resetCamera;
- (bool)isDoneMoving;
- (void)apply3DTransformD:(CATransform3D *)transform3D toPoint:(double *)sourcePoint result:(double *)resultingPoint;


- (void)SlerpToTargetOrientation:(float) percent;
-(void) pan: (CGPoint)pt;
-(void) zoomcont: (float) percent;
-(void) zoomstart;
-(void) orient: (CGPoint) pt;
-(void) setRenderMode: (GLVisualizationType) rt;
-(GLVisualizationType) getRenderMode;
- (id)initwithstring:(NSString*) name;
-(void) zoomval: (float) percent;

@end
