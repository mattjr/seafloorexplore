//
//  BenthosDetailViewController.h
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
//  Created by Brad Larson on 7/5/2008.
//

//  This controller manages the detail view of the model's properties, such as author, publication, etc.

#import <UIKit/UIKit.h>
#import <MapKit/MapKit.h>
#import "Model.h"
@class BenthosModel;

@interface BenthosDetailViewController : UITableViewController <MKAnnotation,MKMapViewDelegate> 
{
	BenthosModel *model;
    UITableViewCell *_mapCell;
    UITableViewCell *_imgCell;
    MKMapView *_mapView;
    CLPlacemark *_placemark;
    UIImage *detailImage;

	UILabel *nameLabel;	
}
@property (nonatomic, retain)     MKMapView *_mapView;

@property (nonatomic, retain) CLPlacemark *placemark;
@property (nonatomic, retain) UIImage *detailImage;
@property (nonatomic, retain) BenthosModel *model;
- (id)initWithStyle:(UITableViewStyle)style andBenthosModel:(BenthosModel *)newModel;
- (id)initWithStyle:(UITableViewStyle)style andDownloadedModel:(DownloadedModel *)newModel;

- (UILabel *)createLabelForIndexPath:(int)row;
- (NSString *)textForIndexPath:(int)row;
- (UITableViewCell *)cellForMapView;
- (UITableViewCell *)cellForImageView;

#pragma mark - MKAnnotation Protocol (for map pin)

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;

@end