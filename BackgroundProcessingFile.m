//
//  BackgroundProcessingFile.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 6/4/12.
//  Copyright (c) 2012 SeafloorExplore Development. All rights reserved.
//

#import "BackgroundProcessingFile.h"

@implementation BackgroundProcessingFile
@synthesize filenameWithoutExtension;
@synthesize progressView,spinningIndicator;

- (id)initWithName:(NSString *)name{
	
    if ((self = [super init]))
	{
        filenameWithoutExtension=[name retain];
        progressView = [[[UIProgressView alloc] initWithFrame:CGRectZero] retain];
        progressView.hidden=YES;
        spinningIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] retain];
    }
    
    return self;
}
-(void) dealloc
{
    progressView.hidden=YES;
    [filenameWithoutExtension release];
    filenameWithoutExtension=nil;
    [progressView release];
    progressView=nil;
    [spinningIndicator release];
    self.spinningIndicator = nil;

	[super dealloc];
}

@end
