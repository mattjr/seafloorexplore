//
//  BenthosLibraryTableCell.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 4/30/2011.
//

#import "BenthosLibraryTableCell.h"

@implementation BenthosLibraryTableCell

#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier 
{
    if ((self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]))
	{
        isSelected = NO;
        // Initialization code
    }
    return self;
}

- (void)dealloc 
{
    [super dealloc];
}


//- (void)setSelected:(BOOL)selected animated:(BOOL)animated 
//{
//
//    [super setSelected:selected animated:animated];
//
//    // Configure the view for the selected state
//}

#pragma mark -
#pragma mark Accessors

@synthesize highlightGradientLayer;
@synthesize isSelected;

@end
