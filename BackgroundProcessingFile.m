//
//  BackgroundProcessingFile.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 6/4/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "BackgroundProcessingFile.h"

@implementation BackgroundProcessingFile
@synthesize filenameWithoutExtension;
@synthesize progressView,text,spinningIndicator;

- (id)initWithName:(NSString *)name{
	
    if ((self = [super init]))
	{
        filenameWithoutExtension=[name retain];
        progressView = [[[UIProgressView alloc] initWithFrame:CGRectZero] retain];
        text=[[[NSString alloc] initWithFormat:@"Waiting to extract %@",filenameWithoutExtension] retain];
        
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

    [text release];
    self.text = nil;
    
	[super dealloc];
}

@end
