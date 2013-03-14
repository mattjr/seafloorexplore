/*
     File: FolderParseOperation.m
 Abstract: The NSOperation class used to perform the XML parsing of Folder data.
  Version: 2.3
 
 Disclaimer: IMPORTANT:  This Apple software is supplied to you by Apple
 Inc. ("Apple") in consideration of your agreement to the following
 terms, and your use, installation, modification or redistribution of
 this Apple software constitutes acceptance of these terms.  If you do
 not agree with these terms, please do not use, install, modify or
 redistribute this Apple software.
 
 In consideration of your agreement to abide by the following terms, and
 subject to these terms, Apple grants you a personal, non-exclusive
 license, under Apple's copyrights in this original Apple software (the
 "Apple Software"), to use, reproduce, modify and redistribute the Apple
 Software, with or without modifications, in source and/or binary forms;
 provided that if you redistribute the Apple Software in its entirety and
 without modifications, you must retain this notice and the following
 text and disclaimers in all such redistributions of the Apple Software.
 Neither the name, trademarks, service marks or logos of Apple Inc. may
 be used to endorse or promote products derived from the Apple Software
 without specific prior written permission from Apple.  Except as
 expressly stated in this notice, no other rights or licenses, express or
 implied, are granted by Apple herein, including but not limited to any
 patent rights that may be infringed by your derivative works or by other
 works in which the Apple Software may be incorporated.
 
 The Apple Software is provided by Apple on an "AS IS" basis.  APPLE
 MAKES NO WARRANTIES, EXPRESS OR IMPLIED, INCLUDING WITHOUT LIMITATION
 THE IMPLIED WARRANTIES OF NON-INFRINGEMENT, MERCHANTABILITY AND FITNESS
 FOR A PARTICULAR PURPOSE, REGARDING THE APPLE SOFTWARE OR ITS USE AND
 OPERATION ALONE OR IN COMBINATION WITH YOUR PRODUCTS.
 
 IN NO EVENT SHALL APPLE BE LIABLE FOR ANY SPECIAL, INDIRECT, INCIDENTAL
 OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
 SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
 INTERRUPTION) ARISING IN ANY WAY OUT OF THE USE, REPRODUCTION,
 MODIFICATION AND/OR DISTRIBUTION OF THE APPLE SOFTWARE, HOWEVER CAUSED
 AND WHETHER UNDER THEORY OF CONTRACT, TORT (INCLUDING NEGLIGENCE),
 STRICT LIABILITY OR OTHERWISE, EVEN IF APPLE HAS BEEN ADVISED OF THE
 POSSIBILITY OF SUCH DAMAGE.
 
 Copyright (C) 2010 Apple Inc. All Rights Reserved.
 
 */

#import "FolderParseOperation.h"
#import "Folder.h"

// NSNotification name for sending Folder data back to the app delegate
NSString *kAddFoldersNotif = @"AddFoldersNotif";

// NSNotification userInfo key for obtaining the Folder data
NSString *kFolderResultsKey = @"FolderResultsKey";

// NSNotification name for reporting errors
NSString *kFoldersErrorNotif = @"FolderErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kFoldersMsgErrorKey = @"FoldersMsgErrorKey";


@interface FolderParseOperation () <NSXMLParserDelegate>
    @property (nonatomic, retain) Folder *currentFolderObject;
    @property (nonatomic, retain) NSMutableArray *currentParseBatch;
    @property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@end

@implementation FolderParseOperation

@synthesize FolderData, currentFolderObject, currentParsedCharacterData, currentParseBatch;

- (id)initWithData:(NSMutableData *)parseData
{
    if (self = [super init]) {    
        FolderData = [parseData copy];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

- (void)addFoldersToList:(NSArray *)Folders {
    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddFoldersNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:Folders
                                                                                        forKey:kFolderResultsKey]]; 
}
     
// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.FolderData];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of Folders parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addFoldersToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
    }
    
    self.currentParseBatch = nil;
    self.currentFolderObject = nil;
    self.currentParsedCharacterData = nil;
    
    [parser release];
}


// the main function for this NSOperation, to start the parsing
- (void) staticparse:(NSMutableArray *) list {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.FolderData];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of Folders parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0 && list != nil) {
       [list addObjectsFromArray:self.currentParseBatch];
    }
    
    self.currentParseBatch = nil;
    self.currentFolderObject = nil;
    self.currentParsedCharacterData = nil;
    
    [parser release];
}


- (void)dealloc {
    [FolderData release];
    
    [currentFolderObject release];
    [currentParsedCharacterData release];
    [currentParseBatch release];
    [dateFormatter release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed Folders to 50
// (a given day may have more than 50 Folders around the world, so we only take the first 50)
//
static const NSUInteger kMaximumNumberOfFoldersToParse = 50;

// When an Folder object has been fully constructed, it must be passed to the main thread and
// the table view in RootViewController must be reloaded to display it. It is not efficient to do
// this for every Folder object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary 
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfFolderBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kLinkElementName = @"link";
static NSString * const kFilenameElementName = @"filename";
static NSString * const kFolderElementName = @"folder";
static NSString * const kTitleElementName = @"title";
static NSString * const kDescElementName = @"description";
static NSString * const kUpdatedElementName = @"updated";
static NSString * const kGeoRSSLatElementName = @"geo:lat";
static NSString * const kGeoRSSLonElementName = @"geo:long";
static NSString * const kSizeElementName = @"size";

#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
    // If the number of parsed Folders is greater than
    // kMaximumNumberOfFoldersToParse, abort the parse.
    //
    if (parsedFoldersCounter >= kMaximumNumberOfFoldersToParse) {
        // Use the flag didAbortParsing to distinguish between this deliberate stop
        // and other parser errors.
        //
        didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kItemElementName]) {
        Folder *folder = [[Folder alloc] init];
        self.currentFolderObject = folder;
        [folder release];
    } else if ([elementName isEqualToString:kTitleElementName] ||
               [elementName isEqualToString:kLinkElementName] ||
               [elementName isEqualToString:kUpdatedElementName] ||
               [elementName isEqualToString:kGeoRSSLatElementName]||
               [elementName isEqualToString:kGeoRSSLonElementName]||
               [elementName isEqualToString:kDescElementName]||
               [elementName isEqualToString:kFolderElementName] ||
               [elementName isEqualToString:kFilenameElementName]||
               [elementName isEqualToString:kSizeElementName]) {
        // For the 'title', 'updated', or 'georss:point' element begin accumulating parsed character data.
        // The contents are collected in parser:foundCharacters:.
        accumulatingParsedCharacterData = YES;
        // The mutable string needs to be reset to empty.
        [currentParsedCharacterData setString:@""];
    }
}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName
                                      namespaceURI:(NSString *)namespaceURI
                                     qualifiedName:(NSString *)qName {     
    if ([elementName isEqualToString:kItemElementName]) {
        [self.currentParseBatch addObject:self.currentFolderObject];
        parsedFoldersCounter++;
        if ([self.currentParseBatch count] >= kMaximumNumberOfFoldersToParse) {
            [self performSelectorOnMainThread:@selector(addFoldersToList:)
                                   withObject:self.currentParseBatch
                                waitUntilDone:NO];
            self.currentParseBatch = [NSMutableArray array];
        }
    } else if ([elementName isEqualToString:kTitleElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *title = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&title]) {
            self.currentFolderObject.title = [title retain];
        }
    }else if ([elementName isEqualToString:kLinkElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *weblink = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&weblink]) {
            self.currentFolderObject.weblink = [NSURL URLWithString:weblink] ;

        }   
    }else if ([elementName isEqualToString:kDescElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *desc = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&desc]) {
            self.currentFolderObject.desc = [desc retain];
        }
    }else if ([elementName isEqualToString:kFolderElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *folder = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&folder]) {
            self.currentFolderObject.folder = [folder retain];
        }
    }else if ([elementName isEqualToString:kFilenameElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *filename = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&filename]) {
            self.currentFolderObject.filename = [filename retain];
        }
    }else if ([elementName isEqualToString:kUpdatedElementName]) {
        if (self.currentFolderObject != nil) {
            self.currentFolderObject.date =
            [dateFormatter dateFromString:self.currentParsedCharacterData];
        }
        else {
            // kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
            // so don't process it here.
        }                 
    } else if ([elementName isEqualToString:kGeoRSSLatElementName]) {
             NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double latitude;
        if ([scanner scanDouble:&latitude]) {
                self.currentFolderObject.latitude = latitude;
            }
        
    } else if ([elementName isEqualToString:kSizeElementName]) {
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        long long int fileSize;
        if ([scanner scanLongLong:&fileSize]) {
            self.currentFolderObject.fileSize = fileSize;
        }
        
    }else if ([elementName isEqualToString:kGeoRSSLonElementName]) {
       NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
    double longitude;
    if ([scanner scanDouble:&longitude]) {
        self.currentFolderObject.longitude = longitude;
    }
    
    }
    // Stop accumulating parsed character data. We won't start again until specific elements begin.
    accumulatingParsedCharacterData = NO;
}

// This method is called by the parser when it find parsed character data ("PCDATA") in an element.
// The parser is not guaranteed to deliver all of the parsed character data for an element in a single
// invocation, so it is necessary to accumulate character data until the end of the element is reached.
//
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string {
    if (accumulatingParsedCharacterData) {
        // If the current element is one whose content we care about, append 'string'
        // to the property that holds the content of the current element.
        //
        [self.currentParsedCharacterData appendString:string];
    }
}

// an error occurred while parsing the Folder data,
// post the error as an NSNotification to our app delegate.
// 
- (void)handleFoldersError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kFoldersErrorNotif
                                                    object:self
                                                  userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                       forKey:kFoldersMsgErrorKey]];
}

// an error occurred while parsing the Folder data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of Folders)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleFoldersError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
