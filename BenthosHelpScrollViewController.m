//
//  BenthosScrollViewController.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 5/22/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "BenthosHelpScrollViewController.h"

@implementation BenthosHelpScrollViewController
@synthesize scrollView;

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect bounds = self.view.bounds;
    
    scrollView = [[UIScrollView alloc] initWithFrame: self.view.frame];
    [scrollView setScrollEnabled:YES];

    [scrollView setMaximumZoomScale:1.0f];
    [scrollView setMinimumZoomScale:1.0f];
    [scrollView setDelegate:self];


    int y=0;
    NSArray *imgArray=[[NSArray alloc]initWithObjects:@"drag-flick",@"double-tap",@"finger-drag-down",@"spread",nil]; 
    NSArray *labelArray=[[NSArray alloc]initWithObjects:@"drag-flick",@"double-tap",@"finger-drag-down",@"spread",nil]; 

    UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(0, 0 ,0,0 )];
    title.text=@"Interaction";
    [title sizeToFit];
    
    y+=title.frame.size.height;
    [scrollView addSubview:title];

    for(int i=0;i<[imgArray count];i++)
    {
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[imgArray objectAtIndex:i]]];
        CGRect frame = tempImageView.frame;
        frame.origin.y=y;
        tempImageView.frame = frame;

        UILabel *languageLabel=[[UILabel alloc]initWithFrame:CGRectMake(0, y ,90,30 )];
        languageLabel.text=[labelArray objectAtIndex:i];
        languageLabel.font=[UIFont systemFontOfSize:19.0];
        languageLabel.backgroundColor=[UIColor clearColor];
        [scrollView addSubview:tempImageView];

      //  [scrollView addSubview:languageLabel];
        //  [languageScrollView addSubview:languageLabel];
        //y+=90;        
        y+=tempImageView.frame.size.height;
        [languageLabel release];
        
    }

    //self.imageView = tempImageView;
    
    //scrollView.backgroundColor = [UIColor whiteColor];
    
    [scrollView setContentSize:CGSizeMake(bounds.size.width, y)];
    [imgArray release];
    [labelArray release];
    [self.view addSubview:scrollView];

}
- (void)dealloc {
    [scrollView release];
    [super dealloc];
}

@end
