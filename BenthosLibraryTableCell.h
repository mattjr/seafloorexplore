//
//  BenthosLibraryTableCell.h
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
//  Created by Brad Larson on 4/30/2011.
//

#import <UIKit/UIKit.h>
#import <QuartzCore/QuartzCore.h>

@interface BenthosLibraryTableCell : UITableViewCell 
{
    CAGradientLayer *highlightGradientLayer;
    BOOL isSelected;
}

@property(assign, nonatomic) CAGradientLayer *highlightGradientLayer;
@property(assign, nonatomic) BOOL isSelected;

@end
