//
//  Benthos+SDF.h
//  Molecules
//
//  Created by Brad Larson on 5/3/2011.
//  Copyright 2011 Sunset Lake Software LLC. All rights reserved.
//

#import "Benthos.h"

@interface Benthos (SDF)

- (BOOL)readFromSDFFileToDatabase:(NSError **)error;

@end
