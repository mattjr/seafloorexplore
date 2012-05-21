//
//  BenthosiPadRootViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
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
	UIPopoverController *downloadOptionsPopover, *moleculeTablePopover;
	
	UIScreen *externalScreen;
	
	UIWindow *externalWindow;
}

// Bar response methods
//- (void)showMolecules:(id)sender;
- (void)showVisualizationModes:(id)sender;
- (void)showDownloadOptions:(id)sender;

// External monitor support
- (void)handleConnectionOfMonitor:(NSNotification *)note;
- (void)handleDisconnectionOfMonitor:(NSNotification *)note;
- (void)displayOnExternalOrLocalScreen:(id)sender;
- (void)sendHome:(id)sender;

@end
