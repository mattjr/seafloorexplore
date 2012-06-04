//
//  BackgroundProcessingFile.h
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 6/4/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface BackgroundProcessingFile : NSObject{
    NSString *filenameWithoutExtension;
    UIProgressView *progressView;
    UILabel *downloadStatusText;
    UIActivityIndicatorView *spinningIndicator;
}
@property (nonatomic, retain) NSString *filenameWithoutExtension;
@property(nonatomic, retain)UIProgressView * progressView;
@property(nonatomic, retain)UILabel *downloadStatusText;
@property(nonatomic, retain)UIActivityIndicatorView *spinningIndicator;

- (id)initWithName:(NSString *)name;

@end
