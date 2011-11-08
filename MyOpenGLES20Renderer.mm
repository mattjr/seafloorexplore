
//
//  SLSOpenGLES20Renderer.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 4/12/2011.
//

#import "MyOpenGLES20Renderer.h"
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

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithContext:(EAGLContext *)newContext;
{
	if (![super initWithContext:newContext])
    {
		return nil;
    }

    currentViewportSize = CGSizeZero;
   	[EAGLContext setCurrentContext:context];

	scene = [Scene sharedScene];
    return self;
}

- (void)dealloc 
{    
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
             
             NSLog(@"Bounds before: %@", NSStringFromCGRect(glLayer.bounds));
             
             glLayer.bounds = CGRectMake(layerBounds.origin.x, layerBounds.origin.y, newWidth, newHeight);
             
             NSLog(@"Bounds after: %@", NSStringFromCGRect(glLayer.bounds));
             */            
            [self createFramebuffer:&viewFramebuffer size:CGSizeZero renderBuffer:&viewRenderbuffer depthBuffer:&viewDepthBuffer texture:NULL layer:glLayer];    
            [self switchToDisplayFramebuffer];
            glViewport(0, 0, backingWidth, backingHeight);
            
            currentViewportSize = CGSizeMake(backingWidth, backingHeight);
			//[scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];
        });        
    });
    
    return YES;
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
        vt.cachedPages.clear();
        vt.cachedPagesAccessTimes.clear();
        
    });     


}

-(void)startupVT:(NSString *)name
{
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory =[paths objectAtIndex:0];
    
    
    //if(documentsDirectory != nil)
    //  printf("NIL %s\n",[documentsDirectory UTF8String]);
    
    NSString *fullpath=[documentsDirectory stringByAppendingPathComponent:name];
  
   
    dispatch_sync(openGLESContextQueue, ^{
        
        if(scene == nil)
            scene = [Scene sharedScene];
        [EAGLContext setCurrentContext:context];
        
        id sim = [[[Simulation alloc] initwithstring:fullpath] autorelease];//[[[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init] autorelease];

        if (sim)
            [scene setSimulator:sim];
        else
            fatal("Error: there is no valid simulation class");
        isSceneReady=YES;
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
- (void)bindVertexBuffersForMolecule;
{
    printf("Finished loading!\n");    
//    isSceneReady = YES;
}
- (void)renderFrameForMolecule:(SLSMolecule *)molecule;
{
    if (!isSceneReady)
    {
        return;
     }
	
    
    if (![molecule hasRendered])
    {
        [scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:backingWidth], [NSNumber numberWithInt:backingHeight], nil]];
        printf("%d %d\n",backingWidth,backingHeight);
        [EAGLContext setCurrentContext:context];

        [molecule setHasRendered:YES];
        printf("First render\n");
    }
//    return;
	
    // In order to prevent frames to be rendered from building up indefinitely, we use a dispatch semaphore to keep at most two frames in the queue
    
    if (dispatch_semaphore_wait(frameRenderingSemaphore, DISPATCH_TIME_NOW) != 0)
    {
        return;
    }
    
    dispatch_async(openGLESContextQueue, ^{
        if (isSceneReady)
        {
       
        [EAGLContext setCurrentContext:context];
		//        CFTimeInterval previousTimestamp = CFAbsoluteTimeGetCurrent();

		[scene update];
		
		[scene render];
       // printf("%d BOOL\n",isSceneReady);
  		[self presentRenderBuffer];
		// Discarding is only supported starting with 4.0, so I need to do a check here for 3.2 devices
        const GLenum discards[]  = {GL_COLOR_ATTACHMENT0};
        glDiscardFramebufferEXT(GL_FRAMEBUFFER, 1, discards);
		//        CFTimeInterval frameDuration = CFAbsoluteTimeGetCurrent() - previousTimestamp;
		//        
		//        NSLog(@"Frame duration: %f ms", frameDuration * 1000.0);
        }
        dispatch_semaphore_signal(frameRenderingSemaphore);
    });
	
	
	
}

@end