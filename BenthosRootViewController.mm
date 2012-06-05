//
//  BenthosRootViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages a root view into which the 3D view and the molecule table selection views and animated for the neat flipping effect

#import "BenthosAppDelegate.h"
#import "BenthosRootViewController.h"
#import "BenthosTableViewController.h"
#import "BenthosMapViewController.h"
#import "BenthosHelpScrollViewController.h"
#import "BenthosGLViewController.h"
#import "BenthosGLView.h"
#import "MyOpenGLES20Renderer.h"
#import "Benthos.h"
#include "Simulation.h"
#import "SegmentsController.h"
#import "NSArray+PerformSelector.h"
@implementation BenthosRootViewController

#pragma mark -
#pragma mark Initialiation and breakdown

- (id)init; 
{	

    if ((self = [super init])) 
	{
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleView:) name:@"ToggleView" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(toggleRotationButton:) name:@"ToggleRotationSelected" object:nil];
		[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(customURLSelectedForMoleculeDownload:) name:@"CustomURLForMoleculeSelected" object:nil];
    }
   
    return self;
}

- (void)dealloc 
{
	[rotationButton release];
    [segmentedControl release];
    [segmentsController release];

    segmentedControl   = nil;
    segmentsController = nil;

	[tableViewController release];
	[glViewController release];
	[tableNavigationController release];
	[super dealloc];
}

- (void)loadView 
{
	CGRect mainScreenFrame = [[UIScreen mainScreen] applicationFrame];
	
	UIView *backgroundView = [[UIView alloc] initWithFrame:mainScreenFrame];
	backgroundView.backgroundColor = [UIColor blackColor];
		
	self.view = backgroundView;
	[backgroundView release];
	toggleViewDisabled = NO;

    
	BenthosGLViewController *viewController = [[BenthosGLViewController alloc] initWithNibName:nil bundle:nil];
	self.glViewController = viewController;
	[viewController release];
	
	[self.view addSubview:glViewController.view];
	
	UIButton *infoButton = [[UIButton buttonWithType:UIButtonTypeInfoLight] retain];
	infoButton.frame = CGRectMake(320.0f - 70.0f, 460.0f - 70.0f, 70.0f, 70.0f);
	[infoButton addTarget:glViewController action:@selector(switchToTableView) forControlEvents:(UIControlEventTouchUpInside | UIControlEventTouchUpOutside)];
	[glViewController.view addSubview:infoButton];
	[infoButton release];
	
	rotationButton = [UIButton buttonWithType:UIButtonTypeCustom];
	
	UIImage *rotationImage = [UIImage imageNamed:@"Paint.png"];
	if (rotationImage == nil)
	{
		rotationImage = [[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"Paint" ofType:@"png"]] autorelease];
	}
	[rotationButton setImage:rotationImage forState:UIControlStateNormal];
	
	UIImage *selectedRotationImage = [UIImage imageNamed:@"PaintOn.png"];
	if (selectedRotationImage == nil)
	{
		selectedRotationImage = [[[UIImage alloc] initWithContentsOfFile:[[NSBundle mainBundle] pathForResource:@"PaintOn" ofType:@"png"]] autorelease];
	}
	[rotationButton setImage:selectedRotationImage forState:UIControlStateSelected];
	
	rotationButton.showsTouchWhenHighlighted = YES;
	[rotationButton addTarget:glViewController action:@selector(switchVisType:) forControlEvents:UIControlEventTouchUpInside];
	rotationButton.frame = CGRectMake(0.0f, 460.0f - 70.0f, 70.0f, 70.0f);
	rotationButton.clipsToBounds = NO;
    rotationButton.selected=NO;
	[glViewController.view addSubview:rotationButton];
}

- (void)toggleView:(NSNotification *)note;
{	
	if (molecules == nil)
		return;
	
	UIView *tableView = self.tableNavigationController.view;
	BenthosGLView *glView = (BenthosGLView *)glViewController.view;
	
	[UIView beginAnimations:nil context:NULL];
	[UIView setAnimationDuration:1];
	[UIView setAnimationTransition:([glView superview] ? UIViewAnimationTransitionFlipFromRight : UIViewAnimationTransitionFlipFromLeft) forView:self.view cache:YES];
	
	if ([glView superview] != nil) 
	{
		[self cancelMoleculeLoading];
		[tableNavigationController viewWillAppear:YES];
		[glViewController viewWillDisappear:YES];
		[glView removeFromSuperview];
		[self.view addSubview:tableView];
		[glViewController viewDidDisappear:YES];
		[tableNavigationController viewDidAppear:YES];
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleDefault];
	} 
	else 
	{
        [glViewController startOrStopAutorotation:YES];
		[glViewController viewWillAppear:YES];
		[tableNavigationController viewWillDisappear:YES];
		[tableView removeFromSuperview];
		[self.view addSubview:glView];
		
		[tableNavigationController viewDidDisappear:YES];
		[glViewController viewDidAppear:YES];
		if (bufferedMolecule != previousMolecule)
		{
			previousMolecule = bufferedMolecule;
			glViewController.moleculeToDisplay = bufferedMolecule;
		}
		else
			previousMolecule.isBeingDisplayed = YES;
		[[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackOpaque];
        
	}
	[UIView commitAnimations];
}

#pragma mark -
#pragma mark Passthroughs for managing molecules

- (void)loadInitialMolecule;
{
	NSInteger indexOfInitialMolecule = [[NSUserDefaults standardUserDefaults] integerForKey:@"indexOfLastSelectedMolecule"];
	if (indexOfInitialMolecule >= [molecules count])
	{
		indexOfInitialMolecule = 0;
	}
	
	if ([molecules count] > 0)
	{
		glViewController.moleculeToDisplay = [molecules objectAtIndex:indexOfInitialMolecule];

        [glViewController startRender:glViewController.moleculeToDisplay];
        [glViewController startOrStopAutorotation:YES];

	}
 
		
}
- (void)selectedMoleculeDidChange:(NSInteger)newMoleculeIndex;
{

	if (newMoleculeIndex >= [molecules count])
	{
		newMoleculeIndex = 0;		
	}

	[[NSUserDefaults standardUserDefaults] setInteger:newMoleculeIndex forKey:@"indexOfLastSelectedMolecule"];
	[[NSUserDefaults standardUserDefaults] synchronize];
	
	tableViewController.selectedIndex = newMoleculeIndex;
	// Defer sending the change message to the OpenGL view until the view is loaded, to make sure that rendering occurs only then
	if ([molecules count] == 0)
	{
        [mapViewController setSelectedMolecule:nil];

		bufferedMolecule = nil;
     //   NSLog(@"No Render Situation\n");
        [glViewController stopRender];


	}
	else
	{

      //  if(bufferedMolecule != nil)
            [glViewController stopRender];
             
        Benthos *tmp=[molecules objectAtIndex:newMoleculeIndex];
        [mapViewController setSelectedMolecule:tmp];

        [glViewController startRender:tmp];
		bufferedMolecule = [molecules objectAtIndex:newMoleculeIndex];
	}
}
/*- (void)loadModel:(NSString *)name{
     NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory =[paths objectAtIndex:0];
    
    
    //if(documentsDirectory != nil)
    //  printf("NIL %s\n",[documentsDirectory UTF8String]);
    
    NSString *fullpath=[documentsDirectory stringByAppendingPathComponent:name];

	if(scene == nil)
		scene = [Scene sharedScene];
    
	id sim = [[[Simulation alloc] initwithstring:fullpath] autorelease];//[[[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init] autorelease];
    printf("Sim create finish\n");
    NSLog(@"Ballz\n");
	if (sim)
        [scene setSimulator:sim];
	else
        fatal("Error: there is no valid simulation class");
}*/
#pragma mark -
#pragma mark UIViewController methods

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
	// Only allow free autorotation on the iPad
	if ([BenthosAppDelegate isRunningOniPad])
	{
		return YES;
	}
	else
	{
		return (interfaceOrientation == UIInterfaceOrientationPortrait);
	}
}

- (void)didReceiveMemoryWarning 
{
}

- (void)cancelMoleculeLoading;
{
	if (!glViewController.moleculeToDisplay.isDoneRendering)
	{
		glViewController.moleculeToDisplay.isRenderingCancelled = YES;
		[NSThread sleepForTimeInterval:0.1];
	}
}

- (void)updateListOfMolecules;
{
	UITableView *tableView = (UITableView *)tableViewController.view;
	[tableView reloadData];
    
   // MKMapView *mapView = (MKMapView *)mapViewController.view;
//	[mapView removeAllAnnotations];
    //[mapView setCenterCoordinate:mapView.region.center animated:NO];
}


#pragma mark -
#pragma mark Manage the switching of rotation state

- (void)toggleRotationButton:(NSNotification *)note;
{
    dispatch_async(dispatch_get_main_queue(), ^{

	if ([[note object] boolValue])
	{
		rotationButton.selected = NO;
	}
	else
	{
		rotationButton.selected = YES;
	}
    });
}

- (void)customURLSelectedForMoleculeDownload:(NSNotification *)note;
{
	NSURL *customURLForMoleculeDownload = [note object];
	
	bufferedMolecule = nil;
	
	if (![BenthosAppDelegate isRunningOniPad])
	{
		[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
	}
	//molecules://www.sunsetlakesoftware.com/sites/default/files/xenonPump.pdb
	//html://www.sunsetlakesoftware.com/sites/default/files/xenonPump.pdb
	
	NSString *pathComponentForCustomURL = [[customURLForMoleculeDownload host] stringByAppendingString:[customURLForMoleculeDownload path]];
	NSString *customMoleculeHandlingURL = [NSString stringWithFormat:@"molecules://%@", pathComponentForCustomURL];

//	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:customMoleculeHandlingURL]];
	[(BenthosAppDelegate *)[[UIApplication sharedApplication] delegate] handleCustomURLScheme:[NSURL URLWithString:customMoleculeHandlingURL]];
}

#pragma mark -
#pragma mark Accessors

@synthesize tableNavigationController;
@synthesize tableViewController;
@synthesize glViewController;
@synthesize database;
@synthesize molecules;
@synthesize segmentsController, segmentedControl;
@synthesize decompressingfiles;

- (void)setDatabase:(sqlite3 *)newValue
{
	database = newValue;
	tableViewController.database = database;
}

- (void)setMolecules:(NSMutableArray *)newValue;
{
	if (molecules == newValue)
	{
		return;
	}
	
	[molecules release];
	molecules = [newValue retain];
	tableViewController.molecules = molecules;
    mapViewController.molecules = molecules;
    helpviewController.molecules = molecules;

	NSInteger indexOfInitialMolecule = [[NSUserDefaults standardUserDefaults] integerForKey:@"indexOfLastSelectedMolecule"];
	if (indexOfInitialMolecule >= [molecules count])
	{
		indexOfInitialMolecule = 0;
        mapViewController.selectedMolecule = nil;

	}else {
        mapViewController.selectedMolecule = [molecules objectAtIndex:indexOfInitialMolecule];
    }
	
	tableViewController.selectedIndex = indexOfInitialMolecule;

}

- (void)setDecompressingfiles:(NSMutableArray *)newValue;
{
	if (decompressingfiles == newValue)
	{
		return;
	}
	
	[decompressingfiles release];
	decompressingfiles = [newValue retain];
	tableViewController.decompressingfiles = decompressingfiles;
    mapViewController.decompressingfiles = decompressingfiles;
	helpviewController.decompressingfiles = decompressingfiles;

}


- (UINavigationController *)tableNavigationController;
{

	if (tableNavigationController == nil)
	{
		bufferedMolecule = nil;
		tableNavigationController = [[UINavigationController alloc] init];
      

		if ([BenthosAppDelegate isRunningOniPad])
		{
			tableNavigationController.navigationBar.barStyle = UIBarStyleBlackOpaque;
		}

		NSInteger indexOfInitialMolecule = [[NSUserDefaults standardUserDefaults] integerForKey:@"indexOfLastSelectedMolecule"];
		if (indexOfInitialMolecule >= [molecules count])
			indexOfInitialMolecule = 0;
		tableViewController = [[BenthosTableViewController alloc] initWithStyle:UITableViewStylePlain initialSelectedMoleculeIndex:indexOfInitialMolecule];
        
        mapViewController = [[BenthosMapViewController alloc] init:indexOfInitialMolecule withMolecules:molecules];
        mapViewController.database = database;
        mapViewController.title=@"Map";
        
        helpviewController = [[BenthosHelpScrollViewController alloc] init];
        helpviewController.title=@"Help";

		tableViewController.database = database;
		tableViewController.molecules = molecules;
        mapViewController.molecules = molecules;
        tableViewController.decompressingfiles= decompressingfiles;
        helpviewController.decompressingfiles= decompressingfiles;

        tableViewController.decompressingfiles= decompressingfiles;

		[tableNavigationController pushViewController:tableViewController animated:NO];
		tableViewController.delegate = self;
		
		// Need to correct the view rectangle of the navigation view to correct for the status bar gap
		UIView *tableView = tableNavigationController.view;
		CGRect tableFrame = tableView.frame;
		tableFrame.origin.y -= 20;
		tableView.frame = tableFrame;
        // Need to correct the view rectangle of the navigation view to correct for the status bar gap
		UIView *mapView = mapViewController.view;
		mapView.frame = tableFrame;

		toggleViewDisabled = NO;		
        
        
       
		mapViewController.delegate = self;
		
		
        
        NSArray * viewControllers = [self segmentViewControllers];
        
        segmentsController = [[SegmentsController alloc] initWithNavigationController:tableNavigationController viewControllers:viewControllers];
        
        segmentedControl = [[UISegmentedControl alloc] initWithItems:[viewControllers arrayByPerformingSelector:@selector(title)]];
        segmentedControl.segmentedControlStyle = UISegmentedControlStyleBar;
        
        [self.segmentedControl addTarget:self.segmentsController
                                  action:@selector(indexDidChangeForSegmentedControl:)
                        forControlEvents:UIControlEventValueChanged];
        [self firstUserExperience];

	}
	
	return tableNavigationController;
}


#pragma mark -
#pragma mark Segment Content

- (NSArray *)segmentViewControllers {
    
    NSArray * viewControllers = [NSArray arrayWithObjects:tableViewController, mapViewController,helpviewController, nil];
    
    return viewControllers;
}

- (void)firstUserExperience {
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentsController indexDidChangeForSegmentedControl:self.segmentedControl];
}


@end
