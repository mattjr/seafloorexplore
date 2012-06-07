//
//  BenthosRootViewController.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages a root view into which the 3D view and the model table selection views and animated for the neat flipping effect

#import <UIKit/UIKit.h>
#import <sqlite3.h>
#import "SegmentsController.h"
@class BenthosGLViewController;
@class BenthosModel;
@class BenthosTableViewController;
@class BenthosMapViewController;
@class BenthosHelpScrollViewController;
@class Scene;
@interface BenthosRootViewController : UIViewController
{
	BenthosGLViewController *glViewController;
	UIButton *rotationButton;
	UINavigationController *tableNavigationController;
	BenthosTableViewController *tableViewController;
    BenthosMapViewController *mapViewController;
    BenthosHelpScrollViewController *helpviewController;

    SegmentsController     * segmentsController;
    UISegmentedControl     * segmentedControl;
	BenthosModel *bufferedModel, *previousModel;
	NSMutableArray *models;
    NSMutableArray *decompressingfiles;
	
	BOOL toggleViewDisabled;
	sqlite3 *database;


}

@property (nonatomic, retain) BenthosGLViewController *glViewController;
@property (nonatomic, readonly) UINavigationController *tableNavigationController;
@property (nonatomic, readonly) BenthosTableViewController *tableViewController;
@property (nonatomic, assign) sqlite3 *database;
@property (nonatomic, retain) NSMutableArray *models;
@property (nonatomic, retain) NSMutableArray *decompressingfiles;


@property (nonatomic, retain) SegmentsController     * segmentsController;
@property (nonatomic, retain) UISegmentedControl     * segmentedControl;
// Manage the switching of views
- (void)toggleView:(NSNotification *)note;

// Passthroughs for managing models
- (void)loadInitialModel;
- (void)selectedModelDidChange:(NSInteger)newModelIndex;
- (void)cancelModelLoading;
- (void)updateListOfModels;
- (void)customURLSelectedForModelDownload:(NSNotification *)note;
- (NSArray *)segmentViewControllers;
- (void)firstUserExperience;

// Manage the switching of rotation state
- (void)toggleRotationButton:(NSNotification *)note;


@end

