//
//  BenthosScrollViewController.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 5/22/12.
//  Copyright (c) 2012 Sunset Lake Software LLC. All rights reserved.
//

#import "BenthosHelpScrollViewController.h"
#import "BenthosAppDelegate.h"
#import "BenthosSearchViewController.h"
@implementation BenthosHelpScrollViewController
@synthesize scrollView;
-(id) init
{
    if ([BenthosAppDelegate isRunningOniPad])
    {
        //			self.MapView.backgroundColor = [UIColor blackColor];
        //			tableTextColor = [[UIColor whiteColor] retain];
        self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
        
        UIBarButtonItem *downloadButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(displayMoleculeDownloadView)];
        self.navigationItem.leftBarButtonItem = downloadButtonItem;
        [downloadButtonItem release];
    }
    else
    {
        //			tableTextColor = [[UIColor blackColor] retain];
        UIBarButtonItem *modelButtonItem = [[UIBarButtonItem alloc] initWithTitle:NSLocalizedStringFromTable(@"3D Model", @"Localized", nil) style:UIBarButtonItemStylePlain target:self action:@selector(switchBackToGLView)];
        self.navigationItem.leftBarButtonItem = modelButtonItem;
        [modelButtonItem release];
        
    }
	return self;

}
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    CGRect bounds;
    if ([BenthosAppDelegate isRunningOniPad]){
        
        bounds  = CGRectMake(0, 
                             0,
                             self.contentSizeForViewInPopover.width, 
                             self.view.bounds.size.height);
    }else{
        bounds=[[UIScreen mainScreen] bounds];
    }
    
    scrollView =  [[UIScrollView alloc] initWithFrame:bounds];
    [scrollView setScrollEnabled:NO];

    [scrollView setMaximumZoomScale:1.0f];
    [scrollView setMinimumZoomScale:1.0f];
    [scrollView setDelegate:self];


    NSArray *imgArray=[[NSArray alloc]initWithObjects:@"drag-flick",@"spread",@"finger-drag-down",@"double-tap",nil]; 
    NSArray *titleArray=[[NSArray alloc]initWithObjects:@"Drag",@"Pinch",@"Two Finger Drag",@"Double Tap",nil]; 
    NSArray *subtitleArray=[[NSArray alloc]initWithObjects:@"Pan the model across the screen",
                                                        @"Zoom in and out",
                                                        @"Tilt the model",
                                                        @"Center and zoom the model on the tapped point",
                                                        nil]; 

    UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(5, 5 ,0,0 )];
    title.text=@"Interaction Help";
    [title setFont:[UIFont boldSystemFontOfSize:18]];

    [title sizeToFit];
    int y=5;

    y+=title.frame.size.height;
    [scrollView addSubview:title];
    [title  release];
    y+=5;

    for(int i=0;i<[imgArray count];i++)
    {
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[imgArray objectAtIndex:i]]];
        CGRect frame = tempImageView.frame;
        frame.origin.y=y;
        float ratio=(0.25)/(frame.size.width /bounds.size.width );
        frame.size.width*=ratio;
        frame.size.height*=ratio;
        

        tempImageView.frame = frame;
        float labelOffsetX=10.0;
        float labelOffsetY=10.0;

        UILabel *title = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width+labelOffsetX, y+labelOffsetY ,bounds.size.width-(frame.size.width+labelOffsetX),30 )];
        [title setBackgroundColor:[UIColor clearColor]];
        [title setFont:[UIFont boldSystemFontOfSize:18]];
        [title setText:[titleArray objectAtIndex:i]];
        [title setTextColor:[UIColor blackColor]];
        [title setNumberOfLines:0];
        [title sizeToFit];
        [scrollView    addSubview:title];
        
        UILabel *subtitle = [[UILabel alloc]initWithFrame:CGRectMake(frame.size.width+labelOffsetX, title.frame.origin.y+title.frame.size.height ,bounds.size.width-(frame.size.width+labelOffsetX),frame.size.height )];
        [subtitle setBackgroundColor:[UIColor clearColor]];
        [subtitle setFont:[UIFont fontWithName:@"Helvetica" size:14]];
        [subtitle setText:[subtitleArray objectAtIndex:i]];
        [subtitle setTextColor:[UIColor blackColor]];
        [subtitle setNumberOfLines:0];
        [subtitle sizeToFit];

        [scrollView    addSubview:subtitle];
        
        [title  release];
        [subtitle release];      
        y+=tempImageView.frame.size.height;
        [scrollView addSubview:tempImageView];
        [tempImageView release];
    }

    
    scrollView.backgroundColor = [UIColor whiteColor];
    
    [scrollView setContentSize:CGSizeMake(bounds.size.width, y)];

    [imgArray release];
    [titleArray release];
    [subtitleArray release];

    [self.view addSubview:scrollView];

}

- (IBAction)switchBackToGLView;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
}

- (IBAction)displayMoleculeDownloadView;
{
    BenthosSearchViewController *searchViewController = [[BenthosSearchViewController alloc] initWithStyle:UITableViewStylePlain];
    
    [self.navigationController pushViewController:searchViewController animated:YES];
    [searchViewController release];
    
    /*    
     BenthosDataSourceViewController *dataSourceViewController = [[BenthosDataSourceViewController alloc] initWithStyle:UIMapViewStylePlain];
     
     [self.navigationController pushViewController:dataSourceViewController animated:YES];
     [dataSourceViewController release];
     */
}

- (void)dealloc {
    [scrollView release];
    [super dealloc];
}

@end
