//
//  SLSMoleculeSearchViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/22/2008.
//
//  This handles the keyword searching functionality of the Protein Data Bank

#import <UIKit/UIKit.h>
#import "SLSMoleculeTableViewController.h"
#import "SLSMoleculeDownloadController.h"

@interface SLSMoleculeSearchViewController : UITableViewController
{
	UISearchBar *keywordSearchBar;
	NSMutableArray *downloadaleModelList;
	NSMutableData *downloadedFileContents;
	NSURLConnection *searchResultRetrievalConnection, *nextResultsRetrievalConnection;
	NSUInteger currentPageOfResults;
	BOOL searchCancelled, isDownloading, isRetrievingCompoundNames;
    NSInteger indexOfDownloadingMolecule;
    
    SLSSearchType currentSearchType;
    SLSMoleculeDownloadController *downloadController;
    NSMutableString *currentXMLElementString;
    NSXMLParser *searchResultsParser;
    NSString *urlbasepath;
    BOOL insideIUPACName, insideSynonym;
    NSMutableData *modelData;
    
    NSOperationQueue *parseQueue;

    
}
@property (nonatomic, retain) NSMutableData *modelData;    // the data returned from the NSURLConnection
@property (nonatomic, retain) NSOperationQueue *parseQueue;     // the queue that manages our NSOperation for parsing earthquake data


// Performing search
- (void)processSearchResultsAppendingNewData:(BOOL)appendData;
- (void)processHTMLResults;
- (void)addModels:(NSNotification *)notif ;
- (void)moleculeFailedDownloading:(NSNotification *)note;
- (void)addModelsToList:(NSArray *)models ;

@end
