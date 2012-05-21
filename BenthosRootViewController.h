//
//  BenthosRootViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages a root view into which the 3D view and the molecule table selection views and animated for the neat flipping effect

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "BenthosCustomDownloadViewController.h"
#import "SegmentsController.h"
@class BenthosGLViewController;
@class Benthos;
@class BenthosTableViewController;
@class BenthosMapViewController;
@class Scene;
@interface BenthosRootViewController : UIViewController
{
	BenthosGLViewController *glViewController;
	UIButton *rotationButton;
	UINavigationController *tableNavigationController;
	BenthosTableViewController *tableViewController;
    BenthosMapViewController *mapViewController;

    SegmentsController     * segmentsController;
    UISegmentedControl     * segmentedControl;
	Benthos *bufferedMolecule, *previousMolecule;
	NSMutableArray *molecules;
	
	BOOL toggleViewDisabled;
	sqlite3 *database;


}

@property (nonatomic, retain) BenthosGLViewController *glViewController;
@property (nonatomic, readonly) UINavigationController *tableNavigationController;
@property (nonatomic, readonly) BenthosTableViewController *tableViewController;
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, retain) NSMutableArray *molecules;


@property (nonatomic, retain) SegmentsController     * segmentsController;
@property (nonatomic, retain) UISegmentedControl     * segmentedControl;
// Manage the switching of views
- (void)toggleView:(NSNotification *)note;

// Passthroughs for managing molecules
- (void)loadInitialMolecule;
- (void)selectedMoleculeDidChange:(NSInteger)newMoleculeIndex;
- (void)cancelMoleculeLoading;
- (void)updateListOfMolecules;
- (void)customURLSelectedForMoleculeDownload:(NSNotification *)note;
- (NSArray *)segmentViewControllers;
- (void)firstUserExperience;

// Manage the switching of rotation state
- (void)toggleRotationButton:(NSNotification *)note;


@end

