 //
//  BenthosGLViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  A barebones controller for managing the OpenGL view of the molecule.  It's pretty sparse, as some of the methods in the view really belong here.

#import "BenthosGLViewController.h"
#import "BenthosGLView.h"
#import "Benthos.h"
#import "BenthosAppDelegate.h"
//#import "BenthosOpenGLESRenderer.h"
#import "BenthosOpenGLES20Renderer.h"
#include "MyOpenGLES20Renderer.h"
#include "Simulation.h"
#include "Scene.h"
//#define RUN_OPENGL_BENCHMARKS

@implementation BenthosGLViewController

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil 
{
	if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) 
	{
		// Set up an observer that catches the molecule update notifications and shows and updates the rendering indicator
		NSNotificationCenter *nc = [NSNotificationCenter defaultCenter];
		[nc addObserver:self selector:@selector(showRenderingIndicator:) name:kBenthosRenderingStartedNotification object:nil];
		[nc addObserver:self selector:@selector(updateRenderingIndicator:) name:kBenthosRenderingUpdateNotification object:nil];
		[nc addObserver:self selector:@selector(hideRenderingIndicator:) name:kBenthosRenderingEndedNotification object:nil];
		
		[nc addObserver:self selector:@selector(showScanningIndicator:) name:kBenthosLoadingStartedNotification object:nil];
		[nc addObserver:self selector:@selector(updateScanningIndicator:) name:kBenthosLoadingUpdateNotification object:nil];
		[nc addObserver:self selector:@selector(hideScanningIndicator:) name:kBenthosLoadingEndedNotification object:nil];

		[nc addObserver:self selector:@selector(updateSizeOfGLView:) name:@"GLViewSizeDidChange" object:nil];

        [nc addObserver:self selector:@selector(stopAutorotate:) name:@"UnhookAutoRotate" object:nil];
       /* [nc addObserver:self
                                                 selector:@selector(reloadBackgroundDownloadedModels:)
                                                     name:UIApplicationDidBecomeActiveNotification object:nil];
*/
		isAutorotating = YES;
		
		// Initialize values for the touch interaction
		previousScale = 1.0f;
		instantObjectScale = 1.0f;
		instantXRotation = 1.0f;
		instantYRotation = 0.0f;
		instantXTranslation = 0.0f;
		instantYTranslation = 0.0f;
		instantZTranslation = 0.0f;
		twoFingersAreMoving = NO;
		pinchGestureUnderway = NO;
		stepsSinceLastRotation = 0;
		previousTimestamp = 0;
		
		[[NSUserDefaults standardUserDefaults] setInteger:TEXTURED forKey:@"currentVisualizationMode"];

		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(handleFinishOfMoleculeRendering:) name:@"MoleculeRenderingEnded" object:nil];	
		
	}
	return self;
}

- (void)dealloc 
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	[self.displayLink invalidate];
	self.displayLink = nil;
	[super dealloc];
}
- (void)stopAutorotate:(NSNotification *)note{
    [self startOrStopAutorotation:NO];
}
- (void)loadView 
{
	CGRect applicationFrame = [[UIScreen mainScreen] applicationFrame];
	
	BenthosGLView *glView = [[BenthosGLView alloc] initWithFrame:CGRectMake(0.0f, 0.0f, applicationFrame.size.width, applicationFrame.size.height)];

	self.view = glView;
    openGLESRenderer = glView.openGLESRenderer;

	[glView release];
}

#pragma mark -
#pragma mark Display indicator control
/*- (void)reloadBackgroundDownloadedModels:(NSNotification *)note;
{
    printf("Reload downloaded models\n");
    sleep(10);
}*/
- (void)showScanningIndicator:(NSNotification *)note;
{
	if (scanningActivityIndicator != nil)
	{
		[scanningActivityIndicator removeFromSuperview];
		[scanningActivityIndicator release];
		scanningActivityIndicator = nil;		
	}
	
	scanningActivityIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
	scanningActivityIndicator.frame = CGRectMake(round(self.view.frame.size.width / 2.0f - 37.0f / 2.0f), round(self.view.frame.size.height / 2.0f + 15.0f), 37.0f, 37.0f);
	scanningActivityIndicator.hidesWhenStopped = YES;
	[scanningActivityIndicator startAnimating];

	if (renderingActivityLabel != nil)
	{
		[renderingActivityLabel removeFromSuperview];
		[renderingActivityLabel release];
		renderingActivityLabel = nil;
	}
	
	renderingActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(round(self.view.frame.size.width / 2.0f - 219.0f / 2.0f), round(self.view.frame.size.height / 2.0f - 15.0f - 21.0f), 219.0f, 21.0f)];
	renderingActivityLabel.font = [UIFont systemFontOfSize:17.0f];
	renderingActivityLabel.text = [note object];
	renderingActivityLabel.textAlignment = UITextAlignmentCenter;
	renderingActivityLabel.backgroundColor = [UIColor clearColor];
	renderingActivityLabel.textColor = [UIColor whiteColor];
	
	[self.view addSubview:scanningActivityIndicator];
	[self.view addSubview:renderingActivityLabel];
}

- (void)updateScanningIndicator:(NSNotification *)note;
{
	
}

- (void)hideScanningIndicator:(NSNotification *)note;
{
	[renderingActivityLabel removeFromSuperview];
	[renderingActivityLabel release];
	renderingActivityLabel = nil;
	
	[scanningActivityIndicator removeFromSuperview];
	[scanningActivityIndicator release];
	scanningActivityIndicator = nil;
}

- (void)showRenderingIndicator:(NSNotification *)note;
{
	if (renderingProgressIndicator != nil)
	{
		[renderingProgressIndicator removeFromSuperview];
		[renderingProgressIndicator release];
		renderingProgressIndicator = nil;
	}
	
	float renderingIndicatorWidth = round(self.view.frame.size.width * 0.6);
	renderingProgressIndicator = [[UIProgressView alloc] initWithFrame:CGRectMake(round(self.view.frame.size.width / 2.0f - renderingIndicatorWidth / 2.0f), round(self.view.frame.size.height / 2.0f + 15.0f), renderingIndicatorWidth, 9.0f)];
	[renderingProgressIndicator setProgress:0.0f];
    renderingProgressIndicator.progressViewStyle = UIProgressViewStyleBar;
	
	if (renderingActivityLabel != nil)
	{
		[renderingActivityLabel removeFromSuperview];
		[renderingActivityLabel release];
		renderingActivityLabel = nil;
	}
	
	renderingActivityLabel = [[UILabel alloc] initWithFrame:CGRectMake(round(self.view.frame.size.width / 2.0f - 219.0f / 2.0f), round(self.view.frame.size.height / 2.0f - 15.0f - 21.0f), 219.0f, 21.0f)];
	renderingActivityLabel.font = [UIFont systemFontOfSize:17.0f];
	renderingActivityLabel.text = NSLocalizedStringFromTable(@"Rendering...", @"Localized", nil);
	renderingActivityLabel.textAlignment = UITextAlignmentCenter;
	renderingActivityLabel.backgroundColor = [UIColor clearColor];
	renderingActivityLabel.textColor = [UIColor whiteColor];

	[openGLESRenderer clearScreen];
	[renderingProgressIndicator setProgress:0.0];
	[self.view addSubview:renderingProgressIndicator];
	[self.view addSubview:renderingActivityLabel];
}

- (void)updateRenderingIndicator:(NSNotification *)note;
{
	float percentComplete = [(NSNumber *)[note object] floatValue];
	
//	if ((percentComplete - renderingProgressIndicator.progress) > 0.01f)
//	{
		renderingProgressIndicator.progress = percentComplete;
//	}
}

- (void)hideRenderingIndicator:(NSNotification *)note;
{
	[renderingActivityLabel removeFromSuperview];
	[renderingProgressIndicator removeFromSuperview];

	[renderingActivityLabel release];
	renderingActivityLabel = nil;
	
	[renderingProgressIndicator release];
	renderingProgressIndicator = nil;
}
- (void)switchVisType:(id)sender;
{

GLVisualizationType currentVisualizationType = [sim getRenderMode];
    GLVisualizationType newVisualizationType;
    if (currentVisualizationType == TEXTURED){
    newVisualizationType=SHADED;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:YES]];

    }
    else{
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:NO]];

        newVisualizationType=TEXTURED;
    }
    BOOL resetAR=isAutorotating;
    if (isAutorotating)
	{
		[self startOrStopAutorotation:NO];
        [openGLESRenderer waitForLastFrameToFinishRendering];
	}
		
	moleculeToDisplay.isBeingDisplayed = NO;
  

    
    
    
    
    
    [sim setRenderMode: newVisualizationType];
    
    
    //   moleculeToDisplay.currentVisualizationType = newVisualizationType;
    [[NSUserDefaults standardUserDefaults] setInteger:newVisualizationType forKey:@"currentVisualizationMode"];
    moleculeToDisplay.isBeingDisplayed = YES;

    //[openGLESRenderer freeVertexBuffers];
    [moleculeToDisplay performSelectorInBackground:@selector(renderMolecule:) withObject:openGLESRenderer];
    if(resetAR)
        [self startOrStopAutorotation:YES];

}


#pragma mark -
#pragma mark Autorotation of molecule

- (void)startOrStopAutorotation:(BOOL)setTo;
{
    isAutorotating= !setTo;
    
	if (isAutorotating)
	{
        [self.displayLink invalidate];
        self.displayLink = nil;
		//printf("Not autorating now\n");
		//[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:NO]];
	}
	else
	{
		previousTimestamp = 0;
		CADisplayLink *aDisplayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(handleAutorotationTimer)];
		[aDisplayLink setFrameInterval:1];
		[aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSDefaultRunLoopMode];
//		[aDisplayLink addToRunLoop:[NSRunLoop currentRunLoop] forMode:NSRunLoopCommonModes];
        
		self.displayLink = aDisplayLink;
     //  printf("Autorating now\n");

		//[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:YES]];
	}
	isAutorotating = !isAutorotating;
}

- (void)handleAutorotationTimer;
{
	if (shouldResizeDisplay)
	{
		[self resizeView];
		shouldResizeDisplay = NO;
	}
	if (previousTimestamp == 0)
	{
        [openGLESRenderer rotateModelFromScreenDisplacementInX:1.0f inY:0.0f];
	}
	else
	{
        [openGLESRenderer rotateModelFromScreenDisplacementInX:(30.0f * (displayLink.timestamp - previousTimestamp)) inY:0.0f];
	}
    
    [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];        
	
	previousTimestamp = displayLink.timestamp;
}

#pragma mark -
#pragma mark OpenGL molecule rendering
-(void)sendHome{
    if ([[scene simulator] respondsToSelector:@selector(resetCamera)])
           [(Simulation *)[scene simulator] resetCamera];
}
- (void)resizeView;
{
    [openGLESRenderer clearScreen];
//	[EAGLContext setCurrentContext:glView.context];
	[openGLESRenderer destroyFramebuffers];
	[openGLESRenderer createFramebuffersForLayer:(CAEAGLLayer *)self.view.layer];
	//if (displayLink == nil)
   /* if ([openGLESRenderer isKindOfClass:[MyOpenGLES20Renderer class]])
        [(MyOpenGLES20Renderer*)openGLESRenderer reshapeScenes];

	{*/    moleculeToDisplay.hasRendered=NO;

      //  [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];
	//}
   
}

- (void)runOpenGLBenchmarks;
{
	NSLog(NSLocalizedStringFromTable(@"Triangles: %d", @"Localized", nil), openGLESRenderer.totalNumberOfTriangles);
	NSLog(NSLocalizedStringFromTable(@"Vertices: %d", @"Localized", nil), openGLESRenderer.totalNumberOfVertices);
	CFAbsoluteTime elapsedTime, startTime = CFAbsoluteTimeGetCurrent();
#define NUMBER_OF_FRAMES_FOR_TESTING 100
	
	for (unsigned int testCounter = 0; testCounter < NUMBER_OF_FRAMES_FOR_TESTING; testCounter++)
	{
		// Do something		
        [openGLESRenderer rotateModelFromScreenDisplacementInX:1.0f inY:0.0];
        [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];
	}
	elapsedTime = CFAbsoluteTimeGetCurrent() - startTime;
	// ElapsedTime contains seconds (or fractions thereof as decimals)
	NSLog(NSLocalizedStringFromTable(@"Elapsed time: %f", @"Localized", nil), elapsedTime);
	NSLog(@"Triangles per second: %f", (CGFloat)openGLESRenderer.totalNumberOfTriangles * (CGFloat)NUMBER_OF_FRAMES_FOR_TESTING / elapsedTime);
}

- (void)updateSizeOfGLView:(NSNotification *)note;
{
//	if (displayLink == nil)
//	{
	//	[self resizeView];
//	}
//	else
//	{
		//shouldResizeDisplay = YES;
        BOOL currentAutorotate=isAutorotating;
        [self startOrStopAutorotation:NO];
        [openGLESRenderer waitForLastFrameToFinishRendering];
        [self resizeView];
        if(!currentAutorotate)
            [(MyOpenGLES20Renderer*)openGLESRenderer setRemoveOnceRender:YES];
        [self startOrStopAutorotation:YES];
      

//	}
}

#pragma mark -
#pragma mark Manage molecule rendering state

- (void)handleFinishOfMoleculeRendering:(NSNotification *)note;
{
	[openGLESRenderer clearScreen];
	[NSThread sleepForTimeInterval:0.1];

    [openGLESRenderer resetModelViewMatrix];
	
#ifdef RUN_OPENGL_BENCHMARKS
    
    [self.displayLink invalidate];
    self.displayLink = nil;
    
//    [[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleRotationSelected" object:[NSNumber numberWithBool:NO]];
	[NSThread sleepForTimeInterval:0.2];

    
    [self runOpenGLBenchmarks];
#else
    if (!isAutorotating)
    {
        [self startOrStopAutorotation:YES];	
    }
#endif	
}

- (UIActionSheet *)actionSheetForVisualizationState;
{
	NSString *buttonTitle1;
//	NSString *buttonTitle2;
	NSString *cancelButtonTitle;
	GLVisualizationType currentVisualizationType = [sim getRenderMode];

	switch (currentVisualizationType)
	{
		case TEXTURED:
		{
			buttonTitle1 = NSLocalizedStringFromTable(@"Shaded", @"Localized", nil);
//			buttonTitle2 = NSLocalizedStringFromTable(@"Cylinders", @"Localized", nil);
			cancelButtonTitle = NSLocalizedStringFromTable(@"Ball-and-stick", @"Localized", nil);
		}; break;
		case SHADED:
		{
			buttonTitle1 = NSLocalizedStringFromTable(@"Textured", @"Localized", nil);
//			buttonTitle2 = NSLocalizedStringFromTable(@"Cylinders", @"Localized", nil);
			cancelButtonTitle = NSLocalizedStringFromTable(@"Spacefilling", @"Localized", nil);
		}; break;
		default:
		{
			buttonTitle1 = NSLocalizedStringFromTable(@"Shaded", @"Localized", nil);
//			buttonTitle2 = NSLocalizedStringFromTable(@"Cylinders", @"Localized", nil);
			cancelButtonTitle = NSLocalizedStringFromTable(@"Ball-and-stick", @"Localized", nil);
		};
	}
	
	NSString *titleForActionSheet = NSLocalizedStringFromTable(@"Visualization mode", @"Localized", nil);
	if ([BenthosAppDelegate isRunningOniPad])
	{
		titleForActionSheet = nil;
//		cancelButtonTitle = nil;
	}
	
	UIActionSheet *actionSheet = [[UIActionSheet alloc] initWithTitle:titleForActionSheet
                                                             delegate:self cancelButtonTitle:cancelButtonTitle destructiveButtonTitle:nil
                                                    otherButtonTitles:buttonTitle1, nil];
//otherButtonTitles:buttonTitle1, buttonTitle2, nil];
	if ([BenthosAppDelegate isRunningOniPad])
    {
        actionSheet.actionSheetStyle = UIActionSheetStyleAutomatic;
    }
    else
    {
        actionSheet.actionSheetStyle = UIActionSheetStyleBlackTranslucent;
    }
	return [actionSheet autorelease];
}

#pragma mark -
#pragma mark Touch handling

- (float)distanceBetweenTouches:(NSSet *)touches;
{
	int currentStage = 0;
	CGPoint point1 = CGPointZero;
	CGPoint point2 = CGPointZero;
	
	
	for (UITouch *currentTouch in touches)
	{
		if (currentStage == 0)
		{
			point1 = [currentTouch locationInView:self.view];
			currentStage++;
		}
		else if (currentStage == 1) 
		{
			point2 = [currentTouch locationInView:self.view];
			currentStage++;
		}
		else
		{
		}
	}
	return (sqrt((point1.x - point2.x) * (point1.x - point2.x) + (point1.y - point2.y) * (point1.y - point2.y)));
}

- (CGPoint)commonDirectionOfTouches:(NSSet *)touches;
{
	// Check to make sure that both fingers are moving in the same direction
	
	int currentStage = 0;
	CGPoint currentLocationOfTouch1 = CGPointZero, currentLocationOfTouch2 = CGPointZero, previousLocationOfTouch1 = CGPointZero, previousLocationOfTouch2 = CGPointZero;
	
	
	for (UITouch *currentTouch in touches)
	{
		if (currentStage == 0)
		{
			previousLocationOfTouch1 = [currentTouch previousLocationInView:self.view];
			currentLocationOfTouch1 = [currentTouch locationInView:self.view];
			currentStage++;
		}
		else if (currentStage == 1) 
		{
			previousLocationOfTouch2 = [currentTouch previousLocationInView:self.view];
			currentLocationOfTouch2 = [currentTouch locationInView:self.view];
			currentStage++;
		}
		else
		{
		}
	}
	
	CGPoint directionOfTouch1, directionOfTouch2, commonDirection;
	// The sign of the Y touches is inverted, due to the inverted coordinate system of the iPhone
	directionOfTouch1.x = currentLocationOfTouch1.x - previousLocationOfTouch1.x;
	directionOfTouch1.y = previousLocationOfTouch1.y - currentLocationOfTouch1.y;
	directionOfTouch2.x = currentLocationOfTouch2.x - previousLocationOfTouch2.x;
	directionOfTouch2.y = previousLocationOfTouch2.y - currentLocationOfTouch2.y;	
	
	// A two-finger movement should result in the direction of both touches being positive or negative at the same time in X and Y
	if (!( ((directionOfTouch1.x <= 0) && (directionOfTouch2.x <= 0)) || ((directionOfTouch1.x >= 0) && (directionOfTouch2.x >= 0)) ))
		return CGPointZero;
	if (!( ((directionOfTouch1.y <= 0) && (directionOfTouch2.y <= 0)) || ((directionOfTouch1.y >= 0) && (directionOfTouch2.y >= 0)) ))
		return CGPointZero;
	
	// The movement ranges are averaged out 
	commonDirection.x = ((directionOfTouch1.x + directionOfTouch2.x) / 2.0f);
	commonDirection.y = ((directionOfTouch1.y + directionOfTouch2.y) / 2.0f);
	

	return commonDirection;
}

- (void)touchesBegan:(NSSet *)touches withEvent:(UIEvent *)event
{
	//if (isAutorotating)
		//[self startOrStopAutorotation:nil];

    NSMutableSet *currentTouches = [[[event touchesForView:self.view] mutableCopy] autorelease];
    [currentTouches minusSet:touches];

    [sim setValidPos];

	// New touches are not yet included in the current touches for the view
	NSSet *totalTouches = [touches setByAddingObjectsFromSet:[event touchesForView:self.view]];
	if ([totalTouches count] > 1)
	{
		startingTouchDistance = [self distanceBetweenTouches:totalTouches];
		previousScale = 1.0f;
		twoFingersAreMoving = NO;
		pinchGestureUnderway = NO;
		previousDirectionOfPanning = CGPointZero;
	}
	else
	{
		lastMovementPosition = [[touches anyObject] locationInView:self.view];
       // if ([[scene simulator] respondsToSelector:@selector(pan:)])
       //     [(Simulation *)[scene simulator] startPan];
        [sim pancont:lastMovementPosition];

	}
}

- (void)touchesMoved:(NSSet *)touches withEvent:(UIEvent *)event;
{
	/*if (isAutorotating)
	{
		[self startOrStopAutorotation:nil];
	}*/

	if ([[event touchesForView:self.view] count] > 1) // Pinch gesture, possibly two-finger movement
	{
		CGPoint directionOfPanning = CGPointZero;
		
		// Two finger panning
		if ([touches count] > 1) // Check to make sure that both fingers are moving
		{
			directionOfPanning = [self commonDirectionOfTouches:touches];
		}
		
		if ( (directionOfPanning.x != 0) || (directionOfPanning.y != 0) ) // Don't scale while doing the two-finger panning
		{
			if (pinchGestureUnderway)
			{
				
				
				if (sqrt(previousDirectionOfPanning.x * previousDirectionOfPanning.x + previousDirectionOfPanning.y * previousDirectionOfPanning.y) > 0.1 )
				{
					pinchGestureUnderway = NO;
				}
				previousDirectionOfPanning.x += directionOfPanning.x;
				previousDirectionOfPanning.y += directionOfPanning.y;
			}
			if (!pinchGestureUnderway)
			{
				twoFingersAreMoving = YES;
            	[sim orient: directionOfPanning];
				//[openGLESRenderer translateModelByScreenDisplacementInX:directionOfPanning.x inY:directionOfPanning.y];
                [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];
			
				previousDirectionOfPanning = CGPointZero;
			}
		}
		else
		{
			float newTouchDistance = [self distanceBetweenTouches:[event touchesForView:self.view]];
			if (twoFingersAreMoving)
			{
				// If fingers have moved more than 10% apart, start pinch gesture again
				if ( fabs(1 - (newTouchDistance / startingTouchDistance) / previousScale) > 0.3 )
				{
					twoFingersAreMoving = NO;
				}
			}
			if (!twoFingersAreMoving)
			{
				if(!pinchGestureUnderway)
                    [sim zoomstart];
				float speedModifier=1.0;
                vector3f movement = vector3f(1,  speedModifier *(newTouchDistance / startingTouchDistance), 1);

				zoomVal=  (newTouchDistance / startingTouchDistance) / previousScale;
                [sim zoomcont:zoomVal];
				
				// Scale using pinch gesture
               // [openGLESRenderer scaleModelByFactor:(newTouchDistance / startingTouchDistance) / previousScale];
              //  [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];

//				[self _drawViewByRotatingAroundX:0.0 rotatingAroundY:0.0 scaling:(newTouchDistance / startingTouchDistance) / previousScale translationInX:directionOfPanning.x translationInY:directionOfPanning.y];
				previousScale = (newTouchDistance / startingTouchDistance);
				pinchGestureUnderway = YES;
			}
		}
	}
	else // Single-touch rotation of object
	{
		CGPoint currentMovementPosition = [[touches anyObject] locationInView:self.view];
        [openGLESRenderer rotateModelFromScreenDisplacementInX:(currentMovementPosition.x - lastMovementPosition.x) inY:(currentMovementPosition.y - lastMovementPosition.y)];
		CGPoint delta;

        delta.x=(currentMovementPosition.x-lastMovementPosition.x);///self.view.frame.size.width;
        delta.y=(currentMovementPosition.y-lastMovementPosition.y);///self.view.frame.size.height;		
		lastMovementPosition = currentMovementPosition;
		//printf("%f %f %f %f\n",delta.x,delta.y,(float)self.view.frame.size.width,(float)self.view.frame.size.height);
		[sim pan: lastMovementPosition];
        [openGLESRenderer renderFrameForMolecule:moleculeToDisplay];
				
	}
	
}
- (void)touchesEnded:(NSSet *)touches withEvent:(UIEvent *)event 
{	//int count=0;
   // if ([[scene simulator] respondsToSelector:@selector(pan:)])
     //   [(Simulation *)[scene simulator] checkIfOutOfBounds];
    
	/*if ([[scene simulator] respondsToSelector:@selector(isDoneMoving)] && !isAutorotating){
		while(![(Simulation *)[scene simulator]isDoneMoving]&& count <10){
			[openGLESRenderer renderFrameForMolecule:moleculeToDisplay];
			[openGLESRenderer waitForLastFrameToFinishRendering];
			count++;	
		}
	}*/
    MovementType logType;
    if(pinchGestureUnderway)
        logType=kZoom;
    else if([touches count]>1 && !pinchGestureUnderway)
        logType= kTilt;
    else {
        logType=kPanning;
    }

    
	[self handleTouchesEnding:touches withEvent:event];
   // [sim logCameraPosition];

	// This is placed here to avoid an infinite spawning of alerts under iPhone OS 4.0
	if (([[touches anyObject] tapCount] >= 2)/* && (![BenthosAppDelegate isRunningOniPad])*/)
	{
        CGPoint endPos = [[touches anyObject] locationInView:self.view];

       // if ([[scene simulator] respondsToSelector:@selector(resetCamera)])
         //   [(Simulation *)[scene simulator] resetCamera];
        [sim centeratPt:endPos];
        [sim setLogOnNextUpdate: kDoubleClick];

		/*if (moleculeToDisplay.isDoneRendering == YES)
		{
			UIActionSheet *actionSheet = [self actionSheetForVisualizationState];
			[actionSheet showInView:self.view];
		}*/		
	}else{
        [sim setLogOnNextUpdate: logType];

    }

}

- (void)touchesCancelled:(NSSet *)touches withEvent:(UIEvent *)event 
{
	[self handleTouchesEnding:touches withEvent:event];
}

- (void)handleTouchesEnding:(NSSet *)touches withEvent:(UIEvent *)event
{
	//if (isAutorotating)
	//	[self startOrStopAutorotation:nil];
	
    NSMutableSet *remainingTouches = [[[event touchesForView:self.view] mutableCopy] autorelease];
    [remainingTouches minusSet:touches];
	if ([remainingTouches count] < 2)
	{
		twoFingersAreMoving = NO;
		pinchGestureUnderway = NO;
		previousDirectionOfPanning = CGPointZero;
        [sim checkInFrame];
		lastMovementPosition = [[remainingTouches anyObject] locationInView:self.view];
        [sim pancont:lastMovementPosition];


	}	
}

#pragma mark -
#pragma mark Interface methods

- (IBAction)switchToTableView;
{
	if (moleculeToDisplay != nil && moleculeToDisplay.isDoneRendering == NO)
	{
		return;
	}
	
	if (isAutorotating)
	{
		[self startOrStopAutorotation:NO];
        [openGLESRenderer waitForLastFrameToFinishRendering];
	}

	[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
}

#pragma mark -
#pragma mark UIActionSheet delegate method

- (void)actionSheet:(UIActionSheet *)actionSheet clickedButtonAtIndex:(NSInteger)buttonIndex
{
	GLVisualizationType newVisualizationType = (GLVisualizationType)[[NSUserDefaults standardUserDefaults] integerForKey:@"currentVisualizationMode"];
	
	switch (newVisualizationType)
	{
		case TEXTURED:
		{
			if (buttonIndex == 0)
			{
				newVisualizationType = SHADED;
			}
//			else if (buttonIndex == 1)
//			{
//				newVisualizationType = CYLINDRICAL;
//			}
		}; break;
		case SHADED:
		{
			if (buttonIndex == 0)
			{
				newVisualizationType = TEXTURED;
			}
//			else if (buttonIndex == 1)
//			{
//				newVisualizationType = CYLINDRICAL;
//			}
		}; break;
	}
	
	GLVisualizationType currentVisualizationType = [sim getRenderMode];

    if (currentVisualizationType != newVisualizationType)
    {
       /* if (isAutorotating)
        {
            [self startOrStopAutorotation:self];
        }*/
		
		[sim setRenderMode: newVisualizationType];
			
		
     //   moleculeToDisplay.currentVisualizationType = newVisualizationType;
        [[NSUserDefaults standardUserDefaults] setInteger:newVisualizationType forKey:@"currentVisualizationMode"];
        
        [openGLESRenderer freeVertexBuffers];
        [moleculeToDisplay performSelectorInBackground:@selector(renderMolecule:) withObject:openGLESRenderer];
    }
    
	visualizationActionSheet = nil;
}

#pragma mark -
#pragma mark UIViewController methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Return YES for supported orientations
//	return (interfaceOrientation == UIInterfaceOrientationPortrait);
	return YES;
}

- (void)didReceiveMemoryWarning 
{
}

#pragma mark -
#pragma mark Accessors

@synthesize visualizationActionSheet;
@synthesize moleculeToDisplay;
@synthesize displayLink,openGLESRenderer;

- (void)setMoleculeToDisplay:(Benthos *)newMolecule;
{
	if (moleculeToDisplay == newMolecule)
	{
		return;
	}

	if (isAutorotating && 	/*Hack */![BenthosAppDelegate isRunningOniPad] )
	{
		[self startOrStopAutorotation:NO];
        [openGLESRenderer waitForLastFrameToFinishRendering];
	}
	
//	[NSThread sleepForTimeInterval:0.2];
	
	moleculeToDisplay.isBeingDisplayed = NO;
    if (!moleculeToDisplay.isRenderingCancelled)
    {
        [openGLESRenderer freeVertexBuffers];
    }
    
	[moleculeToDisplay release];
	moleculeToDisplay = [newMolecule retain];
    if ([openGLESRenderer isKindOfClass:[BenthosOpenGLES20Renderer class]])
    {
        [moleculeToDisplay switchToDefaultVisualizationMode];
        
    }
    else
    {
    //    moleculeToDisplay.currentVisualizationType = [[NSUserDefaults standardUserDefaults] integerForKey:@"currentVisualizationMode"];
    }
	
	GLVisualizationType renderMode = [sim getRenderMode];

	[[NSUserDefaults standardUserDefaults] setInteger:renderMode forKey:@"currentVisualizationMode"];
    
	moleculeToDisplay.isBeingDisplayed = YES;
    
    [moleculeToDisplay performSelectorInBackground:@selector(renderMolecule:) withObject:openGLESRenderer];
    
	instantObjectScale = 1.0f;
	instantXRotation = 1.0f;
	instantYRotation = 0.0f;
	instantXTranslation = 0.0f;
	instantYTranslation = 0.0f;
	instantZTranslation = 0.0f;
	
	[[NSUserDefaults standardUserDefaults] synchronize];
}
- (void)stopRender
{
   // printf("Stopping scene ready\n");
    if ([openGLESRenderer isKindOfClass:[MyOpenGLES20Renderer class]])
        [(MyOpenGLES20Renderer*)openGLESRenderer shutdownVT];
    else
        printf("Can't stop scene\n");
    [openGLESRenderer clearScreen];

   //[[scene simulator] release];
    // [openGLESRenderer destroyFramebuffers];
    sim= nil;

}

- (void)startRender:(Benthos*)mol;
{
   // printf("Starting scene ready\n");
    if ([openGLESRenderer isKindOfClass:[MyOpenGLES20Renderer class]])
        [(MyOpenGLES20Renderer*)openGLESRenderer startupVT:mol];
    else
        printf("Can't start scene\n");
 
    if ([openGLESRenderer isKindOfClass:[MyOpenGLES20Renderer class]]){
        sim = [(MyOpenGLES20Renderer*)openGLESRenderer sim];
        scene =[(MyOpenGLES20Renderer*)openGLESRenderer scene];
    }
}

@end
