//
//  BenthosScrollViewController.h
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 5/22/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface BenthosHelpScrollViewController : UIViewController <UIScrollViewDelegate>{
    UIScrollView* scrollView;

}
@property (nonatomic, retain) IBOutlet UIScrollView* scrollView;

@end
