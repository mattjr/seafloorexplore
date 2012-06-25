//
//  BenthosScrollViewController.h
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 5/22/12.
//  Copyright (c) 2012 SeafloorExplore Development. All rights reserved.
//

#import <UIKit/UIKit.h>
@class LRLinkableLabel;
@interface BenthosHelpScrollViewController : UIViewController <UIScrollViewDelegate>{
    UIScrollView* scrollView;
    NSMutableArray *models;
    NSMutableArray *decompressingfiles;


}
@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;
@property(readwrite,retain) NSMutableArray *models;
@property(readwrite,retain) NSMutableArray *decompressingfiles;
- (void) linkableLabel:(LRLinkableLabel *)label clickedButton:(UIButton *)button forURL:(NSURL *)url;
- (IBAction)displayModelDownloadView;
- (IBAction)switchBackToGLView;
@end
