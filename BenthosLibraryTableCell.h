//
//  BenthosLibraryTableCell.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
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
