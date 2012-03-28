//
//  SLSMoleculeRootViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages a root view into which the 3D view and the molecule table selection views and animated for the neat flipping effect

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "SLSMoleculeCustomDownloadViewController.h"
#import "SegmentsController.h"
@class SLSMoleculeGLViewController;
@class SLSMolecule;
@class SLSMoleculeTableViewController;
@class SLSMoleculeMapViewController;
@class Scene;
@interface SLSMoleculeRootViewController : UIViewController
{
	SLSMoleculeGLViewController *glViewController;
	UIButton *rotationButton;
	UINavigationController *tableNavigationController;
	SLSMoleculeTableViewController *tableViewController;
    SLSMoleculeMapViewController *mapViewController;

    SegmentsController     * segmentsController;
    UISegmentedControl     * segmentedControl;
	SLSMolecule *bufferedMolecule, *previousMolecule;
	NSMutableArray *molecules;
	
	BOOL toggleViewDisabled;
	Scene *scene;
	sqlite3 *database;


}

@property (nonatomic, retain) SLSMoleculeGLViewController *glViewController;
@property (nonatomic, readonly) UINavigationController *tableNavigationController;
@property (nonatomic, readonly) SLSMoleculeTableViewController *tableViewController;
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
- (void)updateTableListOfMolecules;
- (void)customURLSelectedForMoleculeDownload:(NSNotification *)note;
- (NSArray *)segmentViewControllers;
- (void)firstUserExperience;

// Manage the switching of rotation state
- (void)toggleRotationButton:(NSNotification *)note;


@end

