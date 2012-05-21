//
//  BenthosGLView.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 5/18/2008.
//
//  This view manages the OpenGL scene, with setup and rendering methods.  Multitouch events are also handled
//  here, although it might be best to refactor some of the code up to a controller.


#import <QuartzCore/QuartzCore.h>
#import <OpenGLES/EAGLDrawable.h>
#import "BenthosOpenGLES11Renderer.h"
#import "BenthosOpenGLES20Renderer.h"

#import "BenthosGLView.h"
#import "Benthos.h"
#import "MyOpenGLES20Renderer.h"
@implementation BenthosGLView

// Override the class method to return the OpenGL layer, as opposed to the normal CALayer
+ (Class) layerClass 
{
	return [CAEAGLLayer class];
}

#pragma mark -
#pragma mark Initialization and breakdown

- (id)initWithFrame:(CGRect)aRect
{
	if ((self = [super initWithFrame:aRect])) 
	{
		self.multipleTouchEnabled = YES;
		self.opaque = YES;
        
        previousSize = aRect.size;
		
		// Set scaling to account for Retina display	
		if ([self respondsToSelector:@selector(setContentScaleFactor:)])
		{
			self.contentScaleFactor = [[UIScreen mainScreen] scale];
		}
		
		// Do OpenGL Core Animation layer setup
		CAEAGLLayer *eaglLayer = (CAEAGLLayer *)self.layer;
		
		eaglLayer.opaque = YES;
		eaglLayer.drawableProperties = [NSDictionary dictionaryWithObjectsAndKeys:
										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGBA8, kEAGLDrawablePropertyColorFormat, nil];
//										[NSNumber numberWithBool:NO], kEAGLDrawablePropertyRetainedBacking, kEAGLColorFormatRGB565, kEAGLDrawablePropertyColorFormat, nil];
		
		
        EAGLContext *aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
//        aContext = nil;
        
       /* if (!aContext) 
        {
            aContext = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES1];
            openGLESRenderer = [[BenthosOpenGLES11Renderer alloc] initWithContext:aContext];
        }
        else*/
        {
            openGLESRenderer = [[MyOpenGLES20Renderer alloc] initWithContext:aContext];
        }

        [aContext release];
        
        [openGLESRenderer createFramebuffersForLayer:eaglLayer];
        [openGLESRenderer clearScreen];
	}
	return self;
}


#pragma mark -
#pragma mark UIView methods

- (void)layoutSubviews 
{
    CGSize newSize = self.bounds.size;
  //  printf("New Size %f %f\n",newSize.width,newSize.height);
    if (!CGSizeEqualToSize(newSize, previousSize))
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"GLViewSizeDidChange" object:nil];
        previousSize = newSize;
    }
}

#pragma mark -
#pragma mark Accessors

@synthesize openGLESRenderer;

@end
