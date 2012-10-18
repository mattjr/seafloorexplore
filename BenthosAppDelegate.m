//
//  BenthossAppDelegate.m
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 5/18/2008.
//
//  This is the base application delegate, used for handling launch, termination, and memory-related delegate methods

#import "BenthosAppDelegate.h"
#import "BenthosRootViewController.h"
#import "BenthosiPadRootViewController.h"
#import "BenthosGLViewController.h"
#import "BenthosTableViewController.h"
#import "Benthos.h"
#import "NSData+Gzip.h"
#import "NSFileManager+Tar.h"
#import "ModelParseOperation.h"
#import "VCTitleCase.h"
#import "BenthosOpenGLESRenderer.h"
#import "JSGCDDispatcher.h"
#import "BackgroundProcessingFile.h"
#include <sys/xattr.h>

#define MODELS_DATABASE_VERSION 1

@implementation BenthosAppDelegate

@synthesize window;
@synthesize rootViewController;
#pragma mark -
#pragma mark Initialization / teardown
void uncaughtExceptionHandler(NSException *exception) {
    [FlurryAnalytics logError:@"Uncaught" message:@"Crash!" exception:exception];
}
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions   
{	
    NSSetUncaughtExceptionHandler(&uncaughtExceptionHandler);
    [FlurryAnalytics startSession:@"6VB3L2AH89FJ6D1XLZC4"];
	//Initialize the application window
	window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
	if (!window) 
	{
		[self release];
		return NO;
	}
	window.backgroundColor = [UIColor blackColor];
	models = [[NSMutableArray alloc] init];
    decompressingfiles = [[NSMutableArray alloc] init];



	if ([BenthosAppDelegate isRunningOniPad])
	{
		UISplitViewController *newSplitViewController = [[UISplitViewController alloc] init];
        if ([newSplitViewController respondsToSelector:@selector(setPresentsWithGesture:)])
            [newSplitViewController setPresentsWithGesture:NO]; // SplitView won't recognize right swipe
		rootViewController = [[BenthosiPadRootViewController alloc] init];
		[rootViewController loadView];
		newSplitViewController.viewControllers = [NSArray arrayWithObjects:rootViewController.tableNavigationController, rootViewController, nil];
		newSplitViewController.delegate = (BenthosiPadRootViewController *)rootViewController;
		splitViewController = newSplitViewController;
		//[window addSubview:splitViewController.view];
        [self.window setRootViewController:splitViewController];
	}
	else
	{
		rootViewController = [[BenthosRootViewController alloc] init];
		//[window addSubview:rootViewController.view];
        [self.window setRootViewController:rootViewController];

	}
    rootViewController.models = models;
    rootViewController.decompressingfiles = decompressingfiles;
	
    [window makeKeyAndVisible];
	[window layoutSubviews];	
	
	// Start the initialization of the database, if necessary
	isHandlingCustomURLModelDownload = NO;
	downloadedFileContents = nil;
	initialDatabaseLoadLock = [[NSLock alloc] init];
    //networkQueue = [[[NSOperationQueue alloc] init] autorelease];

	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	NSURL *url = (NSURL *)[launchOptions valueForKey:UIApplicationLaunchOptionsURLKey];
	
	if (url != nil)
	{
		isHandlingCustomURLModelDownload = YES;		
	}
    [self showStatusIndicator];
  //  [self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];
  //  [self loadInitialModelsFromDisk];
    [self performSelectorInBackground:@selector(loadInitialModelsFromDisk) withObject:nil];	
   // [self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:YES];
    [self hideStatusIndicator];
	return YES;
}


/*- (BOOL)application:(UIApplication *)application handleOpenURL:(NSURL *)url
{
	
	if (url != nil)
	{
		isHandlingCustomURLModelDownload = YES;		
	}
	
	// Deal with case where you are in the table view
	if (![BenthosAppDelegate isRunningOniPad])
	{
		if ([rootViewController.glViewController.view superview] == nil)
		{
			[[NSNotificationCenter defaultCenter] postNotificationName:@"ToggleView" object:nil];
		}
	}
	
	// Handle the Models custom URL scheme
	[self handleCustomURLScheme:url];
	
	return YES;
}
*/
- (void)dealloc 
{
	[splitViewController release];
	[initialDatabaseLoadLock release];
	[models release];
	[rootViewController release];
	[window release];
	[super dealloc];
}

#pragma mark -
#pragma mark Device-specific interface control

/*+ (BOOL)isRunningOniPad;
{
	return (UI_USER_INTERFACE_IDIOM() == UIUserInterfaceIdiomPad);
}*/

+ (BOOL)isRunningOniPad;
{
	static BOOL hasCheckediPadStatus = NO;
	static BOOL isRunningOniPad = NO;
	
	if (!hasCheckediPadStatus)
	{
		if ([[UIDevice currentDevice] respondsToSelector:@selector(userInterfaceIdiom)])
		{
			if ([[UIDevice currentDevice] userInterfaceIdiom] == UIUserInterfaceIdiomPad)
			{
				isRunningOniPad = YES;
				hasCheckediPadStatus = YES;
				return isRunningOniPad;
			}
		}

		hasCheckediPadStatus = YES;
	}
	
	return isRunningOniPad;
}

#pragma mark -
#pragma mark Database access

- (NSString *)applicationSupportDirectory;
{	
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSApplicationSupportDirectory, NSUserDomainMask, YES);
    NSString *basePath = ([paths count] > 0) ? [paths objectAtIndex:0] : nil;
	
	NSFileManager *fileManager = [NSFileManager defaultManager];
	if ([fileManager fileExistsAtPath:basePath] == NO)
	{
		NSError *error = nil;
		[fileManager createDirectoryAtPath:basePath withIntermediateDirectories:NO attributes:nil error:&error];
	}
	
    return basePath;
}

- (BOOL)createEditableCopyOfDatabaseIfNeeded; 
{
    // First, see if the database exists in the /Documents directory.  If so, move it to Application Support.
    NSFileManager *fileManager = [NSFileManager defaultManager];
    NSError *error;
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];
    NSString *writableDBPath = [documentsDirectory stringByAppendingPathComponent:@"models.sql"];
    if ([fileManager fileExistsAtPath:writableDBPath])
	{
		[fileManager moveItemAtPath:writableDBPath toPath:[[self applicationSupportDirectory] stringByAppendingPathComponent:@"models.sql"] error:&error];
	}
	
	writableDBPath = [[self applicationSupportDirectory] stringByAppendingPathComponent:@"models.sql"];
	
    if ([fileManager fileExistsAtPath:writableDBPath])
		return NO;
	
    // The database does not exist, so copy a blank starter database to the Documents directory
    NSString *defaultDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:@"models.sql"];
    BOOL success = [fileManager copyItemAtPath:defaultDBPath toPath:writableDBPath error:&error];
    if (!success) {
		NSAssert1(0,NSLocalizedStringFromTable(@"Failed to create writable database file with message '%@'.", @"Localized", nil), [error localizedDescription]);
    }
	return YES;
}

- (void)connectToDatabase;
{
	
	// The database is stored in the application bundle. 
    NSString *path = [[self applicationSupportDirectory] stringByAppendingPathComponent:@"models.sql"];
    // Open the database. The database was prepared outside the application.
    if (sqlite3_open([path UTF8String], &database) == SQLITE_OK) 
	{
    } 
	else 
	{
        // Even though the open failed, call close to properly clean up resources.
        sqlite3_close(database);
		NSAssert1(0,NSLocalizedStringFromTable(@"Failed to open database with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
        // Additional error handling, as appropriate...
    }
	
}

- (void)disconnectFromDatabase;
{
// TODO: Maybe write out all database entries to disk
	//	[books makeObjectsPerformSelector:@selector(dehydrate)];
	[BenthosModel finalizeStatements];
    // Close the database.
    if (sqlite3_close(database) != SQLITE_OK) 
	{
		//NSAssert1(0,NSLocalizedStringFromTable(@"Error: failed to close database with message '%s'.", @"Localized", nil), sqlite3_errmsg(database));
    }
	
	database = nil;
}

- (void)loadInitialModelsFromDisk;
{
	[initialDatabaseLoadLock lock];

	NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init];
	rootViewController.models = nil;

	if ([self createEditableCopyOfDatabaseIfNeeded])
	{
		// The database needed to be recreated, so scan and copy over the default files
        [self performSelectorOnMainThread:@selector(showStatusIndicator) withObject:nil waitUntilDone:NO];

		[self connectToDatabase];
		// Before anything else, move included PDB files to /Documents if the program hasn't been run before
		// User might have intentionally deleted files, so don't recopy the files in that case
	//	NSError *error = nil;
		// Grab the /Documents directory path
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
		NSString *libDirectory = [paths objectAtIndex:0];
		
		NSFileManager *fileManager = [NSFileManager defaultManager];
		// Iterate through all files sitting in the application's Resources directory
		// TODO: Can you fast enumerate this?
		NSDirectoryEnumerator *direnum = [fileManager enumeratorAtPath:[[NSBundle mainBundle] resourcePath]];
		NSString *pname;
		while ((pname = [direnum nextObject]))
		{
			if ([[pname pathExtension] isEqualToString:@"tar"])
			{
				NSString *preloadedPDBPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:pname];
				//NSString *installedPDBPath = [documentsDirectory stringByAppendingPathComponent:pname];
				
			//	NSString *preloadedTexPath = [[[NSBundle mainBundle] resourcePath] stringByAppendingPathComponent:[pname stringByDeletingPathExtension]];
				NSString *installedTexPath = [libDirectory stringByAppendingPathComponent:[pname stringByDeletingPathExtension]];
                if(installedTexPath == nil || [installedTexPath length] == 0 )
                    continue;
				if (![fileManager fileExistsAtPath:installedTexPath])
				{
                   // NSLog(@"Processing '%@' to '%@'\n",preloadedPDBPath,installedTexPath);
                    /*
					
                    // Move included PDB files to /Documents
					[[NSFileManager defaultManager]	copyItemAtPath:preloadedPDBPath toPath:installedPDBPath error:&error];
					if (error != nil)
					{
//						NSLog(@"Failed to copy over PDB files with error: '%@'.", [error localizedDescription]);
						// TODO: Report the file copying problem to the user or do something about it
					}
					NSLog(@"Failed to copy over PDB files with error: '%@' ' %@'.", preloadedTexPath,installedTexPath);
					if ([fileManager fileExistsAtPath:preloadedTexPath] && ![fileManager fileExistsAtPath:installedTexPath]){

						[[NSFileManager defaultManager]	copyItemAtPath:preloadedTexPath toPath:installedTexPath error:&error];*/
                   // NSData* tarData = [NSData dataWithContentsOfFile:preloadedPDBPath];
                    NSError *error=nil;
                    [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:libDirectory withTarPath:preloadedPDBPath error:&error];
                    
						if (error != nil)
						{
											NSLog(@"Failed to untar %@ preinstalled files  with error: '%@'.", preloadedPDBPath,[error localizedDescription]);
                            /*if (![[NSFileManager defaultManager] removeItemAtPath:preloadedPDBPath error:&error])
                            {
                                
                            }*/

							// TODO: Report the file copying problem to the user or do something about it
						}
                        NSURL *installedURL = [NSURL fileURLWithPath:installedTexPath];

                        [BenthosAppDelegate addSkipBackupAttributeToItemAtURL:installedURL];
                      
					//}
				}
				
			}
		}
		
		[self loadMissingModelsIntoDatabase];
		
		[[NSUserDefaults standardUserDefaults] synchronize];
        [self performSelectorOnMainThread:@selector(hideStatusIndicator) withObject:nil waitUntilDone:YES];

	}
	else
	{
		// The MySQL database has been created, so load models from the database
		[self connectToDatabase];
		// TODO: Check to make sure that the proper version of the database is installed
		[self loadAllModelsFromDatabase];
		[self loadMissingModelsIntoDatabase];		
	}
	
	rootViewController.database = database;
	rootViewController.models = models;
	[initialDatabaseLoadLock unlock];

	if ([BenthosAppDelegate isRunningOniPad])
	{
		[[rootViewController.tableViewController tableView] performSelectorOnMainThread:@selector(reloadData) withObject:nil waitUntilDone:NO];
	}
	
	if (!isHandlingCustomURLModelDownload)
		[rootViewController loadInitialModel];

	[pool release];
}

- (void)loadAllModelsFromDatabase;
{
	const char *sql = "SELECT * FROM models";
	sqlite3_stmt *modelLoadingStatement;

	if (sqlite3_prepare_v2(database, sql, -1, &modelLoadingStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(modelLoadingStatement) == SQLITE_ROW) 
		{
			BenthosModel *newModel = [[BenthosModel alloc] initWithSQLStatement:modelLoadingStatement database:database];
			if (newModel != nil)
				[models addObject:newModel];
				
			[newModel release];
		}
	}
	// "Finalize" the statement - releases the resources associated with the statement.
	sqlite3_finalize(modelLoadingStatement);	
}
-(void)addNewModel:(NSString*)pname
{
    //NSLog(@"Model Adding Complete! %@\n",pname);

    // Now, check all the files on disk to see if any are missing from the database
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libDirectory = [paths objectAtIndex:0];


    NSString *preloadedXMLPath = [libDirectory stringByAppendingPathComponent:pname];
    NSMutableData* xmlData = [NSMutableData dataWithContentsOfFile:preloadedXMLPath];
    ModelParseOperation *parseOperation = [[ModelParseOperation alloc] initWithData:xmlData];
    NSMutableArray *filesystemModels = [NSMutableArray array];
    [parseOperation staticparse:filesystemModels];
    [parseOperation release];   // once added to the NSOperationQueue it's retained, we don't need it anymore
    // earthquakeData will be retained by the NSOperation until it has finished executing,
    // so we no longer need a reference to it in the main thread.
    if([filesystemModels count] >0){
        
        // Parse the PDB file into the database
        BenthosModel *newModel = [[BenthosModel alloc] initWithDownloadedModel:[filesystemModels objectAtIndex:0] database:database];
        if (newModel != nil)
        {
            
            [models addObject:newModel];
        }
        [newModel release];		
    }
    else{
        NSLog(@"Failed to Parse'%@'.", preloadedXMLPath);
        
    }
    NSString *basename = [[[pname stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension];	
    NSMutableArray *discardedItems = [NSMutableArray array];

    
    for(BackgroundProcessingFile *file in decompressingfiles){
        if([basename isEqualToString:[file filenameWithoutExtension]]){
            [discardedItems addObject:file];
        }
        
    }
    [decompressingfiles removeObjectsInArray:discardedItems];

    if (rootViewController.tableViewController != nil)
    {
        [rootViewController.tableViewController.tableView reloadData];		
        if([models count] == 1)
            [rootViewController selectedModelDidChange:([models count] - 1)];
    }
    
   



}

- (void)loadMissingModelsIntoDatabase;
{
	// First, load all model names from the database
	NSMutableDictionary *modelFilenameLookupTable = [[NSMutableDictionary alloc] init];
	
	const char *sql = "SELECT * FROM models";
	sqlite3_stmt *modelLoadingStatement;
	
	if (sqlite3_prepare_v2(database, sql, -1, &modelLoadingStatement, NULL) == SQLITE_OK) 
	{
		while (sqlite3_step(modelLoadingStatement) == SQLITE_ROW) 
		{
			char *stringResult = (char *)sqlite3_column_text(modelLoadingStatement, 3);
			NSString *sqlString =  (stringResult) ? [NSString stringWithUTF8String:stringResult]  : @"";
			NSString *basename = [[sqlString stringByReplacingOccurrencesOfString:@"''" withString:@"'"] stringByDeletingPathExtension];
			[modelFilenameLookupTable setValue:[NSNumber numberWithBool:YES] forKey:basename];
		}
	}
	sqlite3_finalize(modelLoadingStatement);	
	
	// Now, check all the files on disk to see if any are missing from the database
	NSArray *libpaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
	NSString *libDirectory = [libpaths objectAtIndex:0];
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0];

    {
        NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
                                          enumeratorAtPath:libDirectory];
        NSString *pname;
        while ((pname = [direnum nextObject]))
        {
            
            NSDictionary *pathAttrs = [direnum fileAttributes];
            NSUInteger level = [direnum level];
            
            BOOL isDir = [[pathAttrs objectForKey:NSFileType] isEqual:NSFileTypeDirectory];
            if(isDir && level == 2)
                [direnum skipDescendents];
            NSString *basename = [[[pname stringByDeletingLastPathComponent] lastPathComponent] stringByDeletingPathExtension];	
            NSString *filename = [pname stringByDeletingPathExtension]  ;

            BOOL alreadyProcessing=NO;
           
            for(BackgroundProcessingFile *file in decompressingfiles){
                if([filename isEqualToString:[file filenameWithoutExtension]]){
                    alreadyProcessing=YES;
                }
            }
            if(alreadyProcessing)
                continue;

            if(([basename length] > 0) && ([modelFilenameLookupTable valueForKey:basename] == nil) && ([[[pname pathExtension] lowercaseString] isEqualToString:@"xml"])){
                [self addNewModel: pname]; 
                
            }
            
        }
    }
    
    {

        NSDirectoryEnumerator *direnum = [[NSFileManager defaultManager]
                                          enumeratorAtPath:documentsDirectory];
        NSString *pname;
        while ((pname = [direnum nextObject]))
        {
      
            NSDictionary *pathAttrs = [direnum fileAttributes];
            NSUInteger level = [direnum level];
            
            BOOL isDir = [[pathAttrs objectForKey:NSFileType] isEqual:NSFileTypeDirectory];
            if(isDir && level == 2)
                [direnum skipDescendents];
            
            if([[[pname pathExtension] lowercaseString] isEqualToString:@"tar"] && ([modelFilenameLookupTable valueForKey:[pname stringByDeletingPathExtension]] == nil)){
                NSString *filename = [pname stringByDeletingPathExtension]  ;
                BOOL alreadyProcessing=NO;
                for(BackgroundProcessingFile *file in decompressingfiles){
                    if([filename isEqualToString:[file filenameWithoutExtension]]){
                        alreadyProcessing=YES;
                    }
                }
                if(alreadyProcessing)
                    continue;

                //NSLog(@"Adding %@\n",[pname stringByDeletingPathExtension]);
                NSString *installedTexPath = [libDirectory stringByAppendingPathComponent:[pname stringByDeletingPathExtension]];
                if ([[NSFileManager defaultManager] fileExistsAtPath:installedTexPath]){
                    NSLog(@"Warning removing incomplete folder %@\n",[pname stringByDeletingPathExtension]);
                    [BenthosAppDelegate removeModelFolder:[pname stringByDeletingPathExtension]];
                }
                
                /*  NSDictionary*  userInfo = [NSDictionary dictionaryWithObjectsAndKeys:
                 filename, @"filename",nil];
                 NSLog(@"Tar found %@\n",filename);
                 
                 [filename release];
                 
                 [[NSNotificationCenter defaultCenter]
                 postNotificationName:@"NewBGTask"
                 object:self userInfo:userInfo];
                 */
                BackgroundProcessingFile *curProg = [[BackgroundProcessingFile alloc] initWithName:filename];
                [decompressingfiles addObject:curProg];
                [curProg release];
                dispatch_async(dispatch_get_main_queue(), ^{  if (rootViewController.tableViewController != nil)
                {
                    [rootViewController.tableViewController.tableView reloadData];				
                }	
                });

                [[JSGCDDispatcher sharedDispatcher] dispatchOnSerialQueue:^{
                    
                    //  dispatch_async( dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^{
                    NSString *fname = [pname stringByDeletingPathExtension];	
                    // NSLog(@"Startup Unarchive Block Executed On %s %@", dispatch_queue_get_label(dispatch_get_current_queue()),fname);
                    
                    NSError *error=nil;
                    if([BenthosAppDelegate processArchive:pname error:&error]){
                        //NSLog(@"Startup Decompress Finished %@\n",pname);
                        NSString *pname=[NSString stringWithFormat:@"%@/m.xml", fname];
                        dispatch_async(dispatch_get_main_queue(), ^{ [self addNewModel: pname]; });
                    }else{
                        NSLog(@"Fail to extract %@ %@ %@\n",[error localizedDescription],pname,installedTexPath);
                        NSMutableArray *discardedItems = [NSMutableArray array];
                        for(BackgroundProcessingFile *file in decompressingfiles){
                            if([filename isEqualToString:[file filenameWithoutExtension]]){
                                [discardedItems addObject:file];
                            }
                        }
                        [decompressingfiles removeObjectsInArray:discardedItems];
                        
                        dispatch_async(dispatch_get_main_queue(), ^{  if (rootViewController.tableViewController != nil)
                        {
                            [rootViewController.tableViewController.tableView reloadData];				
                        }	
                        });
                        
                    }
                }];
                
            }
        }
        
		
	}
	
	[modelFilenameLookupTable release];
}

#pragma mark -
#pragma mark Status update methods

- (void)showStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingStarted" object:NSLocalizedStringFromTable(@"Initializing database...", @"Localized", nil)];
}

- (void)showDownloadIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingStarted" object:NSLocalizedStringFromTable(@"Downloading model...", @"Localized", nil)];
}

- (void)updateStatusIndicator;
{
	
}

- (void)hideStatusIndicator;
{
	[[NSNotificationCenter defaultCenter] postNotificationName:@"FileLoadingEnded" object:nil];
}

#pragma mark -
#pragma mark Flow control

- (void)applicationWillResignActive:(UIApplication *)application 
{
   // [[NSOperationQueue sharedOperationQueue] setSuspended:YES]; 
    
	[[NSUserDefaults standardUserDefaults] synchronize];		

}

- (void)applicationDidBecomeActive:(UIApplication *)application 
{
    //[[NSOperationQueue sharedOperationQueue] setSuspended:NO]; 

}

- (void)applicationWillTerminate:(UIApplication *)application 
{
	if (database != nil)
	{
		[rootViewController cancelModelLoading];
		[self disconnectFromDatabase];
	}
}


- (void)applicationWillEnterForeground:(UIApplication *)application
{
/*	if (database == nil)
	{
		[self connectToDatabase];
	}*/
  //  bgTask = UIBackgroundTaskInvalid; 
 //   [rootViewController.glViewController showScanningIndicator:nil];
   //[rootViewController.glViewController.modelToDisplay showStatusIndicator];

    /*dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
    NSAutoreleasePool *pool = [[NSAutoreleasePool alloc] init]; 
    [self loadMissingModelsIntoDatabase];
    [pool drain];
    });*/
 
  //  [self performSelectorOnMainThread:@selector(splashFade) withObject:nil waitUntilDone:YES];
    //[self splashFade];
  //  [self performSelectorInBackground:@selector(loadMissingModelsIntoDatabase) withObject:nil];
	//[self loadMissingModelsIntoDatabase];
 //  [rootViewController.glViewController hideScanningIndicator:nil];
    
    [self loadMissingModelsIntoDatabase];

    rootViewController.glViewController.openGLESRenderer.isSceneReady=YES;
    [rootViewController.glViewController startOrStopAutorotation:YES];

   // [rootViewController.glViewController.modelToDisplay hideStatusIndicator];

}

- (void)applicationDidEnterBackground:(UIApplication *)application
{
    [rootViewController.glViewController startOrStopAutorotation:NO];
    rootViewController.glViewController.openGLESRenderer.isSceneReady=NO;
    [rootViewController.glViewController.openGLESRenderer waitForLastFrameToFinishRendering];
	[rootViewController cancelModelLoading];

    
   /* if ([[NSOperationQueue sharedOperationQueue] operationCount]>0) { 
        UIApplication*  app = [UIApplication sharedApplication]; 
        bgTask = [app beginBackgroundTaskWithExpirationHandler:^{ 
            [app endBackgroundTask:bgTask]; 
            bgTask = UIBackgroundTaskInvalid; 
        }]; 
        
        // Start the long-running task and return immediately. 
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 
                                                 0), ^{ 

            [[NSOperationQueue sharedOperationQueue] waitUntilAllOperationsAreFinished]; 
            [app endBackgroundTask:bgTask]; 
            bgTask = UIBackgroundTaskInvalid;

        }); 
    }       */  
    
//	[self disconnectFromDatabase];
}

/*
#pragma mark -
#pragma mark Custom model download methods

- (BOOL)handleCustomURLScheme:(NSURL *)url;
{
	if (url != nil)
	{
		isHandlingCustomURLModelDownload = YES;
		[NSThread sleepForTimeInterval:0.5]; // Wait for database to load
		
		NSString *pathComponentForCustomURL = [[url host] stringByAppendingString:[url path]];
		NSString *locationOfRemotePDBFile = [NSString stringWithFormat:@"http://%@", pathComponentForCustomURL];
		nameOfDownloadedModel = [[pathComponentForCustomURL lastPathComponent] retain];
		
		// Check to make sure that the file has not already been downloaded, if so, just switch to it
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];	
		
		[initialDatabaseLoadLock lock];

		if ([[NSFileManager defaultManager] fileExistsAtPath:[documentsDirectory stringByAppendingPathComponent:nameOfDownloadedModel]])
		{
			
			NSInteger indexForModelMatchingThisName = 0, currentIndex = 0;
			for (BenthosModel *currentModel in models)
			{
				if ([[currentModel filename] isEqualToString:nameOfDownloadedModel])
				{
					indexForModelMatchingThisName = currentIndex;
					break;
				}
				currentIndex++;
			}
			
			if (rootViewController.tableViewController == nil)
			{
				[rootViewController selectedModelDidChange:indexForModelMatchingThisName];
			}
			else
			{
				if ([BenthosAppDelegate isRunningOniPad])
				{
					[rootViewController.tableViewController tableView:rootViewController.tableViewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:indexForModelMatchingThisName inSection:0]];
				}
				else
				{
					[rootViewController.tableViewController tableView:rootViewController.tableViewController.tableView didSelectRowAtIndexPath:[NSIndexPath indexPathForRow:(indexForModelMatchingThisName + 1) inSection:0]];
				}					
			}
			[rootViewController loadInitialModel];
			
			[nameOfDownloadedModel release];
			nameOfDownloadedModel = nil;
			[initialDatabaseLoadLock unlock];
			return YES;
		}
		[initialDatabaseLoadLock unlock];

		
		[rootViewController cancelModelLoading];
		
		[NSThread sleepForTimeInterval:0.1]; // Wait for cancel action to take place
		
		// Determine if this is a file being passed in, or something to download
		if ([url isFileURL])
		{

			[nameOfDownloadedModel release];
			nameOfDownloadedModel = nil;
		}
		else
		{
			downloadCancelled = NO;
			
			// Start download of new model
			[self showDownloadIndicator];
			
			
			[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:YES];
			NSURLRequest *theRequest=[NSURLRequest requestWithURL:[NSURL URLWithString:locationOfRemotePDBFile]
													  cachePolicy:NSURLRequestUseProtocolCachePolicy
												  timeoutInterval:60.0f];
			downloadConnection = [[NSURLConnection alloc] initWithRequest:theRequest delegate:self];
			if (downloadConnection) 
			{
				downloadedFileContents = [[NSMutableData data] retain];
			} 
			else 
			{
				// inform the user that the download could not be made
				return NO;
			}
		}
	}	
	return YES;
}*/

- (void)downloadCompleted;
{
	[downloadConnection release];
	downloadConnection = nil;
	
	[[UIApplication sharedApplication] setNetworkActivityIndicatorVisible:NO];

	[downloadedFileContents release];
	downloadedFileContents = nil;
	[self hideStatusIndicator];
	[nameOfDownloadedModel release];
	nameOfDownloadedModel = nil;
}
/*
- (void)saveModelWithData:(NSData *)modelData toFilename:(NSString *)filename;
{
	[initialDatabaseLoadLock lock];

	if (modelData != nil)
	{
		// Add the new protein to the list by gunzipping the data and pulling out the title
		NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
		NSString *documentsDirectory = [paths objectAtIndex:0];
		
		NSError *error = nil;
		BOOL writeStatus;
		if (isGzipCompressionUsedOnDownload)
		{
			writeStatus = [modelData writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] options:NSAtomicWrite error:&error];
//			writeStatus = [[modelData gzipDeflate] writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] options:NSAtomicWrite error:&error];			
//			NSLog(@"Decompressing");
		}
		else
			writeStatus = [modelData writeToFile:[documentsDirectory stringByAppendingPathComponent:filename] options:NSAtomicWrite error:&error];

		if (!writeStatus)
		{
			// TODO: Do some error handling here
			return;
		}
		
		BenthosModel *newModel = [[BenthosModel alloc] initWithFilename:filename database:database title:filename];
		if (newModel == nil)
		{
			UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Error in downloaded file", @"Localized", nil) message:NSLocalizedStringFromTable(@"The model file is either corrupted or not of a supported format", @"Localized", nil)
														   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles:nil, nil];
			[alert show];
			[alert release];
			
			// Delete the corrupted or sunsupported file
			NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
			NSString *documentsDirectory = [paths objectAtIndex:0];
			
			NSError *error = nil;
			if (![[NSFileManager defaultManager] removeItemAtPath:[documentsDirectory stringByAppendingPathComponent:filename] error:&error])
			{
				UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not delete file", @"Localized", nil) message:[error localizedDescription]
															   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles:nil, nil];
				[alert show];
				[alert release];					
				return;
			}
			
		}
		else
		{			
			[models addObject:newModel];
			[newModel release];
			
			[rootViewController updateListOfModels];
			[rootViewController selectedModelDidChange:([models count] - 1)];
			[rootViewController loadInitialModel];

		}			
	}	
	[initialDatabaseLoadLock unlock];

}

#pragma mark -
#pragma mark URL connection delegate methods

- (void)connection:(NSURLConnection *)connection didFailWithError:(NSError *)error;
{
	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Connection failed", @"Localized", nil) message:NSLocalizedStringFromTable(@"Could not connect to the Protein Data Bank", @"Localized", nil)
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
		return;
	}
	[downloadedFileContents appendData:data];
}

- (void)connection:(NSURLConnection *)connection didReceiveResponse:(NSURLResponse *)response;
{
//	downloadFileSize = [response expectedContentLength];
	NSString * contentEncoding = [[(NSHTTPURLResponse *)response allHeaderFields] valueForKey:@"Content-Encoding"];
//	NSDictionary *allHeaders = [(NSHTTPURLResponse *)response allHeaderFields];
	isGzipCompressionUsedOnDownload = [[contentEncoding lowercaseString] isEqualToString:@"gzip"];

//	for (id key in allHeaders) 
//	{
//		NSLog(@"key: %@, value: %@", key, [allHeaders objectForKey:key]);
//	}
//	
//	if (isGzipCompressionUsedOnDownload)
//		NSLog(@"gzipping");
	
	// Stop the spinning wheel and start the status bar for download
	if ([response textEncodingName] != nil)
	{
		UIAlertView *alert = [[UIAlertView alloc] initWithTitle:NSLocalizedStringFromTable(@"Could not find file", @"Localized", nil) message:[NSString stringWithFormat:NSLocalizedStringFromTable(@"No such file exists on the server: %@", @"Localized", nil), nameOfDownloadedModel]
													   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil, nil];
		[alert show];
		[alert release];		
		[connection cancel];
		[self downloadCompleted];
		return;
	}
}*/
/*
- (void)connectionDidFinishLoading:(NSURLConnection *)connection;
{	
	
//	UIAlertView *alert = [[UIAlertView alloc] initWithTitle:@"Download completed" message:@"Download completed"
//												   delegate:self cancelButtonTitle:NSLocalizedStringFromTable(@"OK", @"Localized", nil) otherButtonTitles: nil];
//	[alert show];
//	[alert release];
	
	// Close off the file and write it to disk
	[self saveModelWithData:downloadedFileContents toFilename:nameOfDownloadedModel];
	
	[self downloadCompleted];	
}*/
+ (BOOL) processArchive:(NSString*)filename error:(NSError**)error {
    //NSLog(@"Processing Archive %@\n",filename);
    // Add the new protein to the list by gunzipping the data and pulling out the title
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSArray* libraryPaths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);

    NSString *libraryDirectory = [libraryPaths objectAtIndex:0];

    NSString *documentsDirectory = [paths objectAtIndex:0];
    
    NSFileManager *fileManager = [NSFileManager defaultManager];
    // Iterate through all files sitting in the application's Resources directory
    // TODO: Can you fast enumerate this?
    
    if ([[filename pathExtension] isEqualToString:@"tar"])
    {
        NSString *archivePath = [documentsDirectory stringByAppendingPathComponent:filename ];
        
        NSString *installedTexPath = [libraryDirectory stringByAppendingPathComponent:[filename stringByDeletingPathExtension]];
        if (![fileManager fileExistsAtPath:installedTexPath])
        {
            [[NSFileManager defaultManager] createFilesAndDirectoriesAtPath:libraryDirectory withTarPath:archivePath error:error];
            
            NSURL *installedURL = [NSURL fileURLWithPath:installedTexPath];
            [BenthosAppDelegate addSkipBackupAttributeToItemAtURL:installedURL];
            //Sucess delete tar
            //   NSLog(@"Deleting %@\n",archivePath);                
            if (![[NSFileManager defaultManager] removeItemAtPath:archivePath error:error])
            {
                
                return NO;
            }

            if (*error != nil)
            {
                NSLog(@"Failed to untar preinstalled files  with error: '%@'.", [*error localizedDescription]);
                // TODO: Report the file copying problem to the user or do something about it
                return NO;
            }
            //}
        }else{
            NSMutableDictionary* details = [NSMutableDictionary dictionary];
            [details setValue:@"ERROR Folder already exists \n" forKey:NSLocalizedDescriptionKey];
            // populate the error object with the details
            if (error != nil) 
                *error = [[[NSError alloc ] initWithDomain:@"benthos" code:kErrFolderExists userInfo:details] autorelease];
            [[NSFileManager defaultManager] removeItemAtPath:installedTexPath error:error];
           
            return NO;
        }
        
    }else{
        NSMutableDictionary* details = [NSMutableDictionary dictionary];
        [details setValue:@"Not Tar File\n" forKey:NSLocalizedDescriptionKey];
        // populate the error object with the details
        if(error != nil)
            *error = [[[NSError alloc ] initWithDomain:@"benthos" code:kErrTarCorrupt userInfo:details] autorelease];
        return NO;
    }
    
    return YES;
}
+(BOOL) removeModelFolder:(NSString*)basename
{
    
    if([basename length] == 0){
        NSLog(@"Attempting to remove Empty model\n");
        return NO;
    }
    // Remove the file from disk
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSLibraryDirectory, NSUserDomainMask, YES);
    NSString *libraryDirectory = [paths objectAtIndex:0];
    CFUUIDRef newUniqueId = CFUUIDCreate(kCFAllocatorDefault);
    CFStringRef newUniqueIdString = CFUUIDCreateString(kCFAllocatorDefault, newUniqueId);
    NSString *tmpPath = [NSTemporaryDirectory() stringByAppendingPathComponent:( NSString *)newUniqueIdString];
    CFRelease(newUniqueId);
    CFRelease(newUniqueIdString);
    NSError *error = nil;
   // NSLog(@"Removing %@\n",basename);
    BOOL ret=[[NSFileManager defaultManager] moveItemAtPath:[libraryDirectory stringByAppendingPathComponent:basename ]  toPath:tmpPath error:&error];
    if(ret){
        dispatch_async(dispatch_get_global_queue(DISPATCH_QUEUE_PRIORITY_DEFAULT, 0), ^(void) {
            NSError *error2 = nil;
            
            NSFileManager *fileManager = [[[NSFileManager alloc] init] autorelease];
            if(![fileManager removeItemAtPath:tmpPath error:&error2])
            {
                NSLog(@"Failed to remove item: %@\n",[error2 localizedDescription]);		
            }
        });
    }else{
        NSLog(@"Failed to move item: %@\n",[error localizedDescription]);		

    }
    return ret;
    
}

+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL
{
    if(![[NSFileManager defaultManager] fileExistsAtPath: [URL path]]){
        NSLog(@"No file exists at %@\n",[URL path] );
        return NO;
    }
    const char* filePath = [[URL path] fileSystemRepresentation];
    
    const char* attrName = "com.apple.MobileBackup";
    u_int8_t attrValue = 1;
    
    int result = setxattr(filePath, attrName, &attrValue, sizeof(attrValue), 0, 0);
    return result == 0;
}

@end
