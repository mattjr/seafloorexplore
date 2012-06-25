//
//  BenthosSearchViewController.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/22/2008.
//
//  This handles the keyword searching functionality of the Protein Data Bank

#import "BenthosSearchViewController.h"
#import "BenthosDownloadController.h" 
#import "BenthosTableViewController.h"
#import "VCTitleCase.h"
#import "BenthosAppDelegate.h"
#import "ModelParseOperation.h"
#import "Model.h"
#import "BackgroundProcessingFile.h"

@interface BenthosSearchViewController ()
- (void)startIconDownload:(DownloadedModel *)model forIndexPath:(NSIndexPath *)indexPath;
@end

@implementation BenthosSearchViewController
@synthesize decompressingfiles,modelData,parseQueue,listURL,models,imageDownloadsInProgress,downloadaleModelList;
#pragma mark -
#pragma mark Initialization and teardown


- (id)initWithStyle:(UITableViewStyle)style andURL:(NSURL*)url andTitle:(NSString*)title
{
	if ((self = [super initWithStyle:style])) 
	{
		// Initialize the search bar and title
		models=nil;
		//self.view.frame = [[UIScreen mainScreen] applicationFrame];
		self.view.autoresizesSubviews = YES;
        listURL = [url retain];

        [[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(modelFailedDownloading:) name:@"ModelFailedDownloading" object:nil];
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(addModels:)
                                                     name:kAddModelsNotif
                                                   object:nil];

		/*keywordSearchBar = [[UISearchBar alloc] initWithFrame:CGRectMake(0.0f, 0.0f, 320.0f, 44.0f)];
		keywordSearchBar.placeholder = NSLocalizedStringFromTable(@"Search PubChem", @"Localized", nil);
		keywordSearchBar.delegate = self;
		keywordSearchBar.autocorrectionType = UITextAutocorrectionTypeNo;
        keywordSearchBar.scopeButtonTitles = [NSArray arrayWithObjects:@"PubChem", @"Protein Data Bank", nil];
        keywordSearchBar.showsScopeBar = YES;
        [keywordSearchBar sizeToFit];
        
        currentSearchType = PUBCHEMSEARCH;
        
//        if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//        {
//            keywordSearchBar.barStyle = UIBarStyleBlack;
//        }
		[keywordSearchBar becomeFirstResponder];
				*/
		self.navigationItem.title = [title retain];
        self.navigationItem.rightBarButtonItem = nil;

		//self.tableView.tableHeaderView = keywordSearchBar;
		
		downloadedFileContents = nil;
		downloadaleModelList = nil;
		searchResultRetrievalConnection = nil;
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
    self.imageDownloadsInProgress = [NSMutableDictionary dictionary];
}

- (void)dealloc 
{
    [models release];
    
    [downloadController release];
    downloadController = nil;
    [[NSNotificationCenter defaultCenter] removeObserver:self name:kAddModelsNotif object:nil];
	[listURL release];

    [currentXMLElementString release];
    currentXMLElementString = nil;

	[searchResultRetrievalConnection release];
	[downloadaleModelList release];
	[downloadedFileContents release];
    [imageDownloadsInProgress release];

	[super dealloc];
}
- (void)addModels:(NSNotification *)notif {
    assert([NSThread isMainThread]);
    
    [self addModelsToList:[[notif userInfo] valueForKey:kModelResultsKey]];
}
- (BOOL)getCurrentModelList;
{
	// Clear the old search results table
	[downloadaleModelList release];
	downloadaleModelList = nil;
	
	    
	/*NSString *searchURL = nil;
    searchURL = [[NSString alloc] initWithString:[urlbasepath stringByAppendingString:listFile ]] ;
    */
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	
	NSURLRequest *fileRequest=[NSURLRequest requestWithURL:[self listURL]
													cachePolicy:NSURLRequestUseProtocolCachePolicy
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
	
		[searchResultRetrievalConnection release];
		searchResultRetrievalConnection = nil;

		downloadaleModelList = [[NSMutableArray alloc] init];
	
	
    [self processHTMLResults];

}
- (void)processHTMLResults;
{
    ModelParseOperation *parseOperation = [[ModelParseOperation alloc] initWithData:downloadedFileContents];
    [self.parseQueue addOperation:parseOperation];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    //Remove models that are too new for this version of the code
    
    // earthquakeData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    [downloadedFileContents release];
	downloadedFileContents = nil;

    /*
    NSString *titlesAndPDBCodeString = [[NSString alloc] initWithData:downloadedFileContents encoding:NSASCIIStringEncoding];
	[downloadedFileContents release];
	downloadedFileContents = nil;
	NSCharacterSet *semicolonSet;
    NSScanner *theScanner;
    NSString *descName;
    NSString *fileName;
   // NSLog(@"A of %@", titlesAndPDBCodeString);

    semicolonSet = [NSCharacterSet characterSetWithCharactersInString:@";"];
    theScanner = [NSScanner scannerWithString:titlesAndPDBCodeString];
    
    while ([theScanner isAtEnd] == NO)
    {
        if ([theScanner scanUpToCharactersFromSet:semicolonSet
                                       intoString:&descName] &&
            [theScanner scanString:@";" intoString:NULL] &&
            [theScanner scanUpToCharactersFromSet:semicolonSet
                                       intoString:&fileName]&&
             [theScanner scanString:@";" intoString:NULL]
            )
        {
            NSString *fullPath = [[[NSString alloc] initWithFormat:@"%@/%@", urlbasepath,fileName] autorelease];
            NSString *descNameStr = [[[NSString alloc] initWithFormat:@"%@", descName] autorelease];

            [searchResultTitles addObject:descNameStr];
            [searchResultIDs addObject:fullPath];

           // NSLog(@"Adding %@ file name: %@", descName, fullPath);
        }
    }
	[titlesAndPDBCodeString release];*/

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
	else if (downloadaleModelList == nil)
		return 0;
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleModelList count] == 0)
		return 1;
	else
	{
       
            return [downloadaleModelList count];
        
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
	if ((searchResultRetrievalConnection != nil)  && (indexPath.row >= [downloadaleModelList count]))
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
		cell.textLabel.text = NSLocalizedStringFromTable(@"Searching...", @"Localized", nil);
	}
	else if (downloadaleModelList == nil)
    {
		cell = nil;
    }
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleModelList count] == 0)
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
    else if ((isDownloading) && ([indexPath row] == indexOfDownloadingModel))
    {
        cell = [tableView dequeueReusableCellWithIdentifier:@"DownloadInProgress"];
		if (cell == nil) 
		{		
            
           // cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"DownloadInProgress"] autorelease];
            cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"DownloadInProgress"] autorelease];

        }
        /*  float widthMargin=0.05;
         float heightMargin=0.75;
         CGRect textframe = CGRectMake(CGRectGetMinX(cell.contentView.bounds)+widthMargin*CGRectGetWidth(cell.contentView.bounds),
         0.0f,
         CGRectGetWidth(cell.contentView.bounds)-((3*widthMargin)* CGRectGetWidth(cell.contentView.bounds)),
         CGRectGetHeight(cell.contentView.bounds)*heightMargin);
         CGRect progframe = CGRectMake(CGRectGetMinX(cell.contentView.bounds)+widthMargin*CGRectGetWidth(cell.contentView.bounds), 
         CGRectGetHeight(cell.contentView.bounds)*heightMargin, CGRectGetWidth(cell.contentView.bounds)-((3*widthMargin)* CGRectGetWidth(cell.contentView.bounds)),
         CGRectGetHeight(cell.contentView.bounds)*1.0-heightMargin);
         
         //float buttonwidth=20.0f;
         CGRect buttonframe = CGRectMake(CGRectGetWidth(cell.contentView.bounds) -(CGRectGetWidth(cell.contentView.bounds)*2*widthMargin), CGRectGetHeight(cell.contentView.bounds)*0.33, CGRectGetHeight(cell.contentView.bounds)*0.33, CGRectGetHeight(cell.contentView.bounds)*0.33);*/
        
        CGRect progframe = CGRectMake(CGRectGetMinX(cell.contentView.bounds) + 20.0f, 45.0f, CGRectGetWidth(cell.contentView.bounds)-80.0f, 20.0f);
        CGRect textframe = CGRectMake(CGRectGetMinX(cell.contentView.bounds) + 25.0f, 0.0f, CGRectGetWidth(cell.contentView.bounds)-40.0f, 40.0f);
        float buttonwidth=20.0f;
        CGRect buttonframe = CGRectMake(CGRectGetWidth(cell.contentView.bounds) -buttonwidth-10.0, 8.0f, buttonwidth, buttonwidth);
        [downloadController cancelDownloadButton].frame=buttonframe;
        
        [downloadController progressView].frame=progframe;
        [downloadController downloadStatusText].frame=textframe;
        [downloadController spinningIndicator].frame=buttonframe;
        [downloadController spinningIndicator].hidden=YES;

        [cell.contentView addSubview:[downloadController progressView]];
        [cell.contentView addSubview:[downloadController downloadStatusText]];
        [cell.contentView addSubview:[downloadController cancelDownloadButton]];
        [cell.contentView addSubview:[downloadController spinningIndicator]];

        cell.accessoryType = UITableViewCellAccessoryNone;

        
    }
	else
	{
		/*if ([indexPath row] >= [downloadaleModelList count])
		{
			cell = [tableView dequeueReusableCellWithIdentifier:@"LoadMore"];
			if (cell == nil) 
			{		
				//cell = [[[UITableViewCell alloc] initWithFrame:CGRectZero reuseIdentifier:@"LoadMore"] autorelease];
                cell = [[[UITableViewCell alloc] initWithStyle:UITableViewCellStyleDefault reuseIdentifier:@"LoadMore"] autorelease];

//                if (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad)
//                {
//                    cell.backgroundColor = [UIColor blackColor];
//                    cell.textLabel.textColor = [UIColor colorWithWhite:0.8 alpha:1.0];
//                }
//                else
//                {
                    cell.textLabel.textColor = [UIColor blackColor];
//                }
                
				cell.textLabel.font = [UIFont systemFontOfSize:16.0];
				cell.textLabel.textAlignment = UITextAlignmentCenter;
				cell.textLabel.text = NSLocalizedStringFromTable(@"Load next 10 results", @"Localized", nil);
				cell.accessoryType = UITableViewCellAccessoryNone;
				cell.detailTextLabel.text = @"";
			}
		}
		else*/
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
            
            BOOL alreadyInList=NO;
            DownloadedModel *curModel=[downloadaleModelList objectAtIndex:[indexPath row]];
            if(curModel != nil){
                
                
                NSString *filename = [[[curModel filename] lastPathComponent] stringByDeletingPathExtension];	
                if(models != nil){
                    for(BenthosModel *model in models){
                        if([[[model filename] stringByDeletingPathExtension] isEqualToString:filename]){
                            alreadyInList=YES;
                            break;
                        }
                    }
                }
                for(BackgroundProcessingFile *file in decompressingfiles){
                    if([filename isEqualToString:[file filenameWithoutExtension]]){
                        if(alreadyInList){
                            NSLog(@"Should not allready be in list and in models\n");
                        }
                        alreadyInList=YES;

                    }
                    
                }

                
                
                if (((isDownloading) && ([indexPath row] != indexOfDownloadingModel)) || alreadyInList)
                {
                    if((isDownloading) && ([indexPath row] != indexOfDownloadingModel)){
                        cell.textLabel.textColor = [UIColor colorWithWhite:0.3 alpha:1.0];
                        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.2 alpha:1.0];                 
                    }else{
                        cell.textLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
                        cell.detailTextLabel.textColor = [UIColor colorWithWhite:0.7 alpha:1.0];
                        
                        
                    }
                    cell.selectionStyle = UITableViewCellSelectionStyleNone;
                    // cell.accessoryType = UITableViewCellAccessoryNone;
                    cell.userInteractionEnabled =NO;
                    
                }else {
                    cell.userInteractionEnabled =YES;
                    
                    cell.textLabel.textColor = [UIColor blackColor];
                    cell.accessoryType = UITableViewCellAccessoryDetailDisclosureButton;
                    
                    
                }
                
                int exponent,width;
                NSString *totalStr= unitStringFromBytes((double)[curModel fileSize],0,&exponent,&width);
                
                if(!alreadyInList)
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ (%@)", [curModel title], totalStr];
                else{ 
                    cell.textLabel.text = [NSString stringWithFormat:@"%@ (Downloaded)", [curModel title]];
                }
                
                cell.detailTextLabel.text = [curModel desc];
                // Only load cached images; defer new downloads until scrolling ends
                if (!curModel.modelIcon)
                {
                    if (self.tableView.dragging == NO && self.tableView.decelerating == NO)
                    {
                        [self startIconDownload:curModel forIndexPath:indexPath];
                    }
                    // if a download is deferred or in progress, return a placeholder image
                    cell.imageView.image = [UIImage imageNamed:@"Placeholder.png"];                
                }
                else
                {
                    cell.imageView.image = curModel.modelIcon;
                }
                
                
			}
		}
	}

	return cell;
}

- (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath 
{
    if ((isDownloading) && ([indexPath row] != indexOfDownloadingModel))
    {
        cell.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1.0];
    }
    else
    {
        cell.backgroundColor = [UIColor whiteColor];
    }
}

- (void)tableView:(UITableView *)tableView didSelectRowAtIndexPath:(NSIndexPath *)indexPath 
{
	// Prevent any crashes by clicking on a non-normal cell
	if (searchResultRetrievalConnection != nil)
    {
		return;
    }
	else if (downloadaleModelList == nil)
    {
		return;
    }
	// No results to the last search, so display one cell explaining that
	else if ([downloadaleModelList count] == 0)
    {        
		return;
    }
    else if (isDownloading)
    {
        return;
    }
		
	/*if (indexPath.row >= [downloadaleModelList count])
	{
		[self grabNextSetOfSearchResults];
	}
	else*/
	{
        indexOfDownloadingModel = indexPath.row;
        isDownloading = YES;
        self.tableView.backgroundColor = [UIColor colorWithWhite:0.4 alpha:1.0];
        self.tableView.separatorColor = [UIColor colorWithWhite:0.4 alpha:1.0];

        [self.tableView reloadData];

		DownloadedModel *selectedModel = [downloadaleModelList objectAtIndex:[indexPath row]];

        downloadController = [[BenthosDownloadController alloc] initWithDownloadedModel:selectedModel];
        
        [downloadController downloadNewModel];
        [self.navigationItem setHidesBackButton: YES animated: YES];
        self.tableView.allowsSelection = NO;


//		
//		BenthosDownloadViewController *downloadViewController = [[BenthosDownloadViewController alloc] initWithPDBCode:selectedPDBCode andTitle:selectedTitle];
//		
//		[self.navigationController pushViewController:downloadViewController animated:YES];
//		[downloadViewController release];	
	}	
}

- (void)tableView:(UITableView *)tableView accessoryButtonTappedForRowWithIndexPath:(NSIndexPath *)indexPath
{
	NSInteger index = [indexPath row];

		// Display detail view for the protein
		BenthosDetailViewController *detailViewController = [[BenthosDetailViewController alloc] initWithStyle:UITableViewStyleGrouped andDownloadedModel: [downloadaleModelList objectAtIndex:(index)]];
		[self.navigationController pushViewController:detailViewController animated:YES];
		[detailViewController release];
		
	
}

- (void)didReceiveMemoryWarning 
{
    [super didReceiveMemoryWarning];
    
    // terminate all pending download connections
    NSArray *allDownloads = [self.imageDownloadsInProgress allValues];
    [allDownloads makeObjectsPerformSelector:@selector(cancelDownload)];}

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

- (void)addModelsToList:(NSArray *)mod {
    for (DownloadedModel *item in mod) {
        if(item.appVersion <= kMaxiumSupportedFileVersion)
        [downloadaleModelList addObject:item];
    }
    [self.tableView reloadData];

}
#pragma mark -
#pragma mark Accessors
- (void)modelFailedDownloading:(NSNotification *)note;{
    indexOfDownloadingModel = -1;
    isDownloading = NO;
    if(!self.tableView){
        NSLog(@"Null tableview\n");
            return;
    }
    self.tableView.backgroundColor = [UIColor whiteColor];
    self.tableView.separatorColor = [UIColor colorWithWhite:0.88 alpha:1.0];
    [self.tableView reloadData];
    [self.navigationItem setHidesBackButton:NO animated:YES];

    self.tableView.allowsSelection = YES;
    

}

#pragma mark -
#pragma mark Table cell image support

- (void)startIconDownload:(DownloadedModel *)Model forIndexPath:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader == nil) 
    {
        iconDownloader = [[IconDownloader alloc] init];
        iconDownloader.modelRecord = Model;
        iconDownloader.indexPathInTableView = indexPath;
        iconDownloader.delegate = self;
        [imageDownloadsInProgress setObject:iconDownloader forKey:indexPath];
        [iconDownloader startDownload];
        [iconDownloader release];   
    }
}

// this method is used in case the user scrolled into a set of cells that don't have their app icons yet
- (void)loadImagesForOnscreenRows
{
    if ([self.downloadaleModelList count] > 0)
    {
        NSArray *visiblePaths = [self.tableView indexPathsForVisibleRows];
        for (NSIndexPath *indexPath in visiblePaths)
        {
            DownloadedModel *model = [self.downloadaleModelList objectAtIndex:indexPath.row];
            
            if (!model.modelIcon) // avoid the app icon download if the app already has an icon
            {
                [self startIconDownload:model forIndexPath:indexPath];
            }
        }
    }
}

// called by our ImageDownloader when an icon is ready to be displayed
- (void)appImageDidLoad:(NSIndexPath *)indexPath
{
    IconDownloader *iconDownloader = [imageDownloadsInProgress objectForKey:indexPath];
    if (iconDownloader != nil)
    {
        UITableViewCell *cell = [self.tableView cellForRowAtIndexPath:iconDownloader.indexPathInTableView];
        
        // Display the newly loaded image
        cell.imageView.image = iconDownloader.modelRecord.modelIcon;
    }
}


#pragma mark -
#pragma mark Deferred image loading (UIScrollViewDelegate)

// Load images for all onscreen rows when scrolling is finished
- (void)scrollViewDidEndDragging:(UIScrollView *)scrollView willDecelerate:(BOOL)decelerate
{
    if (!decelerate)
	{
        [self loadImagesForOnscreenRows];
    }
}

- (void)scrollViewDidEndDecelerating:(UIScrollView *)scrollView
{
    [self loadImagesForOnscreenRows];
}


@end

