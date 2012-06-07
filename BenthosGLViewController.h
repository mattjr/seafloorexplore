//
//  BenthosGLViewController.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  A controller for managing the OpenGL view of the model.

#import <UIKit/UIKit.h>
#import <OpenGLES/ES1/gl.h>
#import <QuartzCore/QuartzCore.h>

@class BenthosModel;
@class BenthosOpenGLESRenderer;
@class Scene;
@class Simulation;
@interface BenthosGLViewController : UIViewController <UIActionSheetDelegate>
{	
	// User interface elements
	UIActivityIndicatorView *scanningActivityIndicator;
	UIProgressView *renderingProgressIndicator;
	UILabel *renderingActivityLabel;
	UIActionSheet *visualizationActionSheet;

    BenthosOpenGLESRenderer *openGLESRenderer;
    Simulation *sim;
    Scene *scene;

	BenthosModel *modelToDisplay;
	BOOL isAutorotating;
	CADisplayLink *displayLink;
	CFTimeInterval previousTimestamp;
	BOOL shouldResizeDisplay;
	NSUInteger stepsSinceLastRotation;

	// Touch-handling 
	float startingTouchDistance, previousScale;
	float instantObjectScale, instantXRotation, instantYRotation, instantXTranslation, instantYTranslation, instantZTranslation;
	CGPoint lastMovementPosition, previousDirectionOfPanning;
	BOOL twoFingersAreMoving, pinchGestureUnderway;
	float zoomVal;

}

@property (readwrite, retain, nonatomic) UIActionSheet *visualizationActionSheet;
@property (readwrite, retain, nonatomic) BenthosModel *modelToDisplay;
@property (readwrite, retain, nonatomic) CADisplayLink *displayLink;
@property (readwrite, retain, nonatomic) BenthosOpenGLESRenderer *openGLESRenderer;

// Display indicator control
- (void)showScanningIndicator:(NSNotification *)note;
- (void)updateScanningIndicator:(NSNotification *)note;
- (void)hideScanningIndicator:(NSNotification *)note;
- (void)showRenderingIndicator:(NSNotification *)note;
- (void)updateRenderingIndicator:(NSNotification *)note;
- (void)hideRenderingIndicator:(NSNotification *)note;
- (void)switchVisType:(id)sender;
//- (void)reloadBackgroundDownloadedModels:(NSNotification *)note;
-(void)sendHome;
// Autorotation of model
- (void)startOrStopAutorotation:(BOOL)setTo;
- (void)handleAutorotationTimer;
- (void)stopAutorotate:(NSNotification *)note;

// OpenGL model rendering
- (void)resizeView;
- (void)runOpenGLBenchmarks;
- (void)updateSizeOfGLView:(NSNotification *)note;
- (void)stopRender;
- (void)startRender:(BenthosModel*)mol;

// Manage model rendering state
- (void)handleFinishOfModelRendering:(NSNotification *)note;
- (UIActionSheet *)actionSheetForVisualizationState;

// Touch handling
- (float)distanceBetweenTouches:(NSSet *)touches;
- (CGPoint)commonDirectionOfTouches:(NSSet *)touches;
- (void)handleTouchesEnding:(NSSet *)touches withEvent:(UIEvent *)event;

// Interface methods
- (IBAction)switchToTableView;


@end
