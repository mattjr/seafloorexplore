//
//  SLSMoleculeDownloadViewController.h
//  Molecules
//
//  The source code for Molecules is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 7/2/2008.
//
//  This controller manages the pop-up modal view for downloading new molecules from the Protein Data Bank

#import <UIKit/UIKit.h>

typedef enum { PUBCHEMSEARCH, PROTEINDATABANKSEARCH } SLSSearchType;

@interface SLSMoleculeDownloadController : NSObject
{
	NSString *codeForCurrentlyDownloadingMolecule, *titleForCurrentlyDownloadingMolecule;
	NSMutableData *downloadedFileContents;

	long long downloadFileSize;
	BOOL downloadCancelled;
	NSURLConnection *downloadConnection;
    SLSSearchType searchType;
    UIProgressView *progressView;
    UILabel *downloadStatusText;
    UIButton *cancelDownloadButton;
    UIActivityIndicatorView *spinningIndicator;
}
@property(nonatomic, retain)UIProgressView * progressView;
@property(nonatomic, retain)UILabel *downloadStatusText;
@property(nonatomic, retain)UIButton *cancelDownloadButton;
@property(nonatomic, retain)UIActivityIndicatorView *spinningIndicator;


// Initialization and teardown
- (id)initWithID:(NSString *)pdbCode title:(NSString *)title searchType:(SLSSearchType)newSearchType;
NSString* unitStringFromBytes(double bytes, uint8_t flags,int *exponent,int *width);
NSString* formatBytesNoUnit(double bytes, uint8_t flags,int exponent,int width);
- (void)downloadNewMolecule;
- (BOOL)downloadMolecule;
- (void)downloadCompleted;
-(void) sendDownloadFinishedMsg:(NSString*)filename;
- (void)cancelDownload;

@end