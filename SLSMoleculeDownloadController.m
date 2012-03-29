//
//  SLSMoleculeDownloadViewController.m
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/2/2008.
//
//  This controller manages the pop-up modal view for downloading new molecules from the Protein Data Bank

#import "SLSMoleculeDownloadController.h"
#import "SLSMoleculeAppDelegate.h"

@implementation SLSMoleculeDownloadController
@synthesize progressView,downloadStatusText,cancelDownloadButton,spinningIndicator;
- (id)initWithModel:(Model *)model
{
	if ((self = [super init])) 
	{
		// Initialization code
		downloadedFileContents = nil;
		downloadCancelled = NO;
        
		
		downloadingmodel = [model  copy];
        progressView = [[[UIProgressView alloc] initWithFrame:CGRectZero] retain];
        downloadStatusText = [[[UILabel alloc] initWithFrame:CGRectZero] retain ];
        downloadStatusText.textColor = [UIColor blackColor];
        downloadStatusText.font = [UIFont boldSystemFontOfSize:16.0];
        downloadStatusText.textAlignment = UITextAlignmentLeft;
        
        cancelDownloadButton =  [[[UIButton alloc] initWithFrame:CGRectZero] retain];//[UIButton buttonWithType:UIButtonTypeRoundedRect];
       // [cancelDownloadButton setTitle:@"Cancel" forState:UIControlStateNormal];
        //[cancelDownloadButton setBackgroundImage:[[UIImage imageNamed:@"redButton.png"] stretchableImageWithLeftCapWidth:10.0 topCapHeight:0.0] forState:UIControlStateNormal];   
        cancelDownloadButton.contentMode = UIViewContentModeScaleToFill;

        [cancelDownloadButton setImage:[UIImage imageNamed:@"redx.png"] forState:UIControlStateNormal];
        [cancelDownloadButton addTarget:self action:@selector(cancelDownload) forControlEvents:UIControlEventTouchUpInside];
        
        spinningIndicator = [[[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleGray] retain];


	}
	return self;
}


- (void)dealloc;
{
	[self cancelDownload];
	[downloadingmodel release];
    [progressView release];
    [spinningIndicator release];
    [downloadStatusText release];
    [cancelDownloadButton release];
    self.downloadStatusText = nil;

	[super dealloc];
}
enum {
    kUnitStringBinaryUnits     = 1 << 0,
    kUnitStringOSNativeUnits   = 1 << 1,
    kUnitStringLocalizedFormat = 1 << 2
};

NSString* formatBytesNoUnit(double bytes, uint8_t flags,int exponent,int width){
    int multiplier = ((flags & kUnitStringOSNativeUnits && /*!leopardOrGreater()*/0) || flags & kUnitStringBinaryUnits) ? 1024 : 1000;

    for(int i=0;i <exponent; i++)
        bytes /= multiplier;


    NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMaximumFractionDigits:2];
    [formatter setMinimumFractionDigits:2];
    [formatter setMinimumIntegerDigits:1];

    [formatter setFormatWidth:width];
    [formatter setPaddingCharacter:@" "];
    if (flags & kUnitStringLocalizedFormat) {
        [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    }
    // Beware of reusing this format string. -[NSString stringWithFormat] ignores \0, *printf does not.

    return [NSString stringWithFormat:@"%@", [formatter stringFromNumber: [NSNumber numberWithDouble: bytes]]];
}
NSString* unitStringFromBytes(double bytes, uint8_t flags,int *exponent,int *width){
    
    static const char units[] = { '\0', 'k', 'M', 'G', 'T', 'P', 'E', 'Z', 'Y' };
    static int maxUnits = sizeof units - 1;
    
    int multiplier = ((flags & kUnitStringOSNativeUnits && /*!leopardOrGreater()*/0) || flags & kUnitStringBinaryUnits) ? 1024 : 1000;
    *exponent = 0;
    
    while (bytes >= multiplier && *exponent < maxUnits) {
        bytes /= multiplier;
        (*exponent)++;
    }
    NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
    [formatter setMinimumFractionDigits:2];

    [formatter setMaximumFractionDigits:2];
    if (flags & kUnitStringLocalizedFormat) {
        [formatter setNumberStyle: NSNumberFormatterDecimalStyle];
    }
    NSString *str=[formatter stringFromNumber: [NSNumber numberWithDouble: bytes]];
    *width=[str length];
    // Beware of reusing this format string. -[NSString stringWithFormat] ignores \0, *printf does not.
    return [NSString stringWithFormat:@"%@ %cB", str, units[*exponent]];
}
#pragma mark -
#pragma mark Protein downloading

- (void)downloadNewMolecule;
{
	// Check if you already have a protein by that name
	// TODO: Put this check in the init method to grey out download button
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];

    //NSString *fileExtension = @"";
  /*  if (searchType == PROTEINDATABANKSEARCH)
    {
        fileExtension = @"pdb.gz";
    }
    else
    {
        fileExtension = @"sdf";        
    }*/
    cancelDownloadButton.hidden = NO;

    NSString *filename = [[[downloadingmodel filename] lastPathComponent] stringByDeletingPathExtension];	
    NSString *octreepath=[NSString stringWithFormat: @"%@/%@.octree",filename,filename];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:octreepath]])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"File already exists", @"Localized", nil) message:NSLocalizedStringFromTable(@"This model has already been downloaded", @"Localized", nil)
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoleculeDidFinishDownloading" object:nil];
		return;
	}
	
	if (![self downloadMolecule])
	{
        NSString *errorMessage = nil;
        
       /* if (searchType == PROTEINDATABANKSEARCH)
        {
            errorMessage = NSLocalizedStringFromTable(@"Could not connect to the Protein Data Bank", @"Localized", nil);
        }
        else
        {
            errorMessage = NSLocalizedStringFromTable(@"Could not connect to PubChem", @"Localized", nil);
        }*/
        errorMessage = NSLocalizedStringFromTable(@"Could not connect to server", @"Localized", nil);

        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Connection failed", @"Localized", nil) message:errorMessage
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoleculeDidFinishDownloading" object:nil];
		return;
	}
}

- (BOOL)downloadMolecule;
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	downloadStatusText.hidden = NO;
	downloadStatusText.text = NSLocalizedStringFromTable(@"Connecting...", @"Localized", nil);
    progressView.progress = 0.0f;

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
	NSURLRequest *theRequest=[NSURLRequest requestWithURL:[downloadingmodel weblink]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy
										  timeoutInterval:60.0];
	downloadConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
	if (downloadConnection) 
	{
		// Create the NSMutableData that will hold
		// the received data
		// receivedData is declared as a method instance elsewhere
		downloadedFileContents = [[NSMutableData data] retain];
	} 
	else 
	{
		// inform the user that the download could not be made
		return NO;
	}
	return YES;
}

- (void)downloadCompleted;
{
	[downloadConnection release];
	downloadConnection = nil;
    progressView.hidden = YES;
    cancelDownloadButton.hidden=YES;

	[downloadedFileContents release];
	downloadedFileContents = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
}

- (void)cancelDownload;
{
	downloadCancelled = YES;
}

#pragma mark -
#pragma mark URL connection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
    NSString *errorMessage = nil;
    
    /*if (searchType == PROTEINDATABANKSEARCH)
    {
        errorMessage = NSLocalizedStringFromTable(@"Could not connect to the Protein Data Bank", @"Localized", nil);
    }
    else
    {*/
        errorMessage = NSLocalizedStringFromTable(@"Could not connect to server", @"Localized", nil);
//    }

	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Connection failed", @"Localized", nil) message:errorMessage
												   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
	[alert show];
	[alert release];
	
	[self downloadCompleted];
}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
{
	// Concatenate the new data with the existing data to build up the downloaded file
	// Update the status of the download

	if (downloadCancelled)
	{
		[connection cancel];
		[self downloadCompleted];
		downloadCancelled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoleculeFailedDownloading" object:nil];
		return;
	}
	[downloadedFileContents appendData:data];
	progressView.progress = (float)[downloadedFileContents length] / (float)  downloadFileSize  ;
    int exponent=0;
    int width=0;

    NSString *totalStr= unitStringFromBytes((double)downloadFileSize,0,&exponent,&width);
    NSString *progStr=formatBytesNoUnit((double)[downloadedFileContents length],0,exponent,width);
	downloadStatusText.text = [NSString stringWithFormat:@"%@: %@/%@",NSLocalizedStringFromTable(@"Downloading", @"Localized", nil),progStr,totalStr];
    //NSLog(@"|%@| %d\n",downloadStatusText.text,[downloadStatusText.text length]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
	downloadFileSize = [response expectedContentLength];
	
	// Stop the spinning wheel and start the status bar for download
	if ([response textEncodingName] != nil)
	{
        NSString *errorMessage = nil;
        
       /* if (searchType == PROTEINDATABANKSEARCH)
        {
            errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"No protein with the code %@ exists in the data bank", @"Localized", nil), codeForCurrentlyDownloadingMolecule];
        }
        else
        {*/
            errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"No file %@ exists", @"Localized", nil), [downloadingmodel filename]];
        //}

		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not find file", @"Localized", nil) message:errorMessage
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];		
		[connection cancel];
		[self downloadCompleted];
		return;
	}
	
	if (downloadFileSize > 0)
	{
        progressView.hidden = NO;

		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	downloadStatusText.text = NSLocalizedStringFromTable(@"Connected", @"Localized", nil);

	// TODO: Deal with a 404 error by checking filetype header
}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{
//	downloadStatusText.text = NSLocalizedStringFromTable(@"Processing...", @"Localized", nil);

	// Close off the file and write it to disk	
	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
    
    //NSString *fileExtension = @"";
  /*  if (searchType == PROTEINDATABANKSEARCH)
    {
        fileExtension = @"pdb.gz";
    }
    else
    {
        fileExtension = @"sdf";        
    }
*/
	NSString *filename = [downloadingmodel filename];
	NSError *error = nil;
	if (![downloadedFileContents writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] options:NSAtomicWrite error:&error])
	{
        
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Write failed", @"Localized", nil) message:@"Could not write file to disk out of space?"
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
        [alert show];
		[alert release];

		// TODO: Do some error handling here
		return;
	}
	
	// Notify about the addition of the new molecule
    /*if (searchType == PROTEINDATABANKSEARCH)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"MoleculeDidFinishDownloading" object:filename];
    }
    else
    {*/
    progressView.hidden = YES;
    cancelDownloadButton.hidden=YES;
    spinningIndicator.hidden=NO;
    [self.spinningIndicator performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:NO];

    [spinningIndicator startAnimating];
	downloadStatusText.text = NSLocalizedStringFromTable(@"Decompressing...", @"Localized", nil);

 
    [self performSelector:@selector(sendDownloadFinishedMsg:) withObject:filename afterDelay:0.3];

    //}
	
//	if ([SLSMoleculeAppDelegate isRunningOniPad])
//	{
//		[self.navigationController popViewControllerAnimated:YES];
//	}
	
	[self downloadCompleted];	
}
-(void) sendDownloadFinishedMsg:(NSString*)filename {
       [[NSNotificationCenter defaultCenter] postNotificationName:@"MoleculeDidFinishDownloading" object:filename userInfo:[NSDictionary dictionaryWithObject:[downloadingmodel filename] forKey:@"title"]];  
}
#pragma mark -
#pragma mark Accessors

@end
