
//
//  BenthosOpenGLES20Renderer.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 4/12/2011.
//

#import "MyOpenGLES20Renderer.h"
#import "FlurryAnalytics.h"

#import "GLProgram.h"
#include "Simulation.h"
#include "LibVT_Internal.h"
extern vtData vt;
extern vtConfig c;
#define AMBIENTOCCLUSIONTEXTUREWIDTH 512
#define AOLOOKUPTEXTUREWIDTH 128
//#define AOLOOKUPTEXTUREWIDTH 64
//#define SPHEREDEPTHTEXTUREWIDTH 256
#define SPHEREDEPTHTEXTUREWIDTH 32

@implementation MyOpenGLES20Renderer
@synthesize sim,scene,     removeOnceRender;
;
#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(EAGLContext *)newContext;
{
    self = [super initWithContext:newContext];
	
    if(self){
        currentViewportSize = CGSizeZero;
        [EAGLContext setCurrentContext:context];
        removeOnceRender=NO;
        //scene = [Scene sharedScene];
    }
    return self;
}

- (void)dealloc 
{    
    //NSLog(@"Here dealloc OPENGLES2\n");
    [self freeVertexBuffers];
    
   	
	[super dealloc];
}

#pragma mark -
#pragma mark Model manipulation


/*- (void)translateModelByScreenDisplacementInX:(float)xTranslation inY:(float)yTranslation;
{
    // Translate the model by the accumulated amount
	float currentScaleFactor = sqrt(pow(currentCalculatedMatrix.m11, 2.0f) + pow(currentCalculatedMatrix.m12, 2.0f) + pow(currentCalculatedMatrix.m13, 2.0f));	
	
	xTranslation = xTranslation * [[UIScreen mainScreen] scale] / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);
	yTranslation = yTranslation * [[UIScreen mainScreen] scale] / (currentScaleFactor * currentScaleFactor * backingWidth * 0.5);
    
	// Use the (0,4,8) components to figure the eye's X axis in the model coordinate system, translate along that
	// Use the (1,5,9) components to figure the eye's Y axis in the model coordinate system, translate along that
	
    accumulatedModelTranslation[0] += xTranslation * currentCalculatedMatrix.m11 + yTranslation * currentCalculatedMatrix.m12;
    accumulatedModelTranslation[1] += xTranslation * currentCalculatedMatrix.m21 + yTranslation * currentCalculatedMatrix.m22;
    accumulatedModelTranslation[2] += xTranslation * currentCalculatedMatrix.m31 + yTranslation * currentCalculatedMatrix.m32;
}*/


#pragma mark -
#pragma mark OpenGL drawing support

- (BOOL)createFramebuffersForLayer:(CAEAGLLayer *)glLayer;
{
	dispatch_async(openGLESContextQueue, ^{
        dispatch_sync(dispatch_get_main_queue(), ^{
            [EAGLContext setCurrentContext:context];
            
            // Need this to make the layer dimensions an even multiple of 32 for performance reasons
            // Also, the 4.2 Simulator will not display the frame otherwise
            /*	CGRect layerBounds = glLayer.bounds;
             CGFloat newWidth = (CGFloat)((int)layerBounds.size.width / 32) * 32.0f;
             CGFloat newHeight = (CGFloat)((int)layerBounds.size.height / 32) * 32.0f;
             */
            // NSLog(@"Bounds before: %@", NSStringFromCGRect(glLayer.bounds));
             
           //  glLayer.bounds = CGRectMake(layerBounds.origin.x, layerBounds.origin.y, newWidth, newHeight);
             
            // NSLog(@"Bounds after: %@", NSStringFromCGRect(glLayer.bounds));
                       
            [self createFramebuffer:&viewFramebuffer size:CGSizeZero renderBuffer:&viewRenderbuffer depthBuffer:&viewDepthBuffer texture:NULL layer:glLayer];    
            [self switchToDisplayFramebuffer];
            glViewport(0, 0, backingWidth, backingHeight);

            currentViewportSize = CGSizeMake(backingWidth, backingHeight);
			[scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];
        });        
    });
    
    return YES;
}
- (void)reshapeScenes;
{
    
    [scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];

}


- (BOOL)createFramebuffer:(GLuint *)framebufferPointer size:(CGSize)bufferSize renderBuffer:(GLuint *)renderbufferPointer depthBuffer:(GLuint *)depthbufferPointer texture:(GLuint *)backingTexturePointer layer:(CAEAGLLayer *)layer;
{
    glGenFramebuffers(1, framebufferPointer);
    glBindFramebuffer(GL_FRAMEBUFFER, *framebufferPointer);
	
    if (renderbufferPointer != NULL)
    {
        glGenRenderbuffers(1, renderbufferPointer);
        glBindRenderbuffer(GL_RENDERBUFFER, *renderbufferPointer);
        
        if (backingTexturePointer == NULL)
        {
            [context renderbufferStorage:GL_RENDERBUFFER fromDrawable:layer];
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_WIDTH, &backingWidth);
            glGetRenderbufferParameteriv(GL_RENDERBUFFER, GL_RENDERBUFFER_HEIGHT, &backingHeight);
            bufferSize = CGSizeMake(backingWidth, backingHeight);
        }
        else
        {
            glRenderbufferStorage(GL_RENDERBUFFER, GL_RGBA8_OES, bufferSize.width, bufferSize.height);
        }
        
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_RENDERBUFFER, *renderbufferPointer);	
    }
    
    if (depthbufferPointer != NULL)
    {
        glGenRenderbuffers(1, depthbufferPointer);
        glBindRenderbuffer(GL_RENDERBUFFER, *depthbufferPointer);
        glRenderbufferStorage(GL_RENDERBUFFER, GL_DEPTH_COMPONENT16, bufferSize.width, bufferSize.height);
        glFramebufferRenderbuffer(GL_FRAMEBUFFER, GL_DEPTH_ATTACHMENT, GL_RENDERBUFFER, *depthbufferPointer);
    }
	
    if (backingTexturePointer != NULL)
    {
		/*  if ( (ambientOcclusionTexture == 0) || (*backingTexturePointer != ambientOcclusionTexture))
		 {
		 if (*backingTexturePointer != 0)
		 {
		 glDeleteTextures(1, backingTexturePointer);
		 }
		 
		 glGenTextures(1, backingTexturePointer);
		 
		 glBindTexture(GL_TEXTURE_2D, *backingTexturePointer);
		 if (*backingTexturePointer == ambientOcclusionTexture)
		 {
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
		 
		 
		 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
		 //                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, bufferSize.width, bufferSize.height, 0, GL_LUMINANCE, GL_UNSIGNED_BYTE, 0);
		 }
		 else if (*backingTexturePointer == sphereAOLookupTexture)
		 {
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
		 
		 
		 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
		 }
		 else
		 {
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_NEAREST );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_NEAREST );
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR );
		 //                glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR );
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_S, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_WRAP_T, GL_CLAMP_TO_EDGE);
		 glTexParameteri(GL_TEXTURE_2D, GL_GENERATE_MIPMAP, GL_FALSE);
		 
		 glTexImage2D(GL_TEXTURE_2D, 0, GL_RGBA, bufferSize.width, bufferSize.height, 0, GL_RGBA, GL_UNSIGNED_BYTE, 0);
		 //                glTexImage2D(GL_TEXTURE_2D, 0, GL_LUMINANCE, bufferSize.width, bufferSize.height, 0, GL_LUMINANCE, GL_FLOAT, 0);
		 }            
		 }
		 else
		 {
		 glBindTexture(GL_TEXTURE_2D, *backingTexturePointer);
		 }*/
        
        glFramebufferTexture2D(GL_FRAMEBUFFER, GL_COLOR_ATTACHMENT0, GL_TEXTURE_2D, *backingTexturePointer, 0);
        glBindTexture(GL_TEXTURE_2D, 0);
    }	
	
	GLenum status = glCheckFramebufferStatus(GL_FRAMEBUFFER);
    if (status != GL_FRAMEBUFFER_COMPLETE) 
	{
		NSLog(@"Incomplete FBO: %d", status);
        assert(false);
    }
    
    return YES;
}

- (void)switchToDisplayFramebuffer;
{
	glBindFramebuffer(GL_FRAMEBUFFER, viewFramebuffer);
    glBindRenderbuffer(GL_RENDERBUFFER, viewRenderbuffer);
    
    CGSize newViewportSize = CGSizeMake(backingWidth, backingHeight);
	
    if (!CGSizeEqualToSize(newViewportSize, currentViewportSize))
    {        
        glViewport(0, 0, backingWidth, backingHeight);
        currentViewportSize = newViewportSize;
    }
}
-(void)shutdownVT;
{

    [FlurryAnalytics endTimedEvent:@"VIEWMODEL" withParameters:nil];
    dispatch_sync(openGLESContextQueue, ^{
        isSceneReady=NO;
        [EAGLContext setCurrentContext:context];
		
        vtShutdown();
        
        c.tileDir = "";
        c.pageDimension=0;
        
        c.tileDir="";
        c.pageCodec="";
        
        c.pageBorder=0; 
        c.mipChainLength=0;
        
        // derived values:
        c.pageMemsize=c.maxCachedPages=c.physTexDimensionPages=c.virtTexDimensionPages=c.residentPages=0;
        c.pageDataFormat=c.pageDataType=c.pageDXTCompression=0;
        int sizeofzero= int((int)&(vt.fovInDegrees)-(int)&(vt.mipTranslation));
        bzero(&vt,sizeofzero);
        vt.neededPages.clear();
        std::queue<uint32_t> empty;
        std::swap(             vt.newPages, empty );
      	map<uint32_t, void *>::iterator cachedIter;
        
            
            for(cachedIter = vt.cachedPages.begin(); cachedIter != vt.cachedPages.end(); ++cachedIter)
            {
                free(cachedIter->second);
            }
                

        vt.cachedPages.clear();
        vt.cachedPagesAccessTimes.clear();
        vt.memValid=false;
        //printf("Scene %d\n",[scene retainCount]);
        [scene release];
        scene =nil;
    });     

}
- (void)showStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kBenthosLoadingStartedNotification object:nil ];
}	

- (void)hideStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:kBenthosLoadingEndedNotification object:nil ];
}
-(void)startupVT:(BenthosModel *)mol
{
    NSDictionary *dictionary = 
    [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:mol.filenameWithoutExtension], 
     @"currentmodel", 
     nil];
    [FlurryAnalytics logEvent:@"VIEWMODEL" withParameters:dictionary timed:YES];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    
  //  NSLog(@"Startt VT %@\n",name);
    //if(documentsDirectory != nil)
    //  printf("NIL %s\n",[documentsDirectory UTF8String]);
   // [self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];

    NSString *fullpath=[libraryDirectory stringByAppendingPathComponent:[[mol filename] stringByDeletingPathExtension]];
    dispatch_sync(openGLESContextQueue, ^{
        NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];

      //  mesh.scene =scene;


        [EAGLContext setCurrentContext:context];
        if(scene == nil)
            scene = [[Scene alloc] init];

        sim = [[Simulation alloc] initWithString:fullpath withScene:scene] ;
        if (sim){
        [scene setSimulator:sim];
            
            isSceneReady=YES;
            [mol setHasRendered:NO];
            [scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];

         //   [self renderFrameForModel:mol];
            
            
        }else{
            dispatch_async(dispatch_get_main_queue(), ^{
                NSError *error=nil;
                
                UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not create simulation files missing", @"Localized", nil) message:[error localizedDescription]
                                                               delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
                [alert show];
                [alert release];
            });
            isSceneReady=NO;
                
            [[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingEnded" object:nil];


        }
        [sim release];
        [pool drain];
    });

}

- (void)destroyFramebuffers;
{
    dispatch_async(openGLESContextQueue, ^{
        [EAGLContext setCurrentContext:context];
		
        if (viewFramebuffer)
        {
            glDeleteFramebuffers(1, &viewFramebuffer);
            viewFramebuffer = 0;
        }
        
        if (viewRenderbuffer)
        {
            glDeleteRenderbuffers(1, &viewRenderbuffer);
            viewRenderbuffer = 0;
        }
        
        if (viewDepthBuffer)
        {
            glDeleteRenderbuffers(1, &viewDepthBuffer);
            viewDepthBuffer = 0;
        }
		
    });   
}


- (void)presentRenderBuffer;
{
	[context presentRenderbuffer:GL_RENDERBUFFER];
}

- (void)clearScreen;
{
    dispatch_async(openGLESContextQueue, ^{
        [EAGLContext setCurrentContext:context];
        
        [self switchToDisplayFramebuffer];
        
        glClearColor(0.2f, 0.2f, 0.2f, 1.0f);
        glClear(GL_COLOR_BUFFER_BIT);
        
        [self presentRenderBuffer];
    });
}

#pragma mark -
#pragma mark Actual OpenGL rendering
- (void)bindVertexBuffersForModel;
{
  //  printf("Finished loading!\n");    
//    isSceneReady = YES;
}
- (void)renderFrameForModel:(BenthosModel *)model;
{
    if (!isSceneReady)
    {
        return;
     }
	
    
 
//    return;
	
    // In order to prevent frames to be rendered from building up indefinitely, we use a dispatch semaphore to keep at most two frames in the queue
    
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    dispatch_async(openGLESContextQueue, ^{
        if (![model hasRendered])
        {
            
          //  [scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];
            [EAGLContext setCurrentContext:context];
            
            [model setHasRendered:YES];
            // printf("Setup render\n");
            //    [self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:NO];
            [self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];
            drawn=0;

        }
        
        if (isSceneReady)
        {
       
        [EAGLContext setCurrentContext:context];
		      // CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();

		[scene update];
		
		[scene render];
        
       // printf("%d BOOL\n",isSceneReady);
          if(drawn < 2)
              glFlush();
        
              
            if(drawn==2){
                //printf("First render\n");

                [self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:NO];
               
            }
            if(drawn>2){
                [self presentRenderBuffer];
                if(removeOnceRender){
                    [[NSNotificationCenter defaultCenter] postNotificationName:@"UnhookAutoRotate" object:nil ];
                    removeOnceRender=NO;
                }

            }
            else
                drawn++;

		// Discarding is only supported starting with 4.0, so I need to do a check here for 3.2 devices
        const GLenum discards[]  = {GL_COLOR_ATTACHMENT0};
        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
		       // CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
		//        
		    //    NSLog(@"Frame duration: %f ms", frameDuration * 1000.0);
        }
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });

	
	
}

@end