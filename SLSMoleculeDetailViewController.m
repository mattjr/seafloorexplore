//
//  SLSMoleculeDetailViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/5/2008.
//
//  This controller manages the detail view of the molecule's properties, such as author, publication, etc.

#import "SLSMoleculeDetailViewController.h"
#import "SLSMolecule.h"
#import "SLSTextViewController.h"
#import "SLSMoleculeAppDelegate.h"
#import <QuartzCore/QuartzCore.h>

#define DESCRIPTION_SECTION 0
#define MAPS_SECTION 1
#define STATISTICS_SECTION 2
#define JOURNAL_SECTION 3
#define SOURCE_SECTION 4
#define SEQUENCE_SECTION 5

@implementation SLSMoleculeDetailViewController
@synthesize placemark = _placemark;


- (id)initWithStyle:(UITableViewStyle)style andMolecule:(SLSMolecule *)newMolecule;
{
	if ((self = [super initWithStyle:style])) 
	{
		self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;
		self.molecule = newMolecule;
		//[newMolecule readMetadataFromDatabaseIfNecessary];
		self.title = molecule.title;

        
        _placemark = [[[CLPlacemark alloc]init] retain];

	
		if ([SLSMoleculeAppDelegate isRunningOniPad])
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}		
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style andModel:(Model *)newModel;
{
	if ((self = [super initWithStyle:style])) 
	{
		self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;
		self.molecule = [[[SLSMolecule alloc] initWithModel:newModel database:NULL] autorelease];
		self.title = molecule.compound;
        
        
        _placemark = [[[CLPlacemark alloc]init] retain];
        
        
		if ([SLSMoleculeAppDelegate isRunningOniPad])
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}		
	}
	return self;
}
- (void)dealloc 
{
    [_placemark release];
    _placemark = nil;

    [_mapCell release];
    _mapCell = nil;

	[super dealloc];
}

- (void)viewDidLoad 
{
//	UILabel *label= [[UILabel alloc] initWithFrame:CGRectZero];
	[super viewDidLoad];
}


- (void)viewWillAppear:(BOOL)animated 
{
	[super viewWillAppear:animated];
}

- (void)viewDidAppear:(BOOL)animated 
{
	[super viewDidAppear:animated];
}

- (void)viewWillDisappear:(BOOL)animated 
{
}

- (void)viewDidDisappear:(BOOL)animated 
{
}

- (void)didReceiveMemoryWarning {
}

#pragma mark -
#pragma mark UITableView Delegate/Datasource

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
    return 2;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    switch (section) 
	{
        case DESCRIPTION_SECTION:
            return NSLocalizedStringFromTable(@"Description", @"Localized", nil);
    //    case MAPS_SECTION:
      //      return NSLocalizedStringFromTable(@"Map", @"Localized", nil);
            /*
        case JOURNAL_SECTION:
            return NSLocalizedStringFromTable(@"Journal", @"Localized", nil);
        case SOURCE_SECTION:
            return NSLocalizedStringFromTable(@"Source", @"Localized", nil);
        case MAPS_SECTION:
            return NSLocalizedStringFromTable(@"Map", @"Localized", nil);
        case SEQUENCE_SECTION:
            return NSLocalizedStringFromTable(@"Sequence", @"Localized", nil);
         */
		default:
			break;
    }
    return nil;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	NSInteger rows = 0;
	
	switch (section) 
	{
		case DESCRIPTION_SECTION:
		case MAPS_SECTION:
		case SOURCE_SECTION:
		case SEQUENCE_SECTION:
			rows = 1;
			break;
        default:
			break;
	}
	return rows;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
	if (indexPath.section == MAPS_SECTION) 
        return [self cellForMapView];

	static NSString *MyIdentifier = @"MyIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
        //cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
    }
    if (indexPath.section == DESCRIPTION_SECTION)
        cell.textLabel.font=[UIFont fontWithName:@"Helvetica" size:12.0];
    
    cell.textLabel.text = [self textForIndexPath:indexPath];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.numberOfLines=0;
    [cell.textLabel sizeToFit];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

	return cell;
}

- (UILabel *)createLabelForIndexPath:(NSIndexPath *)indexPath;
{
	NSString *text = nil;
    switch (indexPath.section) 
	{
		case DESCRIPTION_SECTION: // type -- should be selectable -> checkbox
			text = molecule.title;
			break;
       /* case JOURNAL_SECTION:
		{
			switch (indexPath.row)
			{
				case 0: text = molecule.journalTitle; break;
				case 1: text = molecule.journalAuthor; break;
				case 2: text = molecule.journalReference; break;
			}
		}; break;
        case SOURCE_SECTION:
			text = molecule.source;
			break;
		case SEQUENCE_SECTION:
			text = molecule.sequence;
			break;*/
		default:
			break;
	}
    	
//	CGRect frame = CGRectMake(0.0, 0.0, 100.0, 100.0);

	UILabel *label= [[UILabel alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 100.0f, 100.0f)];
    label.textColor = [UIColor blackColor];
//    textView.font = [UIFont fontWithName:@"Helvetica" size:18.0];
//	textView.editable = NO;
    label.backgroundColor = [UIColor whiteColor];
	
	label.text = text;
	
	return [label autorelease];
}

//#define HEIGHTPERLINE 23.0
//
//- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
//{
//	CGFloat result;
//
//	switch (indexPath.section) 
//	{
//		case DESCRIPTION_SECTION: // type -- should be selectable -> checkbox
//			result = (float)[molecule.title length] * HEIGHTPERLINE;
//			break;
//		case AUTHOR_SECTION: // instructions
//			result = (float)[molecule.author length] * HEIGHTPERLINE;
//			break;
//        case JOURNAL_SECTION:
//		{
//			switch (indexPath.row)
//			{
//				case 0: result = (float)[molecule.journalTitle length] * HEIGHTPERLINE; break;
//				case 1: result = (float)[molecule.journalAuthor length] * HEIGHTPERLINE; break;
//				case 2: result = (float)[molecule.journalReference length] * HEIGHTPERLINE; break;
//			}
//		}; break;
//        case SOURCE_SECTION:
//			result = (float)[molecule.source length] * HEIGHTPERLINE;
//			break;
//		case SEQUENCE_SECTION:
//			result = (float)[molecule.sequence length] * HEIGHTPERLINE;
//			break;
//		default:
//			result = 43.0;
//			break;
//	}
//	
//	return result;
//}

- (NSString *)textForIndexPath:(NSIndexPath *)indexPath;
{
	NSString *text;
	switch (indexPath.section) 
	{
		case DESCRIPTION_SECTION:
			text = molecule.desc;;
			break;
                
        /*case JOURNAL_SECTION:
		{
			switch (indexPath.row)
			{
				case 0: text = molecule.journalTitle; break;
				case 1: text = molecule.journalAuthor; break;
				case 2: text = molecule.journalReference; break;
				default: text = @""; break;
			}
		}; break;
        case SOURCE_SECTION:
			text = molecule.source;
			break;
		case SEQUENCE_SECTION:
			text = molecule.sequence;
			break;*/
		default:
			text = @"";
			break;
	}
	
	return [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
	if (indexPath.section == STATISTICS_SECTION)
		return nil;
	
	return indexPath;
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	/*if (indexPath.section != STATISTICS_SECTION)
	{
		SLSTextViewController *nextViewController = [[SLSTextViewController alloc] initWithTitle:[self tableView:tableView titleForHeaderInSection:indexPath.section] andContent:[self textForIndexPath:indexPath]];
		[self.navigationController pushViewController:nextViewController animated:YES];
		[nextViewController release];
	}*/
	
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}
- (UITableViewCell *)cellForMapView
{
    if (_mapCell)
        return _mapCell;
    
    // if not cached, setup the map view...
    CGFloat cellWidth = self.view.bounds.size.width - 20;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        cellWidth = self.view.bounds.size.width - 20;
    }
    
    CGRect frame = CGRectMake(0, 0, cellWidth, 240);
    MKMapView *map = [[MKMapView alloc] initWithFrame:frame];
    MKCoordinateSpan Span = MKCoordinateSpanMake(5, 5);
    MKCoordinateRegion region =  MKCoordinateRegionMake(self.molecule.coord, Span);

    [map setRegion:region];
    
    map.layer.masksToBounds = YES;
    map.layer.cornerRadius = 10.0;
    map.mapType = MKMapTypeStandard;
    [map setScrollEnabled:NO];
    [map setZoomEnabled:NO];

    // add a pin using self as the object implementing the MKAnnotation protocol
    [map addAnnotation:self];
    
    NSString * cellID = @"Cell";
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];    
    
    [cell.contentView addSubview:map];
    [map release];
    
    _mapCell = [cell retain];
    return cell;
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
    if (indexPath.section == MAPS_SECTION)
    { 
        return 240.0f; // map height
    }

    if (indexPath.section == DESCRIPTION_SECTION)
    { 
        CGSize bodySize = [[self textForIndexPath:indexPath] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:12.0] 
                           constrainedToSize:CGSizeMake(self.view.frame.size.width,CGFLOAT_MAX)];
        return bodySize.height+20.0f;
    
    }
    return [self.tableView rowHeight];
}

#pragma mark -
#pragma mark Accessors
#pragma mark - MKAnnotation Protocol (for map pin)

- (CLLocationCoordinate2D)coordinate
{
   
    return self.molecule.coord;
}

- (NSString *)title
{
    return [molecule title];
}

@synthesize molecule;

@end

