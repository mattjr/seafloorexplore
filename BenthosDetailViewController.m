//
//  BenthosDetailViewController.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/5/2008.
//
//  This controller manages the detail view of the model's properties, such as author, publication, etc.

#import "BenthosDetailViewController.h"
#import "Benthos.h"
#import "BenthosAppDelegate.h"
#import <QuartzCore/QuartzCore.h>
#define IMAGE_SECTION 0

#define DESCRIPTION_SECTION 1
#define MAPS_SECTION 2
#define JOURNAL_SECTION 3
#define SOURCE_SECTION 4
#define SEQUENCE_SECTION 5

@implementation BenthosDetailViewController
@synthesize placemark = _placemark;
@synthesize detailImage;

- (id)initWithStyle:(UITableViewStyle)style andBenthosModel:(BenthosModel *)newModel;
{
	if ((self = [super initWithStyle:style])) 
	{
		self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;
		self.model = newModel;
		//[newModel readMetadataFromDatabaseIfNecessary];
		self.title = model.title;
        self.detailImage=nil;
        
        _placemark = [[[CLPlacemark alloc]init] retain];

	
		if ([BenthosAppDelegate isRunningOniPad])
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 600.0);
		}		
	}
	return self;
}

- (id)initWithStyle:(UITableViewStyle)style andDownloadedModel:(DownloadedModel *)newModel;
{
	if ((self = [super initWithStyle:style])) 
	{
		self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;
		self.model = [[[BenthosModel alloc] initWithDownloadedModel:newModel database:NULL] autorelease];
		self.title = model.compound;
        self.detailImage=[[[UIImage alloc] initWithData:[NSData dataWithContentsOfURL:newModel.imageURL]] autorelease];
        
        _placemark = [[[CLPlacemark alloc]init] retain];
        
        
		if ([BenthosAppDelegate isRunningOniPad])
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
    if((self.detailImage != nil))
        return 3;
    
    return 2;
}


- (NSString *)tableView:(UITableView *)tableView titleForHeaderInSection:(NSInteger)section 
{
    if((self.detailImage == nil))
        section++;
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
		return 1;
}
- (UITableViewCell *)cellForImageView
{
    
    if (_imgCell)
        return _imgCell;
    
    // if not cached, setup the map view...
    CGFloat cellWidth = self.view.bounds.size.width - 20;
    
    if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
    {
        cellWidth = self.view.bounds.size.width - 20;
    }
    
    CGRect frame = CGRectMake(0, 0, cellWidth, 240);
    UIImageView * image = [[UIImageView alloc] initWithFrame:frame];
    [image setImage:self.detailImage];
    image.layer.masksToBounds = YES;
    image.layer.cornerRadius = 10.0;
    image.layer.borderWidth = 1.0;
    image.layer.borderColor = [[UIColor grayColor] CGColor];
    NSString * cellID = @"ImgCell";
    UITableViewCell *cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleValue1 reuseIdentifier:cellID] autorelease];    
    
    [cell.contentView addSubview:image];
    [image release];
    
    _imgCell = [cell retain];
    return cell;
    
    
    
 
    return cell;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
    int section =indexPath.section;
    if(self.detailImage == nil){
        section++;
    }
    if (section == IMAGE_SECTION) 
        return [self cellForImageView];
    
    if (section == MAPS_SECTION) 
        return [self cellForMapView];


	static NSString *MyIdentifier = @"MyIdentifier";
	UITableViewCell *cell = [tableView dequeueReusableCellWithIdentifier:MyIdentifier];
	if (cell == nil) {
        cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:MyIdentifier] autorelease];
        //cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:MyIdentifier] autorelease];
    }
    if (section == DESCRIPTION_SECTION)
        cell.textLabel.font=[UIFont fontWithName:@"Helvetica" size:12.0];
    
    cell.textLabel.text = [self textForIndexPath:section];
    cell.textLabel.lineBreakMode = UILineBreakModeWordWrap;
    cell.textLabel.textAlignment = UITextAlignmentLeft;
    cell.textLabel.numberOfLines=0;
    [cell.textLabel sizeToFit];
    cell.selectionStyle = UITableViewCellSelectionStyleNone;

	return cell;
}

- (UILabel *)createLabelForIndexPath:(int)row;
{
	NSString *text = nil;
    switch (row) 
	{
		case DESCRIPTION_SECTION: // type -- should be selectable -> checkbox
			text = model.title;
			break;
       /* case JOURNAL_SECTION:
		{
			switch (indexPath.row)
			{
				case 0: text = model.journalTitle; break;
				case 1: text = model.journalAuthor; break;
				case 2: text = model.journalReference; break;
			}
		}; break;
        case SOURCE_SECTION:
			text = model.source;
			break;
		case SEQUENCE_SECTION:
			text = model.sequence;
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


- (NSString *)textForIndexPath:(int)row;
{
	NSString *text;
	switch (row) 
	{
		case DESCRIPTION_SECTION:
			text = model.desc;;
			break;
                
        default:
			text = @"";
			break;
	}
	
	return [text stringByReplacingOccurrencesOfString:@"\n" withString:@" "];
	
}

- (NSIndexPath *)tableView:(UITableView *)tableView willSelectRowAtIndexPath:(NSIndexPath *)indexPath;
{
		return nil;
	
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{

	
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
    MKCoordinateRegion region =  MKCoordinateRegionMake(self.model.coord, Span);

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
    int section =indexPath.section;
    if(self.detailImage == nil){
        section++;
    }
    if (section == MAPS_SECTION)
    { 
        return 240.0f; // map height
    }

    if (section == DESCRIPTION_SECTION)
    { 
        CGSize bodySize = [[self textForIndexPath:section] sizeWithFont:[UIFont fontWithName:@"Helvetica" size:12.0] 
                           constrainedToSize:CGSizeMake(self.view.frame.size.width,CGFLOAT_MAX)];
        return bodySize.height+20.0f;
    
    }
    
    if (section == IMAGE_SECTION){
            return 240.0;
    }

    return [self.tableView rowHeight];
}

#pragma mark -
#pragma mark Accessors
#pragma mark - MKAnnotation Protocol (for map pin)

- (CLLocationCoordinate2D)coordinate
{
   
    return self.model.coord;
}

- (NSString *)title
{
    return [model title];
}

@synthesize model;

@end

