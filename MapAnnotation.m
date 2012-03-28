//
//  MapAnnotation.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 3/28/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize coordinate, title, subtitle,idx;

- (id)initWithCoordinate:(CLLocationCoordinate2D) c {
    coordinate = c;
    title = @"Title";
    subtitle = @"Subtitle";
    return self;
}

-(id)initWithCoordinate:(CLLocationCoordinate2D)c withName:(NSString*)name withIndex:(NSInteger)index {
    self = [super init];
    if (self) {
        coordinate = c;
        title = name;
        idx = index;
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