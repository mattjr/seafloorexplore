//
//  MapAnnotation.h
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 3/28/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <MapKit/MapKit.h>
@class Benthos;
@interface MapAnnotation : NSObject <MKAnnotation> {
	NSString *title;
	NSString *subtitle;
	CLLocationCoordinate2D coordinate;
    Benthos *model;
}

@property (nonatomic, readonly) CLLocationCoordinate2D coordinate;
@property (nonatomic,readonly) Benthos *model;
@property (nonatomic, copy) NSString *title; 
@property (nonatomic, copy) NSString *subtitle;
// Title and subtitle for use by selection UI.
- (NSString *)title;
- (NSString *)subtitle;
-(id)initWithCoordinate:(CLLocationCoordinate2D) c;
-(id)initWithCoordinate:(CLLocationCoordinate2D)c withName:(NSString*)name withModel:(Benthos*)mol;
- (CLLocationCoordinate2D) coordinate;

@end