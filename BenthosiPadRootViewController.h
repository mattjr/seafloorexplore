//
//  BenthosiPadRootViewController.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 2/20/2010.
//

#import "BenthosRootViewController.h"

@class UIPopoverController;

@interface BenthosiPadRootViewController : BenthosRootViewController <UISplitViewControllerDelegate, UIPopoverControllerDelegate>
{
	UIImage *unselectedRotationImage, *selectedRotationImage;
	UIBarButtonItem *rotationBarButton, *spacerItem, *visualizationBarButton, *screenBarButton;
	UIToolbar *mainToolbar;
	UIPopoverController *downloadOptionsPopover, *modelTablePopover;
	
	UIScreen *externalScreen;
	
	UIWindow *externalWindow;
}

// Bar response methods
//- (void)showModels:(id)sender;
- (void)showVisualizationModes:(id)sender;

// External monitor support
- (void)handleConnectionOfMonitor:(NSNotification *)note;
- (void)handleDisconnectionOfMonitor:(NSNotification *)note;
- (void)displayOnExternalOrLocalScreen:(id)sender;
- (void)sendHome:(id)sender;

@end
