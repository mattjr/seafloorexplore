//
//  BenthosAppDelegate.h
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
//  Created by Brad Larson on 5/18/2008.
//
//  This is the base application delegate, used for handling launch, termination, and memory-related delegate methods

#import <UIKit/UIKit.h>
#import <sqlite3.h>
//#import "NSOperationQueue+SharedQueue.h"
#import "Flurry.h"
#define kMaxiumSupportedFileVersion 1.0
@class BenthosRootViewController;


@interface BenthosAppDelegate : NSObject <UIApplicationDelegate> 
{
	UIWindow *window;
	BenthosRootViewController *rootViewController;
	UIViewController *splitViewController;
	NSURLConnection *downloadConnection;
	NSMutableData *downloadedFileContents;
	NSString *nameOfDownloadedModel;
	BOOL downloadCancelled;
	NSLock *initialDatabaseLoadLock;
	BOOL isGzipCompressionUsedOnDownload, isHandlingCustomURLModelDownload;
//	UIBackgroundTaskIdentifier bgTask;
	// SQLite database of all models
	sqlite3 *database;
	NSMutableArray *models;
    NSMutableArray *decompressingfiles;
}

@property (nonatomic, retain) UIWindow *window;
@property (nonatomic, retain) BenthosRootViewController *rootViewController;

// Device-specific interface control
+ (BOOL)isRunningOniPad;

// Database access
- (NSString *)applicationSupportDirectory;
- (BOOL)createEditableCopyOfDatabaseIfNeeded; 
- (void)connectToDatabase;
- (void)disconnectFromDatabase;
- (void)loadAllModelsFromDatabase;
- (void)loadInitialModelsFromDisk;
- (void)loadMissingModelsIntoDatabase;

// Status update methods
- (void)showStatusIndicator;
- (void)showDownloadIndicator;
- (void)updateStatusIndicator;
- (void)hideStatusIndicator;

// Custom model download methods
//- (BOOL)handleCustomURLScheme:(NSURL *)url;
- (void)downloadCompleted;
//- (void)saveModelWithData:(NSData *)modelData toFilename:(NSString *)filename;
-(void)addNewModel:(NSString*)pname;
+ (BOOL) processArchive:(NSString*)filename error:(NSError**)error;
+(BOOL) removeModelFolder:(NSString*)basename;
+ (BOOL)addSkipBackupAttributeToItemAtURL:(NSURL *)URL;

void uncaughtExceptionHandler(NSException *exception);
#define kErrFolderExists 200
#define kErrTarCorrupt 201
#define kMapStartSize 1000000
@end

