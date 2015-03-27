//
//  BenthosDownloadViewController.m
//  SeafloorExplore
//
//  Modified from Brad Larson's Molecules Project in 2011-2012 for use in The SeafloorExplore Project
//
//  Copyright (C) 2012 Matthew Johnson-Roberson
//
//  See COPYING for license details
//  
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See COPYING for details.
//
//  Created by Brad Larson on 7/2/2008.
//
//  This controller manages the pop-up modal view for downloading new models from the Protein Data Bank

#import "BenthosDownloadController.h"
#import "BenthosAppDelegate.h"
//#import "AFNetworking.h"
@implementation BenthosDownloadController
@synthesize progressView,downloadStatusText,cancelDownloadButton,spinningIndicator,isBackgrounded,downloadConnection,downloadingFileHandle;
- (id)initWithDownloadedModel:(DownloadedModel *)model
{
	if ((self = [super init])) 
	{
		// Initialization code
	//	downloadedFileContents = nil;
		downloadCancelled = NO;
 
        
        [[NSNotificationCenter defaultCenter] addObserver:self
                                                 selector:@selector(updateUntarProgress:)
                                                     name:@"UntarProgress"
                                                   object:nil];
        isBackgrounded=NO;
		
		downloadingmodel = [model  retain];
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
        self.downloadingFileHandle=nil; 

	}
	return self;
}


- (void)dealloc;
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];

	//[self cancelDownload];
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
-(void)appHasGoneToForground;
{
    isBackgrounded=NO;
    
}
-(void)appHasGoneToBackground;
{
    isBackgrounded=YES;
}
-(void)updateUntarProgress:(NSNotification *)note{
     dispatch_async(dispatch_get_main_queue(), ^{
    progressView.hidden = NO;

    if (note != nil){
        NSDictionary *userDict = [note userInfo];

        float progress=[[userDict objectForKey:@"progress"] floatValue];
       // NSString *filename =[userDict objectForKey:@"filename"];
       // NSLog(@"Progress %f %@\n",progress,filename);
        progressView.progress = progress;
        NSNumberFormatter* formatter = [[[NSNumberFormatter alloc] init] autorelease];
        [formatter setMaximumFractionDigits:2];
        [formatter setMinimumFractionDigits:2];
        [formatter setMinimumIntegerDigits:1];
        
        [formatter setFormatWidth:3];
        [formatter setPaddingCharacter:@" "];
        
        downloadStatusText.text = [NSString stringWithFormat:@"Decompressing... %@%%", [formatter stringFromNumber: [NSNumber numberWithDouble: progress*100.0]]];
       // NSLog(@"Progress %@ : %.2f%%\n",filename,progress*100.0);


    }
     });

}
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

- (void)downloadNewModel;
{
	// Check if you already have a protein by that name
	// TODO: Put this check in the init method to grey out download button

    NSArray *libpaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [libpaths objectAtIndex:0];

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
    NSString *xmlpath=[NSString stringWithFormat: @"%@/m.xml",filename];
	if ([[NSFileManager defaultManager] fileExistsAtPath:[libraryDirectory stringByAppendingPathComponent:xmlpath]])
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"File already exists", @"Localized", nil) message:NSLocalizedStringFromTable(@"This model has already been downloaded", @"Localized", nil)
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelDidFinishDownloading" object:nil];
		return;
	}
	
	if (![self downloadModel])
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
        [Flurry logError:@"ModelFailedDownloading" message:errorMessage exception:nil];

        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelDidFinishDownloading" object:nil];
		return;
	}
}

- (BOOL)downloadModel;
{
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];

	downloadStatusText.hidden = NO;
	downloadStatusText.text = NSLocalizedStringFromTable(@"Connecting...", @"Localized", nil);
    progressView.progress = 0.0f;
   
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
    NSMutableURLRequest *req;
    req = [NSMutableURLRequest requestWithURL:[downloadingmodel weblink]
                                  cachePolicy:NSURLRequestReloadIgnoringLocalAndRemoteCacheData
                              timeoutInterval:60.0];
    if (![NSURLConnection canHandleRequest:req]) {
        NSString *errorMessage = NSLocalizedStringFromTable(@"Could not connect to server", @"Localized", nil);
        
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Connection failed", @"Localized", nil) message:errorMessage
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
        [alert show];
		[alert release];
		return NO;
    }
    
    
	/*NSURLRequest *theRequest=[NSURLRequest requestWithURL:[downloadingmodel weblink]
											  cachePolicy:NSURLRequestUseProtocolCachePolicy
										  timeoutInterval:60.0];
	//downloadConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];*/
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *pathtmp = [[[paths objectAtIndex:0] stringByAppendingPathComponent:[downloadingmodel filename]] stringByAppendingString:@".tmp"];;

    
    // Check to see if the download is in progress
    NSUInteger downloadedBytes = 0;
    NSFileManager *fm = [NSFileManager defaultManager];
    if ([fm fileExistsAtPath:pathtmp]) {
        NSError *error = nil;
        NSDictionary *fileDictionary = [fm attributesOfItemAtPath:pathtmp
                                                            error:&error];
        if (!error && fileDictionary)
            downloadedBytes = (NSUInteger)[fileDictionary fileSize];
    } else {
        [fm createFileAtPath:pathtmp contents:nil attributes:nil];
        NSURL *installedURL = [NSURL fileURLWithPath:pathtmp];
        [BenthosAppDelegate addSkipBackupAttributeToItemAtURL:installedURL];
    }
    if (downloadedBytes > 0) {
     //   NSLog(@"Resuming %d\n",downloadedBytes);
        NSString *requestRange = [NSString stringWithFormat:@"bytes=%lu-", (unsigned long)downloadedBytes];
        [req setValue:requestRange forHTTPHeaderField:@"Range"];
    }
    
    self.downloadingFileHandle = [NSFileHandle fileHandleForWritingAtPath:pathtmp];
    [self.downloadingFileHandle seekToEndOfFile];

    downloadProgress =downloadedBytes;
    NSURLConnection *conn = nil;
    conn = [NSURLConnection connectionWithRequest:req delegate:self];
    self.downloadConnection = conn;
    [conn start];

    /*AFHTTPRequestOperation *operation =  [[[AFHTTPRequestOperation alloc] initWithRequest:theRequest] autorelease];
    
    operation.outputStream = [NSOutputStream outputStreamToFileAtPath:path append:NO];
    
    [operation setDownloadProgressBlock:^(NSInteger bytesRead, NSInteger totalBytesRead, NSInteger totalBytesExpectedToRead) {
        [self progress:bytesRead totalRead:totalBytesRead totalFileBytes:totalBytesExpectedToRead];
    }];

    
    [operation setCompletionBlockWithSuccess:^(AFHTTPRequestOperation *operation, id responseObject) {
        [self connectionFinish ];
    } failure:^(AFHTTPRequestOperation *operation, NSError *error) {
        [self connectionError:error];
    }];*/
    
    progressView.hidden = NO;
   // [[NSOperationQueue sharedOperationQueue] addOperation:operation];
   // [operation start];
	/*if (downloadConnection) 
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
	}*/
    
	return YES;
}

- (void)downloadCompleted;
{
	///[downloadOperation release];
	//downloadConnection = nil;
    progressView.hidden = YES;
    cancelDownloadButton.hidden=YES;

    [self.downloadingFileHandle closeFile];
    
    self.downloadingFileHandle = nil;
    self.downloadConnection = nil;

	//[downloadedFileContents release];
//	downloadedFileContents = nil;
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
    
}

- (void)cancelDownload;
{
	downloadCancelled = YES;
   // [self progress:0 totalRead:-1 totalFileBytes:-1];
    [downloadConnection cancel];
    [self downloadCompleted];
    downloadCancelled = NO;
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];

}

#pragma mark -
#pragma mark URL connection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
//- (void)connectionError:(NSError *)error;

{
    self.downloadConnection = nil;

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
    [Flurry logError:@"ModelFailedDownloading" message:errorMessage exception:nil];

	[self downloadCompleted];
    [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];

}

- (void)connection:(NSURLConnection *)connection didReceiveData:(NSData *)data;
//- (void)progress:(NSInteger)bytesRead totalRead:(NSInteger)totalBytesRead totalFileBytes:(NSInteger)totalBytesExpectedToRead;
{
	// Concatenate the new data with the existing data to build up the downloaded file
	// Update the status of the download
	if (downloadCancelled)
	{
      //  [[NSOperationQueue sharedOperationQueue] cancelAllOperations];
        [downloadConnection cancel];
		[self downloadCompleted];
		downloadCancelled = NO;
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];
		return;
	}
	//[downloadedFileContents appendData:data];
    downloadProgress += [data length];
    
    [self.downloadingFileHandle writeData:data];
  //  [self.downloadingFileHandle synchronizeFile];
    

	progressView.progress = (float)downloadProgress / (float)  downloadFileSize  ;
    int exponent=0;
    int width=0;

    NSString *totalStr= unitStringFromBytes((double)downloadFileSize,0,&exponent,&width);
    NSString *progStr=formatBytesNoUnit((double)downloadProgress,0,exponent,width);
	downloadStatusText.text = [NSString stringWithFormat:@"%@: %@/%@",NSLocalizedStringFromTable(@"Downloading", @"Localized", nil),progStr,totalStr];
    //NSLog(@"|%@| %d\n",downloadStatusText.text,[downloadStatusText.text length]);
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
    NSHTTPURLResponse *httpResponse = (NSHTTPURLResponse*)response;
    if (![httpResponse isKindOfClass:[NSHTTPURLResponse class]]) {
        // I don't know what kind of request this is!
        return;
    }
    //Will be overridden if resuming
   	downloadFileSize = [response expectedContentLength];


    NSFileHandle *fh =    self.downloadingFileHandle;
    
    switch (httpResponse.statusCode) {
        case 206: {
            NSString *range = [httpResponse.allHeaderFields valueForKey:@"Content-Range"];
            NSError *error = nil;
            NSRegularExpression *regex = nil;
            // Check to see if the server returned a valid byte-range
            regex = [NSRegularExpression regularExpressionWithPattern:@"bytes (\\d+)-\\d+/\\d+"
                                                              options:NSRegularExpressionCaseInsensitive
                                                                error:&error];
            if (error) {
                [fh truncateFileAtOffset:0];
                break;
            }
            
            // If the regex didn't match the number of bytes, start the download from the beginning
            NSTextCheckingResult *match = [regex firstMatchInString:range
                                                            options:NSMatchingAnchored
                                                              range:NSMakeRange(0, range.length)];
            if (match.numberOfRanges < 2) {
                [fh truncateFileAtOffset:0];
                break;
            }
            
            // Extract the byte offset the server reported to us, and truncate our
            // file if it is starting us at "0".  Otherwise, seek our file to the
            // appropriate offset.
            NSString *byteStr = [range substringWithRange:[match rangeAtIndex:1]];
            NSInteger bytes = [byteStr integerValue];
            if (bytes <= 0) {
                [fh truncateFileAtOffset:0];
                downloadProgress =0;
                break;
            } else {
                [fh seekToFileOffset:bytes];
                downloadProgress =bytes;
                if ([range hasPrefix:@"bytes"]) {
                    NSArray *bytes = [range componentsSeparatedByCharactersInSet:[NSCharacterSet characterSetWithCharactersInString:@" -/"]];
                    if ([bytes count] == 4) {
                        downloadFileSize = [[bytes objectAtIndex:2] longLongValue] ?: -1; // if this is *, it's converted to 0, but -1 is default.
                    }
                }
            }
            break;
        }
            
        case 404: {
            NSString *errorMessage = [NSString stringWithFormat:NSLocalizedStringFromTable(@"No file %@ exists", @"Localized", nil), [downloadingmodel filename]];
            
            UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not find file", @"Localized", nil) message:errorMessage
                                                           delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
            [alert show];
            [alert release];		
            [connection cancel];
            [self downloadCompleted];
            [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];
            
            return;
        }

            
        default:
            [fh truncateFileAtOffset:0];
            downloadProgress =0;
            break;
    }
    
	
	// Stop the spinning wheel and start the status bar for download
	
	if (downloadFileSize > 0)
	{
        progressView.hidden = NO;

		[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];
	}
	downloadStatusText.text = NSLocalizedStringFromTable(@"Connected", @"Localized", nil);

}

- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
//- (void)connectionFinish;
{
//	downloadStatusText.text = NSLocalizedStringFromTable(@"Processing...", @"Localized", nil);

	// Close off the file and write it to disk	
/*	NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
	NSString *documentsDirectory = [paths objectAtIndex:0];
  */  
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
/*
	NSError *error = nil;
	if (![downloadedFileContents writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] options:NSAtomicWrite error:&error])
	{
        
        
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Write failed", @"Localized", nil) message:@"Could not write file to disk out of space?"
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
        [alert show];
		[alert release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];

		// TODO: Do some error handling here
		return;
	}
	*/
	// Notify about the addition of the new model
    /*if (searchType == PROTEINDATABANKSEARCH)
    {
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelDidFinishDownloading" object:filename];
    }
    else
    {*/
    
    [self downloadCompleted];

    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *pathtmp = [[[paths objectAtIndex:0] stringByAppendingPathComponent:[downloadingmodel filename]] stringByAppendingString:@".tmp"];;
    NSString *path = [[paths objectAtIndex:0] stringByAppendingPathComponent:[downloadingmodel filename]];

    NSFileManager *fm = [NSFileManager defaultManager];
    NSError *error = nil;

    if (![fm moveItemAtPath:pathtmp toPath:path error:&error]) {
        UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Write failed", @"Localized", nil) message:@"Could not write file to disk out of space?"
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
        [alert show];
		[alert release];
        [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelFailedDownloading" object:nil];
        
		// TODO: Do some error handling here
		return;
    }
  
    NSURL *pathURL = [NSURL fileURLWithPath:path];
    [BenthosAppDelegate addSkipBackupAttributeToItemAtURL:pathURL];
    
    
    NSString *filename = [downloadingmodel filename];

    NSDictionary *dictionary = 
    [NSDictionary dictionaryWithObjectsAndKeys:[NSString stringWithString:filename], 
     @"downloadmodel", 
     nil];
    [Flurry logEvent:@"DOWNLOADMODEL" withParameters:dictionary];

    //progressView.hidden = YES;
    progressView.progress = 0.0f;

    cancelDownloadButton.hidden=YES;
    spinningIndicator.hidden=NO;
    [self.spinningIndicator performSelectorOnMainThread:@selector(startAnimating) withObject:nil waitUntilDone:YES];

    [spinningIndicator startAnimating];
	//downloadStatusText.text = NSLocalizedStringFromTable(@"Decompressing...", @"Localized", nil);

    //printf("Download complete\n");
    /*if(![self isBackgrounded])
        [self performSelector:@selector(sendDownloadFinishedMsg:) withObject:filename afterDelay:0.3];
    else 
        [self performSelector:@selector(sendDownloadFinishedMsg:) withObject:nil afterDelay:0.3];
*/
         [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelDidFinishDownloading" object:filename userInfo:[NSDictionary dictionaryWithObject:downloadingmodel  forKey:@"model"]];
  
   /// else {
      // [self performSelector:@selector(sendDownloadFinishedMsg:) withObject:nil afterDelay:0.3];

   // }
/*    else {
              [self performSelector:@selector(sendDownloadFinishedMsg:) withObject:filename afterDelay:5.0];

    }*/
    //}
	
//	if ([BenthosAppDelegate isRunningOniPad])
//	{
//		[self.navigationController popViewControllerAnimated:YES];
//	}
	
	[self downloadCompleted];	
}
-(void) sendDownloadFinishedMsg:(NSString*)filename {

       [[NSNotificationCenter defaultCenter] postNotificationName:@"ModelDidFinishDownloading" object:filename userInfo:[NSDictionary dictionaryWithObject:downloadingmodel  forKey:@"model"]];  
}
#pragma mark -
#pragma mark Accessors

@end
