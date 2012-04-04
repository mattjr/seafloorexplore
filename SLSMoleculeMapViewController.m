//
//  SLSMoleculeMapViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages the root table of molecules that are stored on the device

#import "SLSMoleculeMapViewController.h"
#import "SLSMoleculeRootViewController.h"
#import "SLSMoleculeDataSourceViewController.h"
#import "SLSMoleculeSearchViewController.h"
#import "SLSMolecule.h"
#import "SLSMoleculeAppDelegate.h"
#import "SLSMoleculeLibraryTableCell.h"
#import "NSFileManager+Tar.h"

@implementation SLSMoleculeMapViewController
@synthesize mapView,    selectedAnnotation,firstView;
;
#pragma mark -
#pragma mark Initialization and breakdown

- (id)init:(NSInteger)indexOfInitialMolecule withMolecules:(NSMutableArray*) mol_list
{
	if ((self = [super init])) 
	{        
        
		selectedIndex = indexOfInitialMolecule;
        molecules=mol_list;
        firstView=NO;
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(moleculeDidFinishDownloading:) name:@"MoleculeDidFinishDownloading" object:nil];

		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
            
		}
		
		if ([SLSMoleculeAppDelegate isRunningOniPad])
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
	}
	return self;
}

- (void)viewDidLoad;
{
	[super viewDidLoad];
    mapView = [[MKMapView alloc]
               initWithFrame:CGRectMake(0, 
                                        0,
                                        self.contentSizeForViewInPopover.width, 
                                        self.view.bounds.size.height)
               ];
    //mapView.showsUserLocation = YES;
    mapView.mapType = MKMapTypeHybrid;
    mapView.delegate = self;
    
   /*     //MKCoordinateRegion region =  MKCoordinateRegionMakeWithDistance(self.placemark.location.coordinate, 200, 200);
    CLLocationCoordinate2D AusLoc = {-19.048230,133.685730};
    MKCoordinateSpan AusSpan = MKCoordinateSpanMake(45, 45);
    MKCoordinateRegion AusRegion = MKCoordinateRegionMake(AusLoc, AusSpan);
    [mapView setRegion:AusRegion];*/

   
    [self.view addSubview:mapView];

	/*if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
		//		self.MapView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.054f alpha:1.0f];
		self.mapView.backgroundColor = [UIColor blackColor];
        self.MapView.separatorColor = [UIColor clearColor];
        self.MapView.rowHeight = 50.0;
    
//        CAGradientLayer *shadowGradient = [SLSMoleculeMapViewController shadowGradientForSize:CGSizeMake(320.0f, self.navigationController.view.frame.size.height)];
//		[self.navigationController.view.layer setMask:shadowGradient];
//		self.navigationController.view.layer.masksToBounds = NO;
	}
	else
	{
		self.MapView.backgroundColor = [UIColor whiteColor];
	}	*/

}
 -(void) viewDidAppear:(BOOL)animated {

     if(!firstView){
         [self doAnnotation];
         firstView=YES;
     }
         
     for (id <MKAnnotation> annotation in mapView.annotations){
         if ([annotation isKindOfClass:[MapAnnotation class]])
         {
             MapAnnotation *ma = (MapAnnotation *)annotation;
             if(ma.idx ==selectedIndex){
                 [mapView deselectAnnotation:annotation animated:NO];

                 [mapView selectAnnotation:annotation animated:YES];
                 
             }
         }

     
     }
}
-(void)mapView:(MKMapView *)mapView didDeselectAnnotationView:(MKAnnotationView *)view
{
    [self performSelector:@selector(reSelectAnnotationIfNoneSelected:) 
               withObject:view.annotation afterDelay:0];
}

- (void)reSelectAnnotationIfNoneSelected:(id<MKAnnotation>)annotation
{
    if (mapView.selectedAnnotations.count == 0)
        [mapView selectAnnotation:annotation animated:NO];
}
-(void) doAnnotation
{
    
    int idx=0;
    for(SLSMolecule * mol in molecules){
        MapAnnotation *ann =[[[MapAnnotation alloc] initWithCoordinate:mol.coord withName:mol.title withIndex:idx] autorelease];
        [mapView addAnnotation:ann];
        if(idx ==selectedIndex){
            [mapView selectAnnotation:ann animated:YES];
            self.selectedAnnotation=ann;
            
        }
        idx++;
    }
    
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, 0, 0);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }

    [mapView setVisibleMapRect:zoomRect animated:NO];

}
- (void)dealloc 
{
	[tableTextColor release];
	[molecules release];
	[super dealloc];
}

#pragma mark -
#pragma mark View switching

- (IBAction)switchBackToGLView;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
}

- (IBAction)displayMoleculeDownloadView;
{
    SLSMoleculeSearchViewController *searchViewController = [[SLSMoleculeSearchViewController alloc] initWithStyle:UITableViewStylePlain];
    
    [self.navigationController pushViewController:searchViewController animated:YES];
    [searchViewController release];

/*    
	SLSMoleculeDataSourceViewController *dataSourceViewController = [[SLSMoleculeDataSourceViewController alloc] initWithStyle:UIMapViewStylePlain];
	
	[self.navigationController pushViewController:dataSourceViewController animated:YES];
	[dataSourceViewController release];
 */
}
/*
- (void)moleculeDidFinishDownloading:(NSNotification *)note;
{
    if ([note object] == nil)
    {
        [self.navigationController popToViewController:self animated:YES];
        return;
    }
    
	NSString *filename = [note object];
	
	// Add the new protein to the list by gunzipping the data and pulling out the title
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Iterate through all files sitting in the application's Resources directory
    // TODO: Can you fast enumerate this?
    BOOL extractError=NO;
    if ([[filename pathExtension] isEqualToString:@"tar"])
        {
            NSString *archivePath = [documentsDirectory stringByAppendingPathComponent:filename ];

            NSString *installedTexPath = [documentsDirectory stringByAppendingPathComponent:[filename stringByDeletingPathExtension]];
            if (![fileManager fileExistsAtPath:installedTexPath])
            {
                NSData* tarData = [NSData dataWithContentsOfFile:archivePath];
                NSError *error=nil;
                [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:documentsDirectory withTarData:tarData error:&error];
                
                if (error != nil)
                {
                    NSLog(@"Failed to untar preinstalled files  with error: '%@'.", [error localizedDescription]);
                    // TODO: Report the file copying problem to the user or do something about it
                    extractError=YES;
                }else{
                    //Sucess delete tar
                 //   NSLog(@"Deleting %@\n",archivePath);
                    NSError *error2=nil;

                    if (![[NSFileManager defaultManager] removeItemAtPath:archivePath error:&error2])
                    {
                        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not delete file", @"Localized", nil) message:[error2 localizedDescription]
                                                                       delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
                        [alert show];
                        [alert release];					
                        return;
                    }
                }
                //}
            }else{
                NSLog(@"Folder already exists ERROR\n");
                extractError=YES;
            }
            
        }else{
            NSLog(@"Error Not tar file\n");
            extractError=YES;

        }

	SLSMolecule *newMolecule =nil;
    NSString *pname=[filename  stringByDeletingPathExtension ]   ;
    if(!extractError)
        newMolecule=[[SLSMolecule alloc] initWithFilename:pname  database:database title:[[note userInfo] objectForKey:@"title"]];
	if (newMolecule == nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error in downloaded file", @"Localized", nil) message:NSLocalizedStringFromTable(@"The molecule file is either corrupted or not of a supported format", @"Localized", nil)
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];
		
		// Delete the corrupted or sunsupported file
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSError *error = nil;
		if (![[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:&error])
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not delete file", @"Localized", nil) message:[error localizedDescription]
														   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
			[alert show];
			[alert release];					
			return;
		}
        NSLog(@"Removing corrupt file %@\n",filename );
        error = nil;
        NSString *folder=[filename stringByDeletingPathExtension];
		if (![[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:folder] error:&error])
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not delete file", @"Localized", nil) message:[error localizedDescription]
														   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
			[alert show];
			[alert release];					
			return;
		}
        NSLog(@"Removing corrupt folder %@\n",folder );


		
	}
	else
	{
		[molecules addObject:newMolecule];
		[newMolecule release];
		
        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
        {
            selectedIndex = ([molecules count] - 1);

            [self.delegate selectedMoleculeDidChange:selectedIndex];            
        }else{
        
            if ([molecules count] == 1)
            {
                [self.delegate selectedMoleculeDidChange:0];
            }
        }
        
       // [self.MapView reloadData];
//		[self.MapView insertRowsAtIndexPaths:[NSArray arrayWithObject:[NSIndexPath indexPathForRow:([molecules count] - 1) inSection:0]] withRowAnimation:UIMapViewRowAnimationBottom];		
	}			

	[self.navigationController popToViewController:self animated:YES];
}

*/
#pragma mark -
#pragma mark Table view data source delegate methods


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
{
    MapAnnotation *annotation = view.annotation;
    //NSString *temp = annotation.title;
    if(selectedIndex == annotation.idx)
        return;
    
    
    selectedIndex = annotation.idx;
    [self.delegate selectedMoleculeDidChange:annotation.idx];
    
}

/*- (void)MapView:(UIMapView *)MapView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = [indexPath row];
	if ([SLSMoleculeAppDelegate isRunningOniPad])
		index++;
	
	if (index == 0)
		[self displayMoleculeDownloadView];
	else
	{
		// Display detail view for the protein
		SLSMoleculeDetailViewController *detailViewController = [[SLSMoleculeDetailViewController alloc] initWithStyle:UIMapViewStyleGrouped andMolecule: [molecules objectAtIndex:(index - 1)]];
		
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
		
	}
}*/


- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
            // try to dequeue an existing pin view first
        NSString* AnnotationIdentifier = [[annotation title] stringByAppendingString:@"AnnotationIdentifier"] ;
        MKPinAnnotationView* pinView = (MKPinAnnotationView *)
        [mapView dequeueReusableAnnotationViewWithIdentifier:AnnotationIdentifier];
        if (!pinView)
        {
            // if an existing pin view was not available, create one
            MKPinAnnotationView* customPinView = [[[MKPinAnnotationView alloc]
                                                   initWithAnnotation:annotation reuseIdentifier:AnnotationIdentifier] autorelease];
            customPinView.pinColor = MKPinAnnotationColorRed;
            customPinView.animatesDrop = YES;
            customPinView.canShowCallout = YES;
            customPinView.enabled=YES;
            [customPinView setSelected:YES];
            
            // add a detail disclosure button to the callout which will open a new view controller page
            //
            // note: you can assign a specific call out accessory view, or as MKMapViewDelegate you can implement:
            //  - (void)mapView:(MKMapView *)mapView annotationView:(MKAnnotationView *)view calloutAccessoryControlTapped:(UIControl *)control;
            //
            UIButton* rightButton = [UIButton buttonWithType:UIButtonTypeDetailDisclosure];
            [rightButton addTarget:self
                            action:@selector(showDetails:)
                  forControlEvents:UIControlEventTouchUpInside];
            customPinView.rightCalloutAccessoryView = rightButton;
            
            return customPinView;
        }
        else
        {
            pinView.annotation = annotation;
        }
        return pinView;
    
      
}
-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [self performSelector:@selector(selectInitialAnnotation)
               withObject:nil afterDelay:0.5];
}
-(void)selectInitialAnnotation {
    [self.mapView selectAnnotation:self.selectedAnnotation animated:YES];
}
- (void)showDetails:(id)sender
{
    
    if (mapView.selectedAnnotations.count == 0)
    {
        //no annotation is currently selected
        return;
    }
    
    id<MKAnnotation> selectedAnn = [mapView.selectedAnnotations objectAtIndex:0];
    NSInteger idx=0;
    if ([selectedAnn isKindOfClass:[MapAnnotation class]])
    {
        MapAnnotation *ma = (MapAnnotation *)selectedAnn;
        idx=ma.idx;
    }
    else
    {        NSLog(@"selected annotation (not a Map Annontation) = %@", selectedAnn);

        return;
    }

    // Display detail view for the protein
    SLSMoleculeDetailViewController *detailViewController = [[SLSMoleculeDetailViewController alloc] initWithStyle:UITableViewStyleGrouped andMolecule: [molecules objectAtIndex:idx]];
    
    [self.navigationController pushViewController:detailViewController animated:YES];
    [detailViewController release];

    // the detail view does not want a toolbar so hide it
///    [self.navigationController setToolbarHidden:YES animated:NO];
    
   
}

- (void)didReceiveMemoryWarning
{
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation 
{
    // Overriden to allow any orientation.
    return YES;
}

#pragma mark -
#pragma mark Accessors

@synthesize delegate;
@synthesize database;
@synthesize molecules;
@synthesize selectedIndex;

@end
