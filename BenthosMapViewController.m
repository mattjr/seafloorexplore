//
//  BenthosMapViewController.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 6/30/2008.
//
//  This controller manages the root table of models that are stored on the device

#import "BenthosMapViewController.h"
#import "BenthosRootViewController.h"
#import "BenthosFolderViewController.h"
#import "Benthos.h"
#import "BenthosAppDelegate.h"
#import "BenthosLibraryTableCell.h"
#import "NSFileManager+Tar.h"

@implementation BenthosMapViewController
@synthesize mapView,   firstView,selectedModel,decompressingfiles;
;
#pragma mark -
#pragma mark Initialization and breakdown

- (id)init:(NSInteger)indexOfInitialModel withModels:(NSMutableArray*) mol_list
{
	if ((self = [super init])) 
	{        
        models=mol_list;
        if([models count] && [models count] > indexOfInitialModel )
            selectedModel=[NSString stringWithString:[[models objectAtIndex:indexOfInitialModel] filenameWithoutExtension]];
        else {
            selectedModel=nil;
        }
        firstView=NO;
		//[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelDidFinishDownloading:) name:@"ModelDidFinishDownloading" object:nil];

		
		if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
            
		}
		
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
    
//        CAGradientLayer *shadowGradient = [BenthosMapViewController shadowGradientForSize:CGSizeMake(320.0f, self.navigationController.view.frame.size.height)];
//		[self.navigationController.view.layer setMask:shadowGradient];
//		self.navigationController.view.layer.masksToBounds = NO;
	}
	else
	{
		self.MapView.backgroundColor = [UIColor whiteColor];
	}	*/
    [self doAnnotation];
    firstView=YES;


}
-(void)updatePins
{
    if(!firstView)
        return;
    BOOL anychanges=NO;
    NSMutableArray *discardedItems = [NSMutableArray array];
    for(MapAnnotation * ann in [mapView annotations]){
        if(ann != nil){
          
            bool found=NO;
            for(BenthosModel * mol in models){
                if([[mol filenameWithoutExtension] isEqualToString:ann.filenameWithoutExtension]){
                    found=YES;
                    break;
                }
            }
            if(!found){
               [ discardedItems addObject:ann];
                anychanges=YES;
            }
        }
    }
    [mapView removeAnnotations:discardedItems];
    
    for(BenthosModel * mol in models){
        bool found=NO;
        for(MapAnnotation * ann in [mapView annotations]){
            if([[mol filenameWithoutExtension] isEqualToString:ann.filenameWithoutExtension]){
                found=YES;
                break;
            }
        }
        if(!found){
            MapAnnotation *ann =[[[MapAnnotation alloc] initWithCoordinate:mol.coord withName:mol.title withModel:mol] autorelease];
            [mapView addAnnotation:ann];
            anychanges=YES;
            //       if(mol ==selectedModel){
            //         [mapView selectAnnotation:ann animated:YES];
            //   }
        }
    }
    if(anychanges){
        [self recenterMap];
        [[self mapView ] setNeedsDisplay];
        [[self view ] setNeedsDisplay];

    }

}

-(void) viewDidAppear:(BOOL)animated {
    

    [self performSelector:@selector(selectInitialAnnotation)
               withObject:nil afterDelay:0.5];    


}
-(void)selectInitialAnnotation {
    
    for (id <MKAnnotation> annotation in mapView.annotations){
        if ([annotation isKindOfClass:[MapAnnotation class]])
        {
            MapAnnotation *ma = (MapAnnotation *)annotation;
            if(selectedModel && [[ma filenameWithoutExtension] isEqualToString:selectedModel ]){

                [self.mapView selectAnnotation:annotation animated:YES];
                
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
    if (mapView.selectedAnnotations.count == 0 && [mapView.annotations count] != 0)
        [mapView selectAnnotation:annotation animated:NO];
}
-(void) recenterMap
{
    MKMapRect zoomRect = MKMapRectNull;
    for (id <MKAnnotation> annotation in mapView.annotations)
    {
        MKMapPoint annotationPoint = MKMapPointForCoordinate(annotation.coordinate);
        MKMapRect pointRect = MKMapRectMake(annotationPoint.x, annotationPoint.y, kMapStartSize, kMapStartSize);
        if (MKMapRectIsNull(zoomRect)) {
            zoomRect = pointRect;
        } else {
            zoomRect = MKMapRectUnion(zoomRect, pointRect);
        }
    }
    
    [mapView setVisibleMapRect:zoomRect animated:NO];
}
-(void) doAnnotation
{

    
    int idx=0;
    for(BenthosModel * mol in models){
        MapAnnotation *ann =[[[MapAnnotation alloc] initWithCoordinate:mol.coord withName:mol.title withModel:mol] autorelease];
        [mapView addAnnotation:ann];
       /* if(mol ==selectedModel){
            [mapView selectAnnotation:ann animated:YES];
            
        }*/
        idx++;
    }
    
    [self recenterMap];

}
- (void)dealloc 
{
	[tableTextColor release];
	[models release];
	[super dealloc];
}

#pragma mark -
#pragma mark View switching

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

}
#pragma mark -
#pragma mark Table view data source delegate methods


- (void)mapView:(MKMapView *)mapView didSelectAnnotationView:(MKAnnotationView *)view;
{
    MapAnnotation *annotation = view.annotation;
    //NSString *temp = annotation.title;
    if(selectedModel && [selectedModel  isEqualToString:annotation.filenameWithoutExtension])
        return;
    for(BenthosModel * mol in models){
        if([[mol filenameWithoutExtension] isEqualToString:annotation.filenameWithoutExtension]){
            selectedModel = [NSString stringWithString:annotation.filenameWithoutExtension];
            [self.delegate selectedModelDidChange:[models indexOfObject:mol]];
        }
    }
}



- (MKAnnotationView *)mapView:(MKMapView *)theMapView viewForAnnotation:(id <MKAnnotation>)annotation
{
    // if it's the user location, just return nil.
    if ([annotation isKindOfClass:[MKUserLocation class]])
        return nil;
    
    if ([annotation isKindOfClass:[MapAnnotation class]]){

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
    
    return nil;
}
/*-(void)mapView:(MKMapView *)mapView didAddAnnotationViews:(NSArray *)views {
    [self performSelector:@selector(selectInitialAnnotation)
               withObject:nil afterDelay:0.5];
}
-(void)selectInitialAnnotation {
    
    [self.mapView selectAnnotation:self.selectedAnnotation animated:YES];
}*/
- (void)showDetails:(id)sender
{
    
    if (mapView.selectedAnnotations.count == 0)
    {
        //no annotation is currently selected
        return;
    }
    
    id<MKAnnotation> selectedAnn = [mapView.selectedAnnotations objectAtIndex:0];
    MapAnnotation *ma =nil;
    if ([selectedAnn isKindOfClass:[MapAnnotation class]])
    {
        ma = (MapAnnotation *)selectedAnn;
    }
    else
    {        NSLog(@"selected annotation (not a Map Annontation) = %@", selectedAnn);

        return;
    }
    if([models count] == 0 || ma == nil)
        return;
    // Display detail view for the protein
    for(BenthosModel * mol in models){
        if([[mol filenameWithoutExtension] isEqualToString:ma.filenameWithoutExtension]){

            BenthosDetailViewController *detailViewController = [[BenthosDetailViewController alloc] initWithStyle:UITableViewStyleGrouped andBenthosModel: mol];
    
            [self.navigationController pushViewController:detailViewController animated:YES];
            [detailViewController release];
            break;
        }
    }

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
@synthesize models;

@end
