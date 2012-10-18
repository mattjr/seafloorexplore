//
//  BenthosScrollViewController.m
//  Benthos
//
//  Created by Matthew Johnson-Roberson on 5/22/12.
//  Copyright (c) 2012 SeafloorExplore Development. All rights reserved.
//

#import "BenthosHelpScrollViewController.h"
#import "BenthosAppDelegate.h"
#import "BenthosFolderViewController.h"
#import "LRLinkableLabel.h"

@implementation BenthosHelpScrollViewController
@synthesize decompressingfiles,scrollView,models;
-(id) init
{
    self = [super init];
    if(self){
        models=nil;
        if ([BenthosAppDelegate isRunningOniPad])
        {
            //			self.MapView.backgroundColor = [UIColor blackColor];
            //			tableTextColor = [[UIColor whiteColor] retain];
            self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
            
            UIBarButtonItem *downloadButtonItem = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemAdd target:self action:@selector(displayModelDownloadView)];
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
    }
	return self;

}
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    return YES;
}
- (void)viewDidLoad
{
    [super viewDidLoad];
    [self.view setAutoresizingMask:(UIViewAutoresizingFlexibleWidth | UIViewAutoresizingFlexibleHeight)];

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
    [scrollView setScrollEnabled:YES];

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
    int y=5;
        
    UILabel *title=[[UILabel alloc]initWithFrame:CGRectMake(5, y ,0,0 )];
    title.text=@"Interaction Help";
    [title setFont:[UIFont boldSystemFontOfSize:18]];

    [title sizeToFit];

    y+=title.frame.size.height;
    [scrollView addSubview:title];
    [title  release];
    y+=5;
    float targetRatio= 0.18;
    for(int i=0;i<[imgArray count];i++)
    {
        
        UIImageView *tempImageView = [[UIImageView alloc] initWithImage:[UIImage imageNamed:[imgArray objectAtIndex:i]]];
        CGRect frame = tempImageView.frame;
        frame.origin.y=y;
        float ratio=(targetRatio)/(frame.size.width /bounds.size.width );
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

    CGFloat labelPadding = 5.0;
    
    UILabel *about=[[UILabel alloc]initWithFrame:CGRectMake(5, y ,0,0 )];
    about.text=@"About";
    [about setFont:[UIFont boldSystemFontOfSize:18]];
    
    [about sizeToFit];
    
    y+=about.frame.size.height;
    [scrollView addSubview:about];
    [about  release];
    
    NSArray *aboutTxt= [NSArray arrayWithObjects:@"Written by Matthew Johnson-Roberson find out more about my work http://bit.ly/mattjr",
                        @"Thanks to the support of the Australian Centre of Field Robotics (ACFR) http://marine.acfr.usyd.edu.au where you can learn more about ongoing marine robotics research.",@"Built with help from the generous open source contributions of Molecules (Sunset Lake Software) and LibVT (Julian Mayer).",@"Financial support from the ACFR and the Australian Research Council.        ",nil];
    
    for(NSString *txtVal in aboutTxt){
        CGSize bodySize = [txtVal sizeWithFont:[UIFont fontWithName:@"Helvetica" size:12.0] 
                             constrainedToSize:CGSizeMake(bounds.size.width-2*labelPadding,CGFLOAT_MAX) lineBreakMode:UILineBreakModeWordWrap];
        LRLinkableLabel *label = [[LRLinkableLabel alloc] initWithFrame:CGRectMake(labelPadding,y+labelPadding,bodySize.width,bodySize.height)];
        
        label.text =txtVal;
        
        label.font=[UIFont fontWithName:@"Helvetica" size:12.0];
        label.autoresizingMask = (UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight);
        label.tag = 1;
        label.linkColor=[UIColor blueColor];
        label.delegate = self;
        
        [label sizeToFit];
        [scrollView addSubview:label];
        [label release];
        
        y+=label.frame.size.height+5;
    }
    y+=5.0f;
    
    UIImageView *acfrIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"acfr"]];
    CGRect frame = acfrIV.frame;
    frame.origin.y=y;
    float ratio=(0.4)/(frame.size.width /bounds.size.width );
    frame.size.width*=ratio;
    frame.size.height*=ratio;
    frame.origin.x+=20.0f;
    
    acfrIV.frame = frame;
    [scrollView addSubview:acfrIV];
    [acfrIV release];
    
    UIImageView *arcIV = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"arc"]];
    frame = arcIV.frame;
    frame.origin.y=y;
    ratio=(0.4)/(frame.size.width /bounds.size.width );
    frame.size.width*=ratio;
    frame.size.height*=ratio;
    frame.origin.x += acfrIV.frame.size.width + 20.0f +acfrIV.frame.origin.x ;
    
    arcIV.frame = frame;
    [scrollView addSubview:arcIV];
    [arcIV release];
    
    y+=arcIV.frame.size.height;
    

    y+=80.0f;
    scrollView.backgroundColor = [UIColor whiteColor];
    
    [scrollView setContentSize:CGSizeMake(bounds.size.width, y)];

    [imgArray release];
    [titleArray release];
    [subtitleArray release];

    [self.view addSubview:scrollView];

}
- (void) linkableLabel:(LRLinkableLabel *)label clickedButton:(UIButton *)button forURL:(NSURL *)url {
    [[UIApplication sharedApplication] openURL:url];
}

- (IBAction)switchBackToGLView;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
}

- (IBAction)displayModelDownloadView;
{
    BenthosFolderViewController *folderViewController = [[BenthosFolderViewController alloc] initWithStyle:UITableViewStylePlain];
    folderViewController.models = models;
    folderViewController.decompressingfiles = decompressingfiles;

    [self.navigationController pushViewController:folderViewController animated:YES];
    [folderViewController release];
    
    /*    
     BenthosDataSourceViewController *dataSourceViewController = [[BenthosDataSourceViewController alloc] initWithStyle:UIMapViewStylePlain];
     
     [self.navigationController pushViewController:dataSourceViewController animated:YES];
     [dataSourceViewController release];
     */
}

- (void)dealloc {
    [models release];
    [scrollView release];
    [super dealloc];
}

@end
