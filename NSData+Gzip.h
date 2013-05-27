//
//  NSData+Gzip.h
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
//  Created by Brad Larson on 7/1/2008.
//
//  This extension is adapted from the examples present at the CocoaDevWiki at http://www.cocoadev.com/index.pl?NSDataCategory

#import <Foundation/Foundation.h>


@interface NSData (Gzip)
- (id)initWithGzippedData: (NSData *)gzippedData;
- (NSData *) gzipDeflate;

@end