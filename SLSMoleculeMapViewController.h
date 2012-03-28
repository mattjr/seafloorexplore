//
//  SLSMoleculeMapViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages the root table of molecules that are stored on the device

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>
#import <MapKit/MapKit.h>

#import "SLSMoleculeRootViewController.h"
#import "SLSMoleculeSearchViewController.h"
#import "SLSMoleculeDownloadController.h"
#import "SLSMoleculeDetailViewController.h"
#import "SLSMoleculeCustomDownloadViewController.h"
#import "MapAnnotation.h"

@interface SLSMoleculeMapViewController : UIViewController <MKMapViewDelegate>
{
	NSMutableArray *molecules;
	SLSMoleculeRootViewController *delegate;
	NSInteger selectedIndex;
	UIColor *tableTextColor;
    MKMapView *mapView;

	sqlite3 *database;
}
@property(nonatomic,retain) MKMapView *mapView;


@property(readwrite,assign) SLSMoleculeRootViewController *delegate;
@property(readwrite,assign) sqlite3 *database;
@property(readwrite,retain) NSMutableArray *molecules;
@property(readwrite) NSInteger selectedIndex;

// Initialization and teardown
- (id)init:(NSInteger)indexOfInitialMolecule withMolecules:(NSMutableArray*) mol_list;
- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;


- (IBAction)displayMoleculeDownloadView;
- (IBAction)switchBackToGLView;

- (void)moleculeDidFinishDownloading:(NSNotification *)note;

@end
