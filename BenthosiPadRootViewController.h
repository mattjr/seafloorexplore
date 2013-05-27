//
//  BenthosiPadRootViewController.h
//  SeafloorExplore
//
//  Modified from Brad Larson's Molecules Project in 2011-2012 for use in The SeafloorExplore Project
//
//  Copyright (C) 2012 Matthew Johnson-Roberson
//
//  See COPYING for license details
//  
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See COPYING for details.
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
