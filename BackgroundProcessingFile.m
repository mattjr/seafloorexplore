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
@synthesize progressView,downloadStatusText,spinningIndicator;

- (id)initWithName:(NSString *)name{
	
    if ((self = [super init]))
	{
        filenameWithoutExtension=[name retain];
        progressView = [[[UIProgressView alloc] initWithFrame:CGRectZero] retain];
        downloadStatusText = [[[UILabel alloc] initWithFrame:CGRectZero] retain ];
        downloadStatusText.textColor = [UIColor blackColor];
        downloadStatusText.font = [UIFont boldSystemFontOfSize:16.0];
        downloadStatusText.textAlignment = UITextAlignmentLeft;
        downloadStatusText.text=[NSString stringWithFormat:@"Waiting to extract %@",filenameWithoutExtension];
        
        spinningIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] retain];
    }
    
    return self;
}
-(void) dealloc
{
    [filenameWithoutExtension release];
    filenameWithoutExtension=nil;
    [progressView release];
    progressView=nil;
    [spinningIndicator release];
    self.spinningIndicator = nil;

    [downloadStatusText release];
    self.downloadStatusText = nil;
    
	[super dealloc];
}

@end
