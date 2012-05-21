//
//  BenthosDetailViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/5/2008.
//
//  This controller manages the detail view of the molecule's properties, such as author, publication, etc.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Model.h"
@class Benthos;

@interface BenthosDetailViewController : UITableViewController <MKAnnotation> 
{
	Benthos *molecule;
    UITableViewCell *_mapCell;
    CLPlacemark *_placemark;

	UILabel *nameLabel;	
}
@property (nonatomic, retain) CLPlacemark *placemark;

@property (nonatomic, retain) Benthos *molecule;
- (id)initWithStyle:(UITableViewStyle)style andMolecule:(Benthos *)newMolecule;
- (id)initWithStyle:(UITableViewStyle)style andModel:(Model *)newModel;

- (UILabel *)createLabelForIndexPath:(NSIndexPath *)indexPath;
- (NSString *)textForIndexPath:(NSIndexPath *)indexPath;
- (UITableViewCell *)cellForMapView;

#pragma mark - MKAnnotation Protocol (for map pin)

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end