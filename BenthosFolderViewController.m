//
//  BenthosFolderViewController.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/22/2008.
//
//  This handles the keyword searching functionality of the Protein Data Bank

#import "BenthosFolderViewController.h"
#import "BenthosDownloadController.h"
#import "BenthosTableViewController.h"
#import "BenthosSearchViewController.h"
#import "VCTitleCase.h"
#import "BenthosAppDelegate.h"
#import "FolderParseOperation.h"
#define kFolderListURL @"http://marine.acfr.usyd.edu.au/campaigns.xml"

@implementation BenthosFolderViewController
@synthesize decompressingfiles,folderData,parseQueue,models;
#pragma mark -
#pragma mark Initialization and teardown

- (id)initWithStyle:(UITableViewStyle)style 
{
	if ((self = [super initWithStyle:style])) 
	{
		// Initialize the search bar and title
		models =nil;
		self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;

        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addFolder:)
                                                     name:kAddFoldersNotif
                                                   object:nil];


		self.navigationItem.title = NSLocalizedStringFromTable(@"Campaigns", @"Localized", nil);
		self.navigationItem.rightBarButtonItem = nil;

		
		downloadedFileContents = nil;
		downloadaleFolderList = nil;
		searchResultRetrievalConnection = nil;
		nextResultsRetrievalConnection = nil;
		searchCancelled = NO;
		
		if ([BenthosAppDelegate isRunningOniPad])
		{
			self.contentSizeForViewInPopover = CGSizeMake(320.0, 700.0);
		}
        parseQueue = [NSOperationQueue new];

        [self getCurrentModelList];
		
	}
	return self;
}

- (void)viewDidLoad;
{
	[super viewDidLoad];
    
	if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
	{
//		//		self.tableView.backgroundColor = [UIColor colorWithRed:0.0f green:0.0f blue:0.054f alpha:1.0f];
//		self.tableView.backgroundColor = [UIColor blackColor];
//        self.tableView.separatorColor = [UIColor clearColor];
//        self.tableView.rowHeight = 50.0;

		self.tableView.backgroundColor = [UIColor whiteColor];
//        CAGradientLayer *shadowGradient = [BenthosTableViewController shadowGradientForSize:CGSizeMake(320.0f, self.navigationController.view.frame.size.height)];
//		[self.navigationController.view.layer setMask:shadowGradient];
//		self.navigationController.view.layer.masksToBounds = NO;
	}
	else
	{
		self.tableView.backgroundColor = [UIColor whiteColor];
	}	
    [self.navigationItem setHidesBackButton:NO animated:YES];
    self.tableView.allowsSelection = YES;

}

- (void)dealloc 
{
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddFoldersNotif object:nil];
    [models release];

	[searchResultRetrievalConnection release];
	[downloadaleFolderList release];
	[downloadedFileContents release];
	[super dealloc];
}
- (void)addFolder:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self addFolderToList:[[notif userInfo] valueForKey:kFolderResultsKey]];
}
- (BOOL)getCurrentModelList;
{
	// Clear the old search results table
	[downloadaleFolderList release];
	downloadaleFolderList = nil;
	
	    
    
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSURLRequest *fileRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:kFolderListURL]
													cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData//NSURLRequestUseProtocolCachePolicy
												timeoutInterval:60.0];
	searchResultRetrievalConnection = [[NSURLConnection alloc] initWithRequest:fileRequest delegate:self];
	
	downloadedFileContents = [[NSMutableData data] retain];
   
	if (searchResultRetrievalConnection) 
	{
		[self.tableView reloadData];
	} 
	else 
	{
		return NO;
	}
	return YES;
}

#pragma mark -
#pragma mark Performing search


- (void)processSearchResultsAppendingNewData:(BOOL)appendData;
{
	if (!appendData)
	{
		[searchResultRetrievalConnection release];
		searchResultRetrievalConnection = nil;

		downloadaleFolderList = [[NSMutableArray alloc] init];
	}
	else
	{
		[nextResultsRetrievalConnection release];
		nextResultsRetrievalConnection = nil;
	}	
    

    [self processResults];

}
- (void)processResults;
{
    FolderParseOperation *parseOperation = [[FolderParseOperation alloc] initWithData:downloadedFileContents];
    [self.parseQueue addOperation:parseOperation];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    
    // earthquakeData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    [downloadedFileContents release];
	downloadedFileContents = nil;
}


  
#pragma mark -
#pragma mark UITableViewController methods

- (NSInteger)numberOfSectionsInTableView:(UITableView *)tableView 
{
	return 1;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section 
{
	// Running a search, so display a status cell
	if (searchResultRetrievalConnection != nil)
		return 1;
	else if (downloadaleFolderList == nil)
		return 0;
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleFolderList count] == 0)
		return 1;
	else
	{
       
            return [downloadaleFolderList count];
        
	}
}

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath
{
	return 60.0;
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath;
{	          
	UITableViewCell *cell;
	// Running a search, so display a status cell
	if ((searchResultRetrievalConnection != nil) || ((nextResultsRetrievalConnection != nil) && (indexPath.row >= [downloadaleFolderList count])))
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"SearchInProgress"];
		if (cell == nil) 
		{		
//			cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"SearchInProgress"] autorelease];
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"SearchInProgress"] autorelease];

//            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//            {
//                cell.backgroundColor = [UIColor blackColor];
//                cell.textLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
//            }
//            else
//            {
                cell.textLabel.textColor = [UIColor blackColor];
//            }

			cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0];
			
			//		CGRect frame = CGRectMake(CGRectGetMaxX(cell.contentView.bounds) - 250.0, 5.0, 240.0, 32.0);
//			CGRect frame = CGRectMake(CGRectGetMaxX(cell.contentView.bounds) - 70.0, 14.0, 32.0, 32.0);
			CGRect frame = CGRectMake(CGRectGetMaxX(cell.contentView.bounds) - 70.0f, 20.0f, 20.0f, 20.0f);
			UIActivityIndicatorView *spinningIndicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray];
			[spinningIndicator startAnimating];
			spinningIndicator.frame = frame;
			[cell.contentView addSubview:spinningIndicator];
			[spinningIndicator release];
			cell.accessoryType = UITableViewCellAccessoryNone;
			cell.textLabel.font = [UIFont systemFontOfSize:16.0];
			cell.textLabel.textAlignment = UITextAlignmentCenter;
		}
		cell.textLabel.text = NSLocalizedStringFromTable(@"Downloading...", @"Localized", nil);
	}
	else if (downloadaleFolderList == nil)
    {
		cell = nil;
    }
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleFolderList count] == 0)
	{
		cell = [tableView dequeueReusableCellWithIdentifier:@"NoResults"];
		if (cell == nil) 
		{		
		//	cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"NoResults"] autorelease];
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"NoResults"] autorelease];


//            if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//            {
//                cell.backgroundColor = [UIColor blackColor];
//                cell.textLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
//            }
//            else
//            {
                cell.textLabel.textColor = [UIColor blackColor];
//            }

			cell.textLabel.font = [UIFont systemFontOfSize:16.0];
			cell.textLabel.text = NSLocalizedStringFromTable(@"No results", @"Localized", nil);
			cell.textLabel.textAlignment = UITextAlignmentCenter;
			cell.accessoryType = UITableViewCellAccessoryNone;
		}
	}
   	else
	{
		
		
        cell = [tableView dequeueReusableCellWithIdentifier:NSLocalizedStringFromTable(@"Results", @"Localized", nil)];
        if (cell == nil) 
        {		
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleSubtitle reuseIdentifier:NSLocalizedStringFromTable(@"Results", @"Localized", nil)] autorelease];
            
            //                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
            //                {
            //                    cell.backgroundColor = [UIColor blackColor];
            //                    cell.textLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
            //                    CAGradientLayer *glowGradientLayer = [BenthosTableViewController glowGradientForSize:CGSizeMake(self.view.frame.size.width, 60.0)];
            //                    
            //                    [cell.layer insertSublayer:glowGradientLayer atIndex:10];
            //                }
            //                else
            //                {
            cell.textLabel.textColor = [UIColor blackColor];
            //                }
            cell.selectionStyle = UITableViewCellSelectionStyleNone;
            
            cell.textLabel.font = [UIFont boldSystemFontOfSize:14.0];
            cell.textLabel.numberOfLines = 2;
            cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:14.0];
            
            //                cell.textLabel.font = [UIFont boldSystemFontOfSize:12.0];
            //				cell.detailTextLabel.font = [UIFont boldSystemFontOfSize:12.0];
        }
        
        
        
        
        cell.textLabel.text = [NSString stringWithFormat:@"%@", [[downloadaleFolderList objectAtIndex:[indexPath row]] title]];
        if([[[downloadaleFolderList objectAtIndex:[indexPath row]] desc] length])
            cell.detailTextLabel.text  = [NSString stringWithFormat:@"%@", [[downloadaleFolderList objectAtIndex:[indexPath row]] desc]];

        
        cell.accessoryType = UITableViewCellAccessoryDisclosureIndicator;
		
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    
        cell.backgroundColor = [UIColor whiteColor];
    
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Prevent any crashes by clicking on a non-normal cell
	if (searchResultRetrievalConnection != nil)
    {
		return;
    }
	else if (downloadaleFolderList == nil)
    {
		return;
    }
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleFolderList count] == 0)
    {        
		return;
    }
	else
	{
       
		Folder *selFolder = [downloadaleFolderList objectAtIndex:[indexPath row]];

        BenthosSearchViewController *searchViewController = [[BenthosSearchViewController alloc] initWithStyle:UITableViewStylePlain andURL:[selFolder weblink] andTitle:[selFolder title]];
        searchViewController.models=models;
        searchViewController.decompressingfiles=decompressingfiles;

        [self.navigationController pushViewController:searchViewController animated:YES];
        [searchViewController release];	

	}	
}

/*- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = [indexPath row];

		// Display detail view for the protein
		BenthosDetailViewController *detailViewController = [[BenthosDetailViewController alloc] initWithStyle:UITableViewStyleGrouped andModel: [downloadaleFolderList objectAtIndex:(index)]];
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
		
	
}
*/
- (void)didReceiveMemoryWarning 
{
    NSLog(@"My Memory warning\n");
}

#pragma mark -
#pragma mark UIViewController methods

- (void)viewWillDisappear:(BOOL)animated
{
	
	[super viewWillDisappear:animated];
}

- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Overriden to allow any orientation.
    return YES;
}


#pragma mark -
#pragma mark NSURLConnection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    NSString *connectionError = nil;
   /* if (currentSearchType == PROTEINDATABANKSEARCH)
    {
        connectionError = NSLocalizedStringFromTable(@"Could not connect to the Protein Data Bank", @"Localized", nil);
    }
    else
    {*/
        connectionError = NSLocalizedStringFromTable(@"Could not connect to server", @"Localized", nil);
    //}
    
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Connection failed", @"Localized", nil) message:connectionError
												   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
	[alert show];
	[alert release];
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	[downloadedFileContents release];
	downloadedFileContents = nil;
	
	[searchResultRetrievalConnection release];
	searchResultRetrievalConnection = nil;
	
	[nextResultsRetrievalConnection release];
	nextResultsRetrievalConnection = nil;
	
	[self.tableView reloadData];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	// Concatenate the new data with the existing data to build up the downloaded file
	// Update the status of the download
	
	[downloadedFileContents appendData:data];

	if (searchCancelled)
	{
		[connection cancel];
		[downloadedFileContents release];
		downloadedFileContents = nil;
		
		// Release connection?
		[self.tableView reloadData];
		
		searchCancelled = NO;
		return;
	}
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	// TODO: Deal with a 404 error by checking filetype header
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];


    
        if (connection == searchResultRetrievalConnection)
        {
            [self processSearchResultsAppendingNewData:NO];
        }
        else
        {
            [self processSearchResultsAppendingNewData:YES];
        }
}

- (void)addFolderToList:(NSArray *)folders {
    
    [downloadaleFolderList addObjectsFromArray:folders];
    [self.tableView reloadData];

}

@end

