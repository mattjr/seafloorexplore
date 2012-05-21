//
//  BenthosCellTextView.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//	This class is based on Apple's example from the Recipes sample application, with only minor modifications

#import <UIKit/UIKit.h>

// cell identifier for this custom cell
extern NSString *kBenthosCellTextView_ID;

@interface BenthosCellTextView : UITableViewCell
{
    UITextView *view;
}

@property (nonatomic, retain) UITextView *view;

@end
