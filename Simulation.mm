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
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

#import "Flurry.h"
#endif
#include "LibVT.h"
#include "LibVT_Internal.h"
float positions[60 * 60][6];
bool gRunExpCode=YES;
#define LOG_SERVER_IP @"129.78.210.200"
#include <math.h>
#import "Core3D.h"
#import "TrackerOverlay.h"
//#define PLAY_DEMO		0
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
@implementation  ReplayData : NSObject
-init { x = y = z = tilt= dist= heading=time=0.0; movement= kNoLog; return self;}

-initWith: (float) _x :(float) _y :(float) _z :(float) _tilt :(float) _dist :(float) _heading :(float) _time  :(MovementType) _movement  ;
{ x = _x; y =_y;  z = _z; tilt=_tilt; dist= _dist; heading=_heading; time= _time; movement=_movement; return self;}
-(float) x {return x;}
-(float) y {return y;}
-(float) z{return z;}
-(float) tilt {return tilt;}
-(float) dist {return dist;}
-(float) heading {return heading;}
-(float) time {return time;}
-(MovementType) movement {return movement;}

@end


@implementation Simulation
@synthesize logOnNextUpdate,toverlay,gaze_bbox_max,gaze_bbox_min;

- (id)initWithString:(NSString *)name withScene:(Scene *)newscene;
{
    self = [super init];
    if (self)
    {
        toverlay=nil;
        scene=newscene;
		//GLuint bla = LoadTexture(@"/Users/julian/Documents/Development/VirtualTexturing/_texdata_sources/texture_8k.png", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_TRUE, 2.0);

		//globalSettings.disableTextureCompression = YES;

		//interfaceOrientation = [[UIApplication sharedApplication] statusBarOrientation];

#ifndef TARGET_OS_IPHONE
//		Light *light = [[[Light alloc] init] autorelease];
//		[light setPosition:vector3f(300, 300, 0)];
//		[light setLightAmbient:vector4f(0.7, 0.7, 0.7, 1.0)];
//		[[scene lights] addObject:light];
#endif
        vtnode=nil;
		[[scene camera] setAxisConfiguration:AXIS_CONFIGURATION(kXAxis, kYAxis, kZAxis)];
		[[scene camera] setFarPlane:20000];
		[[scene camera] setNearPlane:0.5];
		renderMode=TEXTURED;
      //  NSString *filename = [[name lastPathComponent] stringByDeletingPathExtension];	
        basename = [[name lastPathComponent ] copy];
        NSString *dataName = [NSString stringWithFormat:@"%@/vtex",name] ;
        
        NSString *numMeshesFile = [NSString stringWithFormat:@"%@/cnt",name] ;

        //NSLog(@"%@\n",dataName);
        meshes = [[NSMutableArray alloc] init]; 

        BOOL fileExists = [[NSFileManager defaultManager] fileExistsAtPath:numMeshesFile];
        int numMeshes=1;
        if(!fileExists){
            NSLog(@"No mesh count file at %@\n",numMeshesFile);
            return nil;
        }else{
            NSError *error;
            
            NSString * fileContents = [NSString stringWithContentsOfFile:numMeshesFile encoding:NSUTF8StringEncoding error:&error];
            if (fileContents == nil) {
                // an error occurred
                NSLog(@"Error reading file at %@\n%@",
                      numMeshesFile, [error localizedFailureReason]);
                if(numMeshes<=0)
                    return nil;

            }
            numMeshes = [fileContents intValue];
            if(numMeshes<=0)
                return nil;
        }
        for(int i=0; i < numMeshes; i++){
            CollideableMesh *mesh = [[CollideableMesh alloc] initWithOctreeNamed:[NSString stringWithFormat:@"%@/m-%04d", name,i]];
            mesh.scene =scene;
            if(mesh == nil)
                return nil;
            [meshes addObject:[mesh autorelease]];
        }
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

                if(vtnode == nil)
                    return nil;
                vtnode.scene =scene;

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
      //  NSLog(@"%x\n",(int)scene);
        for (id mesh in meshes) {
       
            [[vtnode children] addObject:[mesh autorelease]];
            [vtnode setZRange: [mesh zbound]];
        }
        
        [[scene objects] addObject:[vtnode autorelease]];

       // NSLog(@"blah %x %d\n",(int)[scene objects],[[scene objects] count]);

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

		/*if (PLAY_DEMO)
		{
			void *pos = vtuLoadFile([[[NSBundle mainBundle] pathForResource:@"positions" ofType:@"bin"] UTF8String], 0, NULL);

			memcpy(&positions, pos, sizeof(positions));

			[NSTimer scheduledTimerWithTimeInterval:1.0/60.0 target:self selector:@selector(updateTimer) userInfo:NULL repeats:YES];
		}*/
		
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
		replayPos=-1;

		speedModifier = 1.0;
        // Set to either Inertia or Standard slerp value
        _cameraSlerpPercentage = 0.004f;
        _cameraPanAcceleration = 30.0;
        _panKeyDist=0.005;
        _minimumZoomScale = 0.5f;
        _maxZoomScale =  6*[self radius];
        _minalt=0.0;
        cameraRotationSpeed = 0.01;
        _maxDist = 3.5*[self radius];

		replayData=NULL;
		[self resetCamera];
        _firstPan=false;
        _radius = [self radius];
        donePanning=true;
        bbox[0]=[self minbb];
        bbox[1]=[self maxbb];
      //  printf("%f -- %f\n%f -- %f\n",bbox[0][0],bbox[1][0],bbox[0][1],bbox[1][1]);
        extentsMesh=bbox[1]-bbox[0];
        _meshcent =[self center];
        logOnNextUpdate=kNoLog;
        movementStrings = [[NSArray arrayWithObjects:@"NoLog",
                           @"pann",
                           @"zoom",
                           @"tilt",
                            @"dblc",nil] retain];
        if(gRunExpCode){
            udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];  
        }else
            udpSocket=nil;

    }
    return self;
}

- (void)dealloc
{
    //printf("Sim dealloc\n");
   // [vtnode release];
    [movementStrings release];
    [basename release];
    if(vtnode!= nil)
    [[scene objects] removeObject:vtnode];
	[super dealloc];
}
- (void)clearObjs
{
    if(vtnode!= nil)
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
-(void) setupOverlay{
    toverlay = [[TrackerOverlay alloc] init];
    [toverlay setScale:20.0];

    
    [[scene objects] addObject:toverlay];

}

- (void)fpstimer
{
	globalInfo.fps = frames;
	frames = 0;
}
-(void)dumpVisInfo:(NSArray *)arr intoFile:(NSString *)fname
{
    replayData = arr;
    [arr retain];
    
    FILE *fp=fopen([fname UTF8String],"wb");
    unsigned int count=(unsigned int)[replayData count];
    fwrite((char *)&count,sizeof(unsigned int),1,fp);
    
    for(unsigned int i=0; i < count; i++){
        [self updateTimer];
        vector3f cur_bbox[2];
        cur_bbox[0]=gaze_bbox_min;
        cur_bbox[1]=gaze_bbox_max;

        [self writeVisibleVertsTo:fp :cur_bbox];
        if( i % 100 == 0 ){
            printf("%04d/%04d\n",i,count);
        }
    }
    fclose(fp);
    NSLog(@"Finished dumping\n");
}
- (void)writeVisibleVertsTo:(FILE *) fp :(vector3f *) bbox_gaze
{
    struct frustrum test_frustum=[self getFrustrumPlanes];
    unsigned int count=(unsigned int)[meshes count];
    fwrite((char *)&count,sizeof(unsigned int),1,fp);
    for (CollideableMesh *mesh in meshes) {
        NSMutableSet *ptsInFrame = [[NSMutableSet alloc] init];
        if(![mesh getVertesInFrame:ptsInFrame forFrustrum:test_frustum]){
            fprintf(stderr,"Failed to run getVertsinframe\n");
            exit(-1);
        }
        count=(unsigned int)mesh.octree->vertexCount;
        fwrite((char *)&count,sizeof(unsigned int),1,fp);
        count=(unsigned int)[ptsInFrame count];
        fwrite((char *)&count,sizeof(unsigned int),1,fp);
        for (NSNumber* num in ptsInFrame) {
            unsigned int vert=(unsigned int)[num intValue];
            fwrite((char *)&vert,sizeof(unsigned int),1,fp);
        }
        fwrite((char *)&bbox_gaze[0][0],sizeof(float),3,fp);
        fwrite((char *)&bbox_gaze[1][0],sizeof(float),3,fp);

        [ptsInFrame release];
    }

}

- (void)writeVisibleBoundsTo:(FILE *) fp
{
    struct frustrum test_frustum=[self getFrustrumPlanes];
    vector3f minA,maxA;
    vector3f totalBounds[2];
    for( int i=0; i< 3; i++){
        totalBounds[0][i]=FLT_MAX;
        totalBounds[1][i]=-FLT_MAX;
    }
    

    for (CollideableMesh *mesh in meshes) {
        vector3f bounds[2];

        if(![mesh getBoundsOfVertsInFrame:bounds forFrustrum:test_frustum]){
            fprintf(stderr,"Failed to run getVertsinframe\n");
            exit(-1);
        }
        totalBounds[0]=MIN(totalBounds[0], bounds[0]);
        totalBounds[1]=MAX(totalBounds[1], bounds[1]);

        
    }
    float data[6];
    for(int i=0; i<3; i++){
        data[i]=totalBounds[0][i];
        data[i+3]=totalBounds[1][i];
    }
    fwrite((char *)&data[0],sizeof(float),6,fp);


    
}


- (void)updateTimer
{
/*	if (PLAY_DEMO)
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

	}*/
    if(replayData != nil && [replayData count] > 0 ){
        replayPos++;
        if(replayPos >= [replayData count]){
            replayPos=0;
            NSLog(@"Finished replay restarting\n");
        }
        
        gaze_bbox_min[0]=NAN;
        gaze_bbox_min[1]=NAN;
        gaze_bbox_min[2]=NAN;
        gaze_bbox_max[0]=NAN;
        gaze_bbox_max[1]=NAN;
        gaze_bbox_max[2]=NAN;
        
        ReplayData *data=[replayData objectAtIndex:replayPos];
        if([data movement] == kNoLog ){
            //Update gaze
            if(toverlay != nil){
                vector2f p;
                p[0]=[data x];
                p[1]=[data y];
                [toverlay updatePos:p];
                vector2f p_fliped;
                p_fliped[0]=[data x];
                p_fliped[1]=768-[data y];
                int sizeR=70;
                //CGRect rect= CGRectMake(p_fliped[0]-(sizeR/2),p_fliped[1]-(sizeR/2),sizeR,sizeR);
                CGRect rect= CGRectMake(p_fliped[0]-(sizeR/2),p_fliped[1]-(1.5*sizeR),sizeR,sizeR);

                vector3f world_bbox[2];
                if([self getScreenRectWorldBBox:rect :world_bbox]){
                  /*  printf("%f - %f , %f - %f , %f - %f\n",world_bbox[0][0],world_bbox[1][0],
                       world_bbox[0][1],world_bbox[1][1],
                       world_bbox[0][2],world_bbox[1][2]);*/
                    gaze_bbox_min=world_bbox[0];
                    gaze_bbox_max=world_bbox[1];
                }
                else{
                //   printf("Failed\n");
                }
                [toverlay updatePos3d:world_bbox];

            }
            
        }else{
            _targetCenter[0]=[data x];
            _targetCenter[1]=[data y];
            _targetCenter[2]=[data z];
            
            _targetDistance=[data dist];
            _targetTilt=[data tilt];
            _targetHeading=[data heading];
            /* NSLog(@"Replaying %05ld/%05ld %f %f %f %f %f %f\n", replayPos,(long int)[replayData count],_targetCenter[0], _targetCenter[1], _targetCenter[2],
             _targetDistance,
             _targetTilt,
             _targetHeading);*/
            _center[0]=_targetCenter[0];
            _center[1]=_targetCenter[1];
            _center[2]=_targetCenter[2];
            _distance=_targetDistance;
            _heading=_targetHeading;
            _tilt=_targetTilt;
            
            
        }
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
matrix44f_c CATransform3DSetField(CATransform3D transform )
{
    matrix44f_c mat;

        mat.set(transform.m11 , transform.m21,transform.m31,transform.m41,
                transform.m12 , transform.m22,transform.m32,transform.m42,
                transform.m13 , transform.m23,transform.m33,transform.m43,
                transform.m14 , transform.m24,transform.m34,transform.m44);

                
    return mat;
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
	//printf("portrate %d landscape %d\n",interfaceOrientation == UIInterfaceOrientationPortrait,
       //    interfaceOrientation == UIInterfaceOrientationLandscapeLeft);
	
headingMat= CATransform3DMakeRotation(_heading * M_PI / 180.0,0,0,1);
   
// if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
 //tiltMat=CATransform3DMakeRotation(-_tilt * M_PI / 180.0,1,0,0);
 //else if(interfaceOrientation == UIInterfaceOrientationPortrait)
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
                //[self pan: pt];
                _targetCenter[0]+=_panKeyDist*30;

                break;
			case 'w':
                pt.x=0;
                pt.y=_panKeyDist;
               // [self pan: pt];
                _targetCenter[0]-=_panKeyDist*30;

				break;
			case 'a':
                pt.x=_panKeyDist;
                pt.y=0;
                _targetCenter[1]+=_panKeyDist*30;//[self pan: pt];
				break;
			case 'd':
                pt.x=-_panKeyDist;
                pt.y=0;
                _targetCenter[1]-=_panKeyDist*30;
               // [self pan: pt];
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
    matrix44f_c data=CATransform3DSetField(_invMat);
   // memcpy(data.data(),&_invMat.m11,sizeof(float)*16);
	[[scene camera] load:data];
   // [self printMatrix:[[scene camera] modelViewMatrix].data()];
   // printf("%d %d\n",[self isDoneMoving] , goneOutOfFrame);
    if(goneOutOfFrame && ![self anyTrianlgesInFrustum:frustum]){
        _targetCenter[0]=_lastValidCenter[0];
       _targetCenter[1]=_lastValidCenter[1];
       _targetCenter[2]=_lastValidCenter[2];
       _targetDistance=_lastValidDist;
       _targetTilt =_lastValidTilt;
       _targetHeading=_lastValidHeading;
    }
    if(logOnNextUpdate!=kNoLog){
        [self logCameraPosition: logOnNextUpdate];
        logOnNextUpdate=kNoLog;
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

-(matrix44f_c) getCurrViewMat{
    CATransform3D mTmp;
    CATransform3D tiltMat;
    CATransform3D headingMat;
	CATransform3D viewtest;
	
    headingMat= CATransform3DMakeRotation(_targetHeading * M_PI / 180.0,0,0,1);
    // if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
    //   tiltMat=CATransform3DMakeRotation(-_targetTilt * M_PI / 180.0,1,0,0);
    // else if(interfaceOrientation == UIInterfaceOrientationPortrait)
    tiltMat=CATransform3DMakeRotation(-_targetTilt * M_PI / 180.0,0,1,0);
    viewtest=CATransform3DMakeTranslation(_targetCenter[0],_targetCenter[1],_targetCenter[2]);
    
    viewtest= CATransform3DConcat(viewtest,orientation);
    viewtest= CATransform3DConcat(viewtest,headingMat);
    
    viewtest=CATransform3DConcat(viewtest,tiltMat);
    
    mTmp= CATransform3DMakeTranslation(0,0,-_targetDistance);
    viewtest= CATransform3DConcat(viewtest,mTmp);
    
    matrix44f_c data=CATransform3DSetField(viewtest);
    return data;
}
-(struct frustrum)getFrustrumPlanes{

    matrix44f_c data=[self getCurrViewMat];
    struct frustrum test_frustum;

    //memcpy(data.data(),&(viewtest.m11),sizeof(float)*16);
    
    extract_frustum_planes(data,[[scene camera] projectionMatrix], test_frustum.planes, cml::z_clip_neg_one, false);
    return test_frustum;

}
-(void) checkInFrame{
    struct frustrum test_frustum=[self getFrustrumPlanes];
    if(![self anyTrianlgesInFrustum:test_frustum.planes]){
        goneOutOfFrame=YES;
     //   printf("Not in frame\n");

    }else {
       // printf("Still in\n");
    }
}

- (void)mouseDragged:(CGPoint)pos withFlags:(uint32_t)flags
{
	/*vector3f rot = [[scene camera] rotation];

	 rot[1] -= delta[0] / 10.0;
	 rot[0] -= delta[1] / 10.0;

	 [[scene camera] setRotation:rot];*/
//    [self pan: delta[0] / 2000.0 andY:delta[1] / 2000.0 ];
    [self pan:pos];

}

#if !TARGET_OS_IPHONE && !defined(linux)
/*- (void)mouseUp:(CGPoint)pt
{
    [self pancont:pt];

    //	speedModifier = 1.0;
}
- (void)mouseDown:(CGPoint)pt
{
    //lastMovementPosition = [self convertPoint:p fromView:nil];
    
    [self pancont:pt];
	//speedModifier = 1.0;
}
- (void)rightMouseUp:(NSEvent *)event
{
//	speedModifier = 1.0;
}
- (void)rightMouseDown:(NSEvent *)event
{
    CGPoint p = [event locationInWindow];
    //lastMovementPosition = [self convertPoint:p fromView:nil];

    [self pancont:p];

	//speedModifier = 1.0;
}*/
#endif

- (void)scrollWheel:(float)delta
{
 //   float val=delta/10.0;
    [self zoomval: delta];

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
-(BOOL) getScreenRectWorldBBox:(CGRect)rect :(vector3f *)world_bbox{
    vector3f origin(-_center[0],-_center[1],-_center[2]);
    //printf("%f %f %f\n",_center[0],_center[1],_center[2]);
    vector3f v1=vector3f(origin[0],origin[1],origin[2]);
    vector3f v2=vector3f(origin[0]+1,origin[1],origin[2]);
    vector3f v3=vector3f(origin[0],origin[1]+1,origin[2]);
    CC3Plane plane= CC3PlaneFromPoints(v1,v2,v3);
    CC3Plane normPlane=CC3PlaneNormalize(plane);

    matrix44f_c data=[self getCurrViewMat];

    world_bbox[0][0]=FLT_MAX;
    world_bbox[0][1]=FLT_MAX;
    world_bbox[0][2]=FLT_MAX;
    
    world_bbox[1][0]=-FLT_MAX;
    world_bbox[1][1]=-FLT_MAX;
    world_bbox[1][2]=-FLT_MAX;
    
    CGPoint pts[4];
    pts[0] = CGPointMake(CGRectGetMinX(rect), CGRectGetMaxY(rect));
    pts[1] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMaxY(rect));
    pts[2] = CGPointMake(CGRectGetMaxX(rect), CGRectGetMinY(rect));
    pts[3] = CGPointMake(CGRectGetMinX(rect), CGRectGetMinY(rect));
    for(int i=0; i < 4; i++ ){
        CC3Ray ray=[[scene camera] unprojectPoint: pts[i] withModelView:data];
        float intersectionPoint[4];
        intersectionPoint[3]=1;
        if([self intersectOctreeNodeWithRay:0 withRay:ray inter:intersectionPoint])
        //if(intersectOctreeNodeWithRay([mesh octree], 0,ray, intersectionPoint))
            ;// printf("Hit %f %f %f\n",intersectionPoint[0],intersectionPoint[1],intersectionPoint[2]);
        else{
            continue;
            vector4f ret=CC3RayIntersectionWithPlane(ray, normPlane );// printf("No hit\n");
            intersectionPoint[0]=ret[0];
            intersectionPoint[1]=ret[1];
            intersectionPoint[2]=ret[2];
           // printf("Plane Hit %f %f %f\n",intersectionPoint[0],intersectionPoint[1],intersectionPoint[2]);

        }
        world_bbox[0][0]=MIN(intersectionPoint[0],world_bbox[0][0]);
        world_bbox[0][1]=MIN(intersectionPoint[1],world_bbox[0][1]);
        world_bbox[0][2]=MIN(intersectionPoint[2],world_bbox[0][2]);
        world_bbox[1][0]=MAX(intersectionPoint[0],world_bbox[1][0]);
        world_bbox[1][1]=MAX(intersectionPoint[1],world_bbox[1][1]);
        world_bbox[1][2]=MAX(intersectionPoint[2],world_bbox[1][2]);
        
        
    }
    for(int i=0; i < 2; i++){
        for(int j=0; j<3; j++){
            if(world_bbox[i][j] == FLT_MAX || world_bbox[i][j] == -FLT_MAX || !isfinite(world_bbox[i][j] )){
                return NO;
            }
        }
    }
    
    return YES;
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
    
    vector4f unprojected_diff =[self pickPt:[scene camera] pick:pt];
//[[scene camera] pick:pt intoMesh: [mesh octree] ];
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
    
    CGFloat scale;
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE
    scale = [[UIScreen mainScreen] scale];
#else
    scale=1.0;
#endif
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
    matrix44f_c data=CATransform3DSetField(newModel);
   // memcpy(data.data(),&newModel.m11,sizeof(float)*16);

    CC3Ray ray=[[scene camera] unprojectPoint: centerScreenWorld withModelView:data];
    float intersectionPoint[4];
    intersectionPoint[3]=1;
    if([self intersectOctreeNodeWithRay:0 withRay:ray inter:intersectionPoint])
    //if(intersectOctreeNodeWithRay([mesh octree], 0,ray, intersectionPoint))
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
   // if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft)
      //  tiltMat=CATransform3DMakeRotation(_tilt * M_PI / 180.0,1,0,0);
    //else if(interfaceOrientation == UIInterfaceOrientationPortrait)
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
    
    float tiltAngleOffset=15.0;
	double headingVal,tiltVal;
    // Heading
	/*if(interfaceOrientation == UIInterfaceOrientationLandscapeLeft){
		headingVal=pt.y;
		tiltVal= -(pt.x);
	}
	else*/{
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
    vector4f tmp =[self pickPt:[scene camera] pick:pt];//[self pickPt camera:[scene camera] pick:pt intoMesh: [mesh octree] ];
    if(isfinite(tmp[0])){
        _targetCenter[0]=-tmp[0];
        _targetCenter[1]=-tmp[1];
        _targetCenter[2]=-tmp[2];
        _targetDistance =_minalt+3.0;
    }

}
-(void) panstart: (CGPoint) pt{
    CC3Plane plane=[self centeredPlane];
    CC3Plane normPlane=CC3PlaneNormalize(plane);
    
    vector4f tmp =[self pickPt:[scene camera] pick:pt];//[[scene camera] pick:pt intoMesh: [mesh octree] ];
    
    //[[scene camera] unprojectPoint:_lastPt ontoPlane: normPlane];
    if(isfinite(tmp[0]))
       _unprojected_orig=tmp;
    else 
        _unprojected_orig=[[scene camera] unprojectPoint:pt ontoPlane: normPlane];

}
-(void) loadReplay:(NSArray *)arr {
  //  NSLog(@"%@\n",arr);
    replayData = arr;
    [arr retain];
    [NSTimer scheduledTimerWithTimeInterval:1.0/20.0 target:self selector:@selector(updateTimer) userInfo:NULL repeats:YES];
    
}

-(void) pancont: (CGPoint) pt
{
   // printf("%f %f\n",pt.x,pt.y);

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
-(NSDictionary *) packDictWithState:(MovementType)type 
{
    NSDictionary *dictionary =
    [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:basename],
     @"mesh",
     [movementStrings objectAtIndex:type],
     @"movement",
     [NSNumber numberWithDouble:[[NSDate date] timeIntervalSince1970]],
     @"time",
     [NSNumber numberWithDouble:_targetCenter[0]],
     @"centerX",
     [NSNumber numberWithDouble:_targetCenter[1]],
     @"centerY",
     [NSNumber numberWithDouble:_targetCenter[2]],
     @"centerZ",
     [NSNumber numberWithDouble:_targetDistance],
     @"distance",
     [NSNumber numberWithDouble:_targetTilt],
     @"tilt",
     [NSNumber numberWithDouble:_targetHeading],
     @"heading",
     nil];
    
    return dictionary;
}

-(void) unpackDict:(NSDictionary *)dictionary
{
    _targetCenter[0]= [[dictionary objectForKey:@"centerX" ] doubleValue];
    _targetCenter[1]= [[dictionary objectForKey:@"centerY" ] doubleValue];
    _targetCenter[2]= [[dictionary objectForKey:@"centerZ" ] doubleValue];
    _targetDistance= [[dictionary objectForKey:@"distance" ] doubleValue];
    _targetTilt= [[dictionary objectForKey:@"tilt" ] doubleValue];
    _targetHeading= [[dictionary objectForKey:@"heading" ] doubleValue];
}
-(void)logCameraPosition:(MovementType)type 
{
   /* if(type == kPanning)
        printf("Logging Panning\n");
    else if(type == kZoom)
        printf("Logging Zoom\n");
    else if(type == kTilt)
        printf("Logging Tilt\n");
    else if(type == kDoubleClick)
        printf("Logging Click\n");

*/
#if defined(TARGET_OS_IPHONE) && TARGET_OS_IPHONE

    [Flurry endTimedEvent:@"MOVEMENT_EVENT" withParameters:nil];
    NSDictionary *dictionary =[self packDictWithState:type];
 
    [Flurry logEvent:@"MOVEMENT_EVENT" withParameters:dictionary timed:YES];
    if(gRunExpCode){
        NSMutableData *data = [[NSMutableData alloc] init];
        NSKeyedArchiver *archiver = [[NSKeyedArchiver alloc] initForWritingWithMutableData:data];
        [archiver encodeObject:dictionary forKey:@"STATE_PACKET"];
        [archiver finishEncoding];
        [archiver release];
        [udpSocket sendData:data toHost:LOG_SERVER_IP port:IPAD_PORT withTimeout:-1 tag:1];
        [data release];
     }
#endif
    
}

- (void)resetCamera
{
        
	//[[scene camera] setPosition:vector3f(10, 1, 0)]; 
    //[[scene camera] setRotation:vector3f(-90, 0, 0)];
    vector3f tmp= [self center];
    _center[0] = -tmp[0];
    _center[1] = -tmp[1];
    _center[2] = -tmp[2];
    _distance = 3*[self radius];
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

-(vector3f) center
{
    vector3f cp;
    cp[0]=0;
    cp[1]=0;
    cp[2]=0;
    for (CollideableMesh *mesh in meshes) {
        cp+=[mesh center];
    }
    cp[0]/=[meshes count];
    cp[1]/=[meshes count];
    cp[2]/=[meshes count];
  
    return cp;

}
- (CC3Plane)centeredPlane{
   vector3f cen= [self center];
    vector3f v1=vector3f(cen[0],cen[1],cen[2]);
    vector3f v2=vector3f(cen[0]+1.0,cen[1],cen[2]);
    vector3f v3=vector3f(cen[0],cen[1]+1.0,cen[2]);
    return CC3PlaneFromPoints(v1,v2,v3);
}

- (float)radius
{
    vector3f cp;
    cp[0]=-FLT_MAX;
    cp[1]=-FLT_MAX;
    cp[2]=-FLT_MAX;
    for (CollideableMesh *mesh in meshes) {
        for(int i=0; i<3; i++)
            cp[i]=MAX([mesh extents][i], cp[i]);
    }
    
	return cp.length() / 2.0;
}
- (vector3f)maxbb{
    vector3f cp;
    cp[0]=-FLT_MAX;
    cp[1]=-FLT_MAX;
    cp[2]=-FLT_MAX;
    for (CollideableMesh *mesh in meshes) {
        for(int i=0; i<3; i++)
            cp[i]=MAX([mesh maxbb][i], cp[i]);
    }
    
    return cp;
}
- (vector3f)minbb{
    vector3f cp;
    cp[0]=FLT_MAX;
    cp[1]=FLT_MAX;
    cp[2]=FLT_MAX;
    for (CollideableMesh *mesh in meshes) {
        for(int i=0; i<3; i++)
            cp[i]=MIN([mesh minbb][i], cp[i]);
    }
   
    return cp;
}

-(BOOL) intersectOctreeNodeWithRay:(int)nodeNumber withRay:(CC3Ray)ray inter:(float *)pt
{
    for (CollideableMesh *mesh in meshes) {
        
        if(intersectOctreeNodeWithRay([mesh octree], nodeNumber,ray, pt))
            return YES;
    }
    return NO;
}

-(BOOL)anyTrianlgesInFrustum:(const GLfloat [6][4])frustum
{
    for (CollideableMesh *mesh in meshes) {
        if([mesh anyTrianlgesInFrustum:frustum])
            return YES;
    }
    return NO;

}
-(vector4f)pickPt:(Camera *)cam pick:(CGPoint)pt
{
    for (CollideableMesh *mesh in meshes) {
        vector4f tmp =[[scene camera] pick:pt intoMesh: [mesh octree] ];
            if(tmp != vector4f(INFINITY,INFINITY,INFINITY,INFINITY))
                return tmp;
    }
    return vector4f(INFINITY,INFINITY,INFINITY,INFINITY);

}


@end
