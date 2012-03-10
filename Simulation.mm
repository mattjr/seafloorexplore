//
//  Simulation.m
//  VTDemo
//
//  Created by Julian Mayer on 31.07.09.
/*	Copyright (c) 2010 A. Julian Mayer
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "Simulation.h"
#include "LibVT.h"
#include "LibVT_Internal.h"
float positions[60 * 60][6];
#include <math.h>

#define PLAY_DEMO		0
//#define FIXED_TILES_PATH   // either load from a specific directory or from where the binary is

#ifdef FIXED_TILES_PATH
#ifdef WIN32
#define TILES_BASEPATH	@"C:\\"
#else
#define TILES_BASEPATH	@"/Users/julian/Documents/Development/VirtualTexturing/_texdata/"
#endif
#else
#ifndef TARGET_OS_IPHONE
#define TILES_BASEPATH  [[[NSBundle mainBundle] bundlePath] stringByDeletingLastPathComponent]
#else
#define TILES_BASEPATH  [[[NSBundle mainBundle] bundlePath] stringByAppendingPathComponent:@""]
#endif
#endif


@implementation Simulation

- (id)initwithstring:(NSString*) name
{
	if ((self = [super init]))
	{
		//GLuint bla = LoadTexture(@"/Users/julian/Documents/Development/VirtualTexturing/_texdata_sources/texture_8k.png", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_TRUE, 2.0);

		//globalSettings.disableTextureCompression = YES;

		interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

#ifndef TARGET_OS_IPHONE
//		Light *light = [[[Light alloc] init] autorelease];
//		[light setPosition:vector3f(300, 300, 0)];
//		[light setLightAmbient:vector4f(0.7, 0.7, 0.7, 1.0)];
//		[[scene lights] addObject:light];
#endif

		[[scene camera] setAxisConfiguration:AXIS_CONFIGURATION(kXAxis, kYAxis, kZAxis)];
		[[scene camera] setFarPlane:20000];
		[[scene camera] setNearPlane:0.5];
		renderMode=TEXTURED;
        NSString *filename = [[name lastPathComponent] stringByDeletingPathExtension];	

        NSString *dataName = [NSString stringWithFormat:@"%@/%@.vtex",name,filename] ;
        //NSLog(@"%@\n",dataName);
		mesh = [[CollideableMesh alloc] initWithOctreeNamed:[NSString stringWithFormat:@"%@/%@", name,filename]];
        if(mesh == nil)
            return nil;
		char ext [5] = "    ";
        uint8_t border, length;
        uint32_t dim;
     

        bool success = vtScan([dataName UTF8String], ext, &border, &length, &dim);
        
        if (success)
        {
#if (LONG_MIP_CHAIN)
            if (length > 9)
#else
			if ((length > 0) && (length <= 9))
#endif
			{

				vtnode = [[VirtualTexturingNode alloc] initWithTileStore:dataName format:[NSString stringWithUTF8String:ext] border:border miplength:length tilesize:dim];
			}
			else
			{
				printf("Error: %s not same MIPMAPCHAINLENGTH mode as binary.", [dataName UTF8String]);
				return NULL;
			}
        }
		else
		{
			printf("Error: %s not a valid tile store", [dataName UTF8String]);
            return NULL;
		}

    /*for (int i = 0; i < 1; i++)
		{

        //Mesh *b = [[[Mesh alloc] initWithOctreeNamed:[NSString stringWithFormat:@"%i_bo_lod1", i]] autorelease]; // got to use only the low NY mesh if we want to run on 512er cards, for 1024 we can use both and to LoD
        //Mesh *b = [[[Mesh alloc] initWithOctreeNamed:[NSString stringWithFormat:@"%i_bo_128", i]] autorelease];
        //Mesh *b = [[[Mesh alloc] initWithOctreeNamed:[NSString stringWithFormat:@"%i_bo", i]] autorelease];
        
        LODNode *b = [[LODNode alloc] initWithOctreesNamed:[NSArray arrayWithObjects:[NSString stringWithFormat:@"%i_bo", i], [NSString stringWithFormat:@"%i_bo_lod1", i], nil] andFactor:1.1];
        [[vtnode children] addObject:b];
        }
        */
		[[vtnode children] addObject:[mesh autorelease]];
		[vtnode setZRange: [mesh zbound]];
		[[scene objects] addObject:[vtnode autorelease]];

//		[[scene objects] addObject:mesh];
//		glActiveTexture(GL_TEXTURE0 + 5);
//		glEnable(GL_TEXTURE_2D);
//
//		((Mesh *)mesh)->texName = bla;  // this is only if we want to use a normal texture instead for performance testing
//
//		glActiveTexture(GL_TEXTURE0);


#ifndef WIN32
		/*Skybox *skybox = [[Skybox alloc] initWithSurroundTextureNamed:@"north_east_south_west"];
		[skybox setSize:11000 ];
		[[scene objects] addObject:skybox];*/
#endif
#ifdef DISABLE_VBL_AND_BENCH
	//	globalSettings.disableVBLSync = YES;
#else
#ifndef WIN32
		[NSTimer scheduledTimerWithTimeInterval:1.0 target:self selector:@selector(fpstimer) userInfo:NULL repeats:YES];
#endif
#endif
		if (0)
			[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(recordPositionTimer) userInfo:NULL repeats:YES];

		if (PLAY_DEMO)
		{
			void *pos = vtuLoadFile([[[NSBundle mainBundle] pathForResource:@"positions" ofType:@"bin"] UTF8String], 0, NULL);

			memcpy(&positions, pos, sizeof(positions));

			[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(updateTimer) userInfo:NULL repeats:YES];
		}
		
		orientation.m11=0;
		orientation.m12=1;
		orientation.m13=0;
		orientation.m14=0;
		
		
		orientation.m21=1;
		orientation.m22=0;
		orientation.m23=0;
		orientation.m24=0;
		
		orientation.m31=0;
		orientation.m32=0;
		orientation.m33=-1;
		orientation.m34=0;
		
		orientation.m41=0;
		orientation.m42=0;
		orientation.m43=0;
		orientation.m44=1;
		

		speedModifier = 1.0;
        // Set to either Inertia or Standard slerp value
        _cameraSlerpPercentage = 0.004f;
        _cameraPanAcceleration = 30.0;
        _panKeyDist=0.005;
        _minimumZoomScale = 0.5f;
        _maxZoomScale = 20000.0f;
        _minalt=0.0;
        _tilt=0.0;
        _targetTilt= 0.0;
        cameraRotationSpeed = 0.01;
		_heading=0.0;
		_targetHeading=0.0;
		vector3f tmp= [mesh center];
		_center[0] = -tmp[0];
		_center[1] = -tmp[1];
		_center[2] = -tmp[2];
		_distance = 3*[mesh radius];
		[self resetCamera];
        _firstPan=false;
        _radius = [mesh radius];
       
	}
	return self;
}

- (void)recordPositionTimer
{
	static int times = 0;

	if (times < 60 * 60)
	{
		vector3f pos = [[scene camera] position];
		vector3f rot = [[scene camera] rotation];

		positions[times][0] = pos[0];
		positions[times][1] = pos[1];
		positions[times][2] = pos[2];
		positions[times][3] = rot[0];
		positions[times][4] = rot[1];
		positions[times][5] = rot[2];
	}
	if (times == 60 * 60)
	{
		FILE * pFile;
		pFile = fopen ( "/Users/julian/Desktop/positions.bin" , "wb" );
		fwrite (positions , 1 , sizeof(positions) , pFile );
		fclose (pFile);
	}
	times++;
}

- (void)fpstimer
{
	globalInfo.fps = frames;
	frames = 0;
}

- (void)updateTimer
{
	if (PLAY_DEMO)
	{
		static int times = 0;

		if (times < 60 * 60)
		{
			[[scene camera] setPosition:vector3f(positions[times][0], positions[times][1], positions[times][2])];
			[[scene camera] setRotation:vector3f(positions[times][3], positions[times][4], positions[times][5])];
		}
		else
		{
			vtShutdown();
			exit(1);
		}

		times++;

	}
}

- (void)update
{
#ifdef WIN32
	[self updateTimer];
#endif
}
- (bool)isDoneMoving{
	double eps = 0.0001;
	return (fabs(_center[0]-_targetCenter[0])<eps &&fabs(_center[1]-_targetCenter[1])<eps &&fabs(_center[2]-_targetCenter[2])<eps &&fabs(_targetTilt-_tilt) < eps && fabs(_targetHeading- _heading));	
}

- (void)render
{
    _dt = [NSDate timeIntervalSinceReferenceDate] - startTime;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    [self SlerpToTargetOrientation: _cameraSlerpPercentage];
	frames++;

 CATransform3D mTmp;
 CATransform3D tiltMat;
 CATransform3D headingMat;
	
	
headingMat= CATransform3DMakeRotation(_heading * M_PI / 180.0,0,0,1);
 if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
 tiltMat=CATransform3DMakeRotation(-_tilt * M_PI / 180.0,1,0,0);
 else if(interfaceOrientation == UIInterfaceOrientationPortrait)
 tiltMat=CATransform3DMakeRotation(-_tilt * M_PI / 180.0,0,1,0); 
 _invMat=CATransform3DMakeTranslation(_center[0],_center[1],_center[2]);

_invMat= CATransform3DConcat(_invMat,orientation);
_invMat= CATransform3DConcat(_invMat,headingMat);
 
 _invMat=CATransform3DConcat(_invMat,tiltMat);
 
mTmp= CATransform3DMakeTranslation(0,0,-_distance);
_invMat= CATransform3DConcat(_invMat,mTmp);

    CGPoint pt;

   	for (NSString *keyHit in pressedKeys)
	{
		switch ([keyHit intValue])
		{
			case 's':
                pt.x=0;
                pt.y=-_panKeyDist;
                [self pan: pt];

                break;
			case 'w':
                pt.x=0;
                pt.y=_panKeyDist;
                [self pan: pt];

				break;
			case 'a':
                pt.x=_panKeyDist;
                pt.y=0;
                [self pan: pt];
				break;
			case 'd':
                pt.x=-_panKeyDist;
                pt.y=0;
                [self pan: pt];
				break;
            case 'q':
                [self zoomval: 0.1];
				break;
            case 'e':
                [self zoomval: -0.1];
				break;
                case ' ':
                [self resetCamera];
                break;

		}
	}

	/*
#define DIST 1.0f
	matrix33f_c m;
	matrix_rotation_euler(m, cml::rad([[scene camera] rotation][0]), cml::rad([[scene camera] rotation][1]), cml::rad([[scene camera] rotation][2]), cml::euler_order_xyz);
	movement = transform_vector(m, movement);
	vector3f npos = [[scene camera] position] + (movement * speedModifier / 1.0);

   // [[scene camera] setPosition:npos];


	if (!PLAY_DEMO)
	{
	vector3f intersectionPoint = [mesh intersectWithLineStart:vector3f(npos[0], npos[1] - DIST, npos[2]) end:vector3f(npos[0], 1000, npos[2])];

	if (intersectionPoint[1] != FLT_MAX)
		npos = vector3f(npos[0], intersectionPoint[1] + DIST, npos[2]);
	}
     */
    matrix44f_c data;
    memcpy(data.data(),&_invMat.m11,sizeof(float)*16);
   // [self printMatrix:data.data()];
	[[scene camera] load:data];
 
   // [self printMatrix:[[scene camera] modelViewMatrix].data()];

}

- (void)mouseDragged:(vector2f)delta withFlags:(uint32_t)flags
{
	/*vector3f rot = [[scene camera] rotation];

	 rot[1] -= delta[0] / 10.0;
	 rot[0] -= delta[1] / 10.0;

	 [[scene camera] setRotation:rot];*/
//    [self pan: delta[0] / 2000.0 andY:delta[1] / 2000.0 ];

}

#if !TARGET_OS_IPHONE && !defined(linux)
- (void)rightMouseUp:(NSEvent *)event
{
	speedModifier = 1.0;
}
#endif

- (void)scrollWheel:(float)delta
{
 //   float val=delta/10.0;
 //   [self zoom: val];

}
- (void)apply3DTransformD:(CATransform3D *)transform3D toPoint:(double *)sourcePoint result:(double *)resultingPoint;
{
		
    resultingPoint[0] = sourcePoint[0] * transform3D->m11 + sourcePoint[1] * transform3D->m12 + sourcePoint[2] * transform3D->m13 + transform3D->m14;
    resultingPoint[1] = sourcePoint[0] * transform3D->m21 + sourcePoint[1] * transform3D->m22 + sourcePoint[2] * transform3D->m23 + transform3D->m24;
    resultingPoint[2] = sourcePoint[0] * transform3D->m31 + sourcePoint[1] * transform3D->m32 + sourcePoint[2] * transform3D->m33 + transform3D->m34;
}

-(void) pan: (CGPoint) pt
{
	
    /*pt1.x=-1;
    pt1.y=-1;
    pt2.x=1;
    pt2.y=1;*/
    vector3f ptsrc1; 
    ptsrc1[0]=0.0;
    ptsrc1[1]=0.0;
    ptsrc1[2]=180.0;
    
    CATransform3D invMat= orientation;
    
    CATransform3D mTmp= CATransform3DMakeTranslation(0,0,-_distance);
    invMat= CATransform3DConcat(invMat,mTmp);
    matrix44f_c data;
    memcpy(data.data(),&invMat.m11,sizeof(float)*16);
    
    matrix44f_c mvp([[scene camera] projectionMatrix] *data);
    vector4f v1,v2;
    v1[0]= -_radius;
    v1[1]= -_radius;
    v1[2]= -_radius;
    v1[3]=1.0;
    
    v2[0]= _radius;
    v2[1]= _radius;
    v2[2]= _radius;
    v2[3]= 1.0;
    
    v1=v1*mvp;
    
    
    v2=v2*mvp;
    
    v1[0]/=v1[3];
    v1[1]/=v1[3];
    v1[2]/=v1[3];
    
    
    v2[0]/=v2[3];
    v2[1]/=v2[3];
    v2[2]/=v2[3];
    
    CGPoint r;
    r.x=fabs(v1[0]-v2[0]);
    r.y=fabs(v1[1]-v2[1]);
    if(!_firstPan){
        ranges=r;
        _firstPan=true;
    }
  //  printf("Original %f %f Ratio %f %f\n",r.x,r.y,r.x/ranges.x,(3*[mesh radius])/_distance);
    
    CGPoint ratio;
    ratio.x=ranges.x/r.x;
    ratio.y=ranges.x/r.y;
    
    ratio.x*=pt.x*(3*_radius);
      ratio.y*=pt.y*(3*_radius); 
   // printf("Range X:%f Y:%f\n",ratio.x,ratio.y);
  //  float scale = _cameraPanAcceleration*_distance;
    double zratio=((1.0-((_distance/(3*_radius))))/2.0) + 0.5;	
    
	CATransform3D headingMat;
	headingMat=CATransform3DMakeRotation(-_heading * M_PI / 180.0,0,0,1);
	double pt_trans[3];
	pt_trans[0]=ratio.x;//pt.x*scale;
	pt_trans[1]=ratio.y;//pt.y*scale;
	pt_trans[2]=0;
	  
	double pt_out[3];
	[self apply3DTransformD:&headingMat toPoint:pt_trans result:pt_out];
    
    double tmpCenter[2];
    vector3f tmp= [mesh center];
    
    tmpCenter[0]=( _targetCenter[0]+ pt_out[0])+tmp[0];
    tmpCenter[1]= (_targetCenter[1]+ pt_out[1])+tmp[1];
    double mult=1.0;
    zratio=std::max(0.5,zratio);
   // printf("zratio %f dist %f limit %f curr %f %f\n",zratio,_distance, (zratio*mult)*_radius,tmpCenter[0]+tmp[0],tmpCenter[1]+tmp[1]);
    if(tmpCenter[0] >  -(zratio*mult)*_radius && tmpCenter[0] <  (zratio*mult)*_radius  && tmpCenter[1] >  -(zratio*mult)*_radius&&
       tmpCenter[1] < (zratio*mult)*_radius )
    
    {
       
        _targetCenter[0]= tmpCenter[0]-tmp[0];
        _targetCenter[1]= tmpCenter[1]-tmp[1];
    }
	
}
-(void) orient: (CGPoint) pt
{
    
    float tiltAngleOffset=5.0;
	double headingVal,tiltVal;
    // Heading
	if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
		headingVal=pt.y;
		tiltVal= -(pt.x);
	}
	else{
		headingVal=pt.x;
		tiltVal= -pt.y;
	}
	
    double headingDelta = ( headingVal *50*cameraRotationSpeed);
     _targetHeading += -headingDelta;
	// tilt
    double tiltDelta = (tiltVal*100* cameraRotationSpeed);
    _targetTilt += tiltDelta;
    if(_targetTilt >= 90 - tiltAngleOffset)
        _targetTilt = 90.0-tiltAngleOffset;
    if(_targetTilt <= 0.0)
        _targetTilt = 0.0;
}
-(void) zoomval: (float) percent
{
    //  if(percent > 0)
    //RecomputeTerrainIntersection();
    double tmp=_targetDistance;
    if(percent>0){
        tmp /= 1.0f + percent;
        if(tmp < _minimumZoomScale + _minalt)
            return;
    }
    else{
        
        tmp *= 1.0f - percent;
        
    }
    if(tmp < _minimumZoomScale || tmp > _maxZoomScale)
        return;
    else
        _targetDistance =tmp;
    
}


-(void) zoomcont: (float) percent
{
  
    //  if(percent > 0)
    //RecomputeTerrainIntersection();
    float tmp=_zoomStartDist;
        tmp *= 1+percent*2.0;
   // printf("Zoom dist %f %f\n",tmp,percent);

    if(tmp < _minimumZoomScale + _minalt|| tmp > _maxZoomScale)
        return;
    else
        _targetDistance = std::min((double)tmp,  _radius *4.0);
            
    
}
- (void)resetCamera
{
        
	[[scene camera] setPosition:vector3f(10, 1, 0)]; 
    [[scene camera] setRotation:vector3f(-90, 0, 0)];
 
 

    for(int i=0; i <3; i++){
	_targetCenter[i]=_center[i];
	}
    _targetDistance=_distance;
	
    _tilt=0.0;
    _targetTilt= 0.0;
	_heading=0.0;
	_targetHeading=_heading;
    startTime = [NSDate timeIntervalSinceReferenceDate];

}
-(void) zoomstart{
    _zoomStartDist=_distance;
   // printf("Starting Dist %f\n",_distance);
}

- (void)SlerpToTargetOrientation:(float) percent{
    
    
    percent *= _dt*1000;
    if(percent > 1.0)
        percent=1.0;
    _tilt += (_targetTilt - _tilt)*percent;
    _distance += (_targetDistance - _distance)*percent;
	for(int i=0; i<3; i++)
		_center[i] += ( _targetCenter[i] -_center[i])*percent;
	_heading += ( _targetHeading -_heading)*percent;

}
-(void) setRenderMode: (GLVisualizationType) rt{
	renderMode =rt;
	[vtnode setRenderMode: renderMode];
}

-(GLVisualizationType) getRenderMode{
	return renderMode;
}



@end
