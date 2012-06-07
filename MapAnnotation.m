//
//  MapAnnotation.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 3/28/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "MapAnnotation.h"

#import "Benthos.h"
@implementation MapAnnotation

@synthesize coordinate, title, subtitle,filenameWithoutExtension;

- (id)initWithCoordinate:(CLLocationCoordinate2D) c {
    coordinate = c;
    title = @"Title";
    subtitle = @"Subtitle";
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)c withName:(NSString*)name withModel:(BenthosModel*)mol {
    self = [super init];
    if (self) {
        coordinate = c;
        title = name;
        filenameWithoutExtension = [NSString stringWithString:[mol filenameWithoutExtension]];
    }
    return self;
}

- (CLLocationCoordinate2D) coordinate {
    return coordinate;
}
- (NSString *)title {
	return title;
}

- (NSString *)subtitle{
	return subtitle;
}

- (void)dealloc{
	[title release];
	[subtitle release];
	[super dealloc];
}

@end