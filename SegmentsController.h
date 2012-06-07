//
//  SegmentsController.h
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 3/27/12.
//  Copyright (c) 2012 SeafloorExplore Development. All rights reserved.
//

#import <Foundation/Foundation.h>

@interface SegmentsController : NSObject {
    NSArray                * viewControllers;
    UINavigationController * navigationController;
}

@property (nonatomic, retain, readonly) NSArray                * viewControllers;
@property (nonatomic, retain, readonly) UINavigationController * navigationController;

- (id)initWithNavigationController:(UINavigationController *)aNavigationController
                   viewControllers:(NSArray *)viewControllers;

- (void)indexDidChangeForSegmentedControl:(UISegmentedControl *)aSegmentedControl;

@end