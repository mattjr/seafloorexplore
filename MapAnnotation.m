//
//  MapAnnotation.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 3/28/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "MapAnnotation.h"

@implementation MapAnnotation

@synthesize coordinate,idx;

- (id)init {
	[super init];
    
	coordinate.latitude = 25;
	coordinate.longitude = 25;
	title = [NSString stringWithFormat:@"A Testing annotation"];
	[title retain];
	subtitle = [NSString stringWithFormat:@"selecting detection"];
	[subtitle retain];
	return self;
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