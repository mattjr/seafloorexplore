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
#import "Core3D.h"

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
- (id)initWithString:(NSString *)name
{
    self = [super init];
    if (self)
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
        _maxZoomScale =  6*[mesh radius];
        _minalt=0.0;
        cameraRotationSpeed = 0.01;
        _maxDist = 3.5*[mesh radius];

		
		[self resetCamera];
        _firstPan=false;
        _radius = [mesh radius];
        donePanning=true;
        bbox[0]=[mesh minbb];
        bbox[1]=[mesh maxbb];
        extentsMesh=bbox[1]-bbox[0];
        _meshcent =[mesh center];

    }
    return self;
}

- (void)dealloc
{
   // [vtnode release];
    [[scene objects] removeObject:vtnode];
	[super dealloc];
}
- (void)clearObjs
{
    [[scene objects] removeObject:vtnode];

    
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
	double eps = 0.1;
	return (fabs(_center[0]-_targetCenter[0])<eps &&fabs(_center[1]-_targetCenter[1])<eps &&fabs(_center[2]-_targetCenter[2])<eps &&fabs(_targetTilt-_tilt) < eps && fabs(_targetHeading- _heading)<eps);	
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
   // printf("%d %d\n",[self isDoneMoving] , goneOutOfFrame);
    if(goneOutOfFrame && ![mesh anyTrianlgesInFrustum:frustum]){
        _targetCenter[0]=_lastValidCenter[0];
       _targetCenter[1]=_lastValidCenter[1];
       _targetCenter[2]=_lastValidCenter[2];
       _targetDistance=_lastValidDist;
       _targetTilt =_lastValidTilt;
       _targetHeading=_lastValidHeading;
    }

   
}
-(void)setValidPos{
    _lastValidCenter[0]=_center[0];
    _lastValidCenter[1]=_center[1];
    _lastValidCenter[2]=_center[2];
    _lastValidDist=_distance;
    _lastValidTilt=_tilt;
    _lastValidHeading=_heading;
    goneOutOfFrame=NO;
}
-(void) checkInFrame{
    CATransform3D mTmp;
    CATransform3D tiltMat;
    CATransform3D headingMat;
	CATransform3D viewtest;
	
    headingMat= CATransform3DMakeRotation(_targetHeading * M_PI / 180.0,0,0,1);
    if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        tiltMat=CATransform3DMakeRotation(-_targetTilt * M_PI / 180.0,1,0,0);
    else if(interfaceOrientation == UIInterfaceOrientationPortrait)
        tiltMat=CATransform3DMakeRotation(-_targetTilt * M_PI / 180.0,0,1,0); 
    viewtest=CATransform3DMakeTranslation(_targetCenter[0],_targetCenter[1],_targetCenter[2]);
    
    viewtest= CATransform3DConcat(viewtest,orientation);
    viewtest= CATransform3DConcat(viewtest,headingMat);
    
    viewtest=CATransform3DConcat(viewtest,tiltMat);
    
    mTmp= CATransform3DMakeTranslation(0,0,-_targetDistance);
    viewtest= CATransform3DConcat(viewtest,mTmp);
    
    GLfloat test_frustum[6][4];
    
    matrix44f_c data;
    memcpy(data.data(),&(viewtest.m11),sizeof(float)*16);

    extract_frustum_planes(data,[[scene camera] projectionMatrix], test_frustum, cml::z_clip_neg_one, false);
    

    if(![mesh anyTrianlgesInFrustum:test_frustum]){
        goneOutOfFrame=YES;
     //   printf("Not in frame\n");

    }else {
       // printf("Still in\n");
    }
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

- (void)apply3DTransform:(CATransform3D *)transform3D toPoint:(vector3f)sourcePoint result:(vector3f)resultingPoint;
{
    
    resultingPoint[0] = sourcePoint[0] * transform3D->m11 + sourcePoint[1] * transform3D->m12 + sourcePoint[2] * transform3D->m13 + transform3D->m14;
    resultingPoint[1] = sourcePoint[0] * transform3D->m21 + sourcePoint[1] * transform3D->m22 + sourcePoint[2] * transform3D->m23 + transform3D->m24;
    resultingPoint[2] = sourcePoint[0] * transform3D->m31 + sourcePoint[1] * transform3D->m32 + sourcePoint[2] * transform3D->m33 + transform3D->m34;
}

-(void) pan: (CGPoint) pt
{
       // pt.x=(globalInfo.width/2)+0;
   // pt.y=(globalInfo.height/2)+0;
   // printf("Dist %f %f\n",_center[2],_distance);
    vector3f v1=vector3f(_unprojected_orig[0],_unprojected_orig[1],_unprojected_orig[2]);
    vector3f v2=vector3f(_unprojected_orig[0]+1,_unprojected_orig[1],_unprojected_orig[2]);
    vector3f v3=vector3f(_unprojected_orig[0],_unprojected_orig[1]+1,_unprojected_orig[2]);
    
    CC3Plane plane= CC3PlaneFromPoints(v1,v2,v3);
    //CC3Plane plane=[mesh centeredPlane];
    CC3Plane normPlane=CC3PlaneNormalize(plane);
    
    vector4f unprojected_diff =[[scene camera] pick:pt intoMesh: [mesh octree] ];
    if(!isfinite(unprojected_diff[0]))
        unprojected_diff= [[scene camera] unprojectPoint:pt ontoPlane: normPlane];

    vector4f plane_endclick_world= [[scene camera] unprojectPoint:pt ontoPlane: normPlane];

    // Compute world coords of second click
    matrix44f_c ident;
    float winx,winy,winz;
    // Now unproject (just to get z value need later)

    gluProject(plane_endclick_world[0],plane_endclick_world[1],plane_endclick_world[2],
               [[scene camera] modelViewMatrix].data(),[[scene camera] projectionMatrix].data(),[[scene camera] viewport].data(),&winx,&winy,&winz);
  
    //printf("Win %f %f %f\n",winx,winy,winz);
    // Create x
    float x,y,z;
    CGFloat scale = [[UIScreen mainScreen] scale];
    CGPoint glPoint=pt;
    glPoint.x*=scale;
    glPoint.y*=scale;
    glPoint.y=globalInfo.height- glPoint.y;

    if( gluUnProject(glPoint.x,glPoint.y, winz, ident.identity().data(), [[scene camera] projectionMatrix].data(), [[scene camera] viewport].data(), &x, &y, &z) == GL_TRUE) { 
        
    }else{
        printf("Ballz\n");
    }
    //printf("Camera Frame %f %f %f\n",x,y,z);
    float tmpP[4];
    tmpP[0]=x;
    tmpP[1]=y;
    tmpP[2]=z;
    tmpP[3]=1;

    vector3f termX(x,y,z);
  
    // Create rotation-only version of current modelview
    float firstClickWorld[4];
    firstClickWorld[0]=_unprojected_orig[0];
    firstClickWorld[1]=_unprojected_orig[1];
    firstClickWorld[2]=_unprojected_orig[2];
    firstClickWorld[3]=1;
    CATransform3D roationOnlyModelView;
    roationOnlyModelView=_invMat;
    roationOnlyModelView.m41=0;
    roationOnlyModelView.m42=0;
    roationOnlyModelView.m43=0;
    
    float pt_out[4];
    
    // Compute term Y
    __gluMultMatrixVecf(&roationOnlyModelView.m11, firstClickWorld,pt_out);
    vector3f termY(pt_out[0],pt_out[1],pt_out[2]);

    // Create new modelview matrix
    vector3f newT=termX-termY;
    CATransform3D newModel=roationOnlyModelView;
    
    newModel.m41=newT[0];
    newModel.m42=newT[1];
    newModel.m43=newT[2];
   
    CGPoint centerScreenWorld;
    centerScreenWorld.x=(globalInfo.width/2)/scale;
    centerScreenWorld.y=(globalInfo.height/2)/scale;
   // printf("%f %f %f %f\n",pt.x,pt.y,centerScreenWorld.x,centerScreenWorld.y);
    matrix44f_c data;
    memcpy(data.data(),&newModel.m11,sizeof(float)*16);

    CC3Ray ray=[[scene camera] unprojectPoint: centerScreenWorld withModelView:data];
    float intersectionPoint[4];
    intersectionPoint[3]=1;
    if(intersectOctreeNodeWithRay([mesh octree], 0,ray, intersectionPoint))
        ;//printf("Hit %f %f %f\n",intersectionPoint[0],intersectionPoint[1],intersectionPoint[2]);
    else{
       vector4f ret=CC3RayIntersectionWithPlane(ray, plane);// printf("No hit\n");
        intersectionPoint[0]=ret[0];
        intersectionPoint[1]=ret[1];
        intersectionPoint[2]=ret[2];
    }
    __gluMultMatrixVecf(&newModel.m11, intersectionPoint,pt_out);
   // printf("Z pt out %f \n ", pt_out[2]);
   // printf("Distance %f \n ", _distance);
   
    float tmp_targetDistance=-pt_out[2];

   // printf("New model:\n");
   // [self printMatrix:&newModel.m11];

   // printf("termY  %f %f %f\n",termY[0],termY[1],termY[2]);
   // printf("termX %f %f %f\n",termX[0],termX[1],termX[2]);
    
    // Run test
    
   // gluProject(_unprojected_orig[0],_unprojected_orig[1],_unprojected_orig[2],&newModel.m11,g_projMatrix,g_viewport,&winx,&winy,&winz);
 //   printf("Should be u:%f v:%f -- u:%f v:%f\n",winx,globalInfo.height-winy,pt.x,pt.y);

    // Now recover view center from new model matrix
    CATransform3D tiltMat, retMat;
    
    CATransform3D mTmp= CATransform3DMakeTranslation(0,0,tmp_targetDistance);
    CATransform3D headingMat= CATransform3DMakeRotation(-_heading * M_PI / 180.0,0,0,1);
    if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
        tiltMat=CATransform3DMakeRotation(_tilt * M_PI / 180.0,1,0,0);
    else if(interfaceOrientation == UIInterfaceOrientationPortrait)
        tiltMat=CATransform3DMakeRotation(_tilt * M_PI / 180.0,0,1,0); 
    
    // bring camera to center, reverse rotations
    retMat= CATransform3DConcat(newModel,mTmp);
    retMat=CATransform3DConcat(retMat,tiltMat);    
    retMat= CATransform3DConcat(retMat,headingMat);
    
    retMat= CATransform3DConcat(retMat,CATransform3DInvert(orientation));
    
    // extract center point
    vector3f cent(retMat.m41,retMat.m42,retMat.m43);
    vector3f tmpCenter;
    tmpCenter=cent+_meshcent;    
   //  printf("Cen %f %f %f\n",retMat.m41,retMat.m42,retMat.m43);

    if(tmpCenter[0] > -extentsMesh[0] && tmpCenter[0] <  extentsMesh[0]  && tmpCenter[1] >  -extentsMesh[1]&& tmpCenter[1] < extentsMesh[1] )
    {
        
        _targetCenter[0]=cent[0];
        _targetCenter[1]=cent[1];
        _targetCenter[2]=cent[2];
        _targetDistance=tmp_targetDistance;
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
//     printf("Zoom   %f\n",1.0/percent);
    //  if(percent > 0)
    //RecomputeTerrainIntersection();
    float tmp=_targetDistance * 1.0/percent;
   // printf("Zoom   %f\n",tmp);

    //    tmp *= 1+percent*2.0;
   // printf("Zoom dist %f %f\n",tmp,percent);

    if(tmp < _minimumZoomScale + _minalt|| tmp > _maxZoomScale)
        return;
    else
        _targetDistance *= 1.0/percent;// std::min((double)tmp,  _radius *4.0);
    

    
}
-(void) centeratPt: (CGPoint) pt{
    vector4f tmp =[[scene camera] pick:pt intoMesh: [mesh octree] ];
    if(isfinite(tmp[0])){
        _targetCenter[0]=-tmp[0];
        _targetCenter[1]=-tmp[1];
        _targetCenter[2]=-tmp[2];
        _targetDistance =_minalt+3.0;
    }

}
-(void) panstart: (CGPoint) pt{
    CC3Plane plane=[mesh centeredPlane];
    CC3Plane normPlane=CC3PlaneNormalize(plane);
    
    vector4f tmp =[[scene camera] pick:pt intoMesh: [mesh octree] ];
    
    //[[scene camera] unprojectPoint:_lastPt ontoPlane: normPlane];
    if(isfinite(tmp[0]))
       _unprojected_orig=tmp;
    else 
        _unprojected_orig=[[scene camera] unprojectPoint:pt ontoPlane: normPlane];

}
-(void) pancont: (CGPoint) pt
{
    [self panstart: pt];
    //_lastPt=pt;    
    
}
- (void)printMatrix:(GLfloat *)matrix;
{
	NSLog(@"___________________________");
	NSLog(@"|%f,%f,%f,%f|", matrix[0], matrix[1], matrix[2], matrix[3]);
	NSLog(@"|%f,%f,%f,%f|", matrix[4], matrix[5], matrix[6], matrix[7]);
	NSLog(@"|%f,%f,%f,%f|", matrix[8], matrix[9], matrix[10], matrix[11]);
	NSLog(@"|%f,%f,%f,%f|", matrix[12], matrix[13], matrix[14], matrix[15]);
	NSLog(@"___________________________");			
}


- (void)resetCamera
{
        
	//[[scene camera] setPosition:vector3f(10, 1, 0)]; 
    //[[scene camera] setRotation:vector3f(-90, 0, 0)];
    vector3f tmp= [mesh center];
    _center[0] = -tmp[0];
    _center[1] = -tmp[1];
    _center[2] = -tmp[2];
    _distance = 3*[mesh radius];
    _lastValidCenter[0]=_center[0];
     _lastValidCenter[1]=_center[1];
    _lastValidCenter[2]=_center[2];
    for(int i=0; i <3; i++){
	_targetCenter[i]=_center[i];
	}
    _targetDistance=_distance;
    _lastValidDist=_distance;

    _tilt=0.0;
    _targetTilt= _tilt;
	_heading=0.0;
	_targetHeading=_heading;
    startTime = [NSDate timeIntervalSinceReferenceDate];
    for(int i=0;i<3; i++)
        lastValidCenter[i]=_center[i];

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
