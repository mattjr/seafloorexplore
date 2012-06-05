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
@synthesize progressView,textLabel,spinningIndicator;

- (id)initWithName:(NSString *)name{
	
    if ((self = [super init]))
	{
        filenameWithoutExtension=[name retain];
        progressView = [[[UIProgressView alloc] initWithFrame:CGRectZero] retain];
        textLabel = [[[UILabel alloc] init] retain];
        textLabel.text=[NSString stringWithFormat:@"Waiting to extract %@",filenameWithoutExtension];
        
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

    [textLabel release];
    self.textLabel = nil;
    
	[super dealloc];
}

@end
