/*
     File: ParseOperation.m
 Abstract: The NSOperation class used to perform the XML parsing of Model data.
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

#import "ParseOperation.h"
#import "Model.h"

// NSNotification name for sending Model data back to the app delegate
NSString *kAddModelsNotif = @"AddModelsNotif";

// NSNotification userInfo key for obtaining the Model data
NSString *kModelResultsKey = @"ModelResultsKey";

// NSNotification name for reporting errors
NSString *kModelsErrorNotif = @"ModelErrorNotif";

// NSNotification userInfo key for obtaining the error message
NSString *kModelsMsgErrorKey = @"ModelsMsgErrorKey";


@interface ParseOperation () <NSXMLParserDelegate>
    @property (nonatomic, retain) Model *currentModelObject;
    @property (nonatomic, retain) NSMutableArray *currentParseBatch;
    @property (nonatomic, retain) NSMutableString *currentParsedCharacterData;
@end

@implementation ParseOperation

@synthesize ModelData, currentModelObject, currentParsedCharacterData, currentParseBatch;

- (id)initWithData:(NSMutableData *)parseData
{
    if (self = [super init]) {    
        ModelData = [parseData copy];
        
        dateFormatter = [[NSDateFormatter alloc] init];
        [dateFormatter setTimeZone:[NSTimeZone timeZoneForSecondsFromGMT:0]];
        [dateFormatter setLocale:[[[NSLocale alloc] initWithLocaleIdentifier:@"en_US_POSIX"] autorelease]];
        [dateFormatter setDateFormat:@"yyyy'-'MM'-'dd'T'HH':'mm':'ss'Z'"];
    }
    return self;
}

- (void)addModelsToList:(NSArray *)Models {
    assert([NSThread isMainThread]);
    
    [[NSNotificationCenter defaultCenter] postNotificationName:kAddModelsNotif
                                                        object:self
                                                      userInfo:[NSDictionary dictionaryWithObject:Models
                                                                                           forKey:kModelResultsKey]]; 
}
     
// the main function for this NSOperation, to start the parsing
- (void)main {
    self.currentParseBatch = [NSMutableArray array];
    self.currentParsedCharacterData = [NSMutableString string];
    
    // It's also possible to have NSXMLParser download the data, by passing it a URL, but this is
    // not desirable because it gives less control over the network, particularly in responding to
    // connection errors.
    //
    NSXMLParser *parser = [[NSXMLParser alloc] initWithData:self.ModelData];
    [parser setDelegate:self];
    [parser parse];
    
    // depending on the total number of Models parsed, the last batch might not have been a
    // "full" batch, and thus not been part of the regular batch transfer. So, we check the count of
    // the array and, if necessary, send it to the main thread.
    //
    if ([self.currentParseBatch count] > 0) {
        [self performSelectorOnMainThread:@selector(addModelsToList:)
                               withObject:self.currentParseBatch
                            waitUntilDone:NO];
    }
    
    self.currentParseBatch = nil;
    self.currentModelObject = nil;
    self.currentParsedCharacterData = nil;
    
    [parser release];
}

- (void)dealloc {
    [ModelData release];
    
    [currentModelObject release];
    [currentParsedCharacterData release];
    [currentParseBatch release];
    [dateFormatter release];
    
    [super dealloc];
}


#pragma mark -
#pragma mark Parser constants

// Limit the number of parsed Models to 50
// (a given day may have more than 50 Models around the world, so we only take the first 50)
//
static const const NSUInteger kMaximumNumberOfModelsToParse = 50;

// When an Model object has been fully constructed, it must be passed to the main thread and
// the table view in RootViewController must be reloaded to display it. It is not efficient to do
// this for every Model object - the overhead in communicating between the threads and reloading
// the table exceed the benefit to the user. Instead, we pass the objects in batches, sized by the
// constant below. In your application, the optimal batch size will vary 
// depending on the amount of data in the object and other factors, as appropriate.
//
static NSUInteger const kSizeOfModelBatch = 10;

// Reduce potential parsing errors by using string constants declared in a single place.
static NSString * const kItemElementName = @"item";
static NSString * const kLinkElementName = @"link";
static NSString * const kFilenameElementName = @"filename";
static NSString * const kFolderElementName = @"folder";
static NSString * const kTitleElementName = @"title";
static NSString * const kDescElementName = @"description";
static NSString * const kUpdatedElementName = @"updated";
static NSString * const kGeoRSSPointElementName = @"georss:point";


#pragma mark -
#pragma mark NSXMLParser delegate methods

- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName
                                        namespaceURI:(NSString *)namespaceURI
                                       qualifiedName:(NSString *)qName
                                          attributes:(NSDictionary *)attributeDict {
    // If the number of parsed Models is greater than
    // kMaximumNumberOfModelsToParse, abort the parse.
    //
    if (parsedModelsCounter >= kMaximumNumberOfModelsToParse) {
        // Use the flag didAbortParsing to distinguish between this deliberate stop
        // and other parser errors.
        //
        didAbortParsing = YES;
        [parser abortParsing];
    }
    if ([elementName isEqualToString:kItemElementName]) {
        Model *model = [[Model alloc] init];
        self.currentModelObject = model;
        [model release];
    } else if ([elementName isEqualToString:kLinkElementName]) {
        NSString *relAttribute = [attributeDict valueForKey:@"rel"];
        if ([relAttribute isEqualToString:@"alternate"]) {
            NSString *weblink = [attributeDict valueForKey:@"href"];
            self.currentModelObject.weblink = [NSURL URLWithString:weblink];
        }
    } else if ([elementName isEqualToString:kTitleElementName] ||
               [elementName isEqualToString:kUpdatedElementName] ||
               [elementName isEqualToString:kGeoRSSPointElementName]||
               [elementName isEqualToString:kDescElementName]||
               [elementName isEqualToString:kFolderElementName] ||
               [elementName isEqualToString:kFilenameElementName]) {
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
        [self.currentParseBatch addObject:self.currentModelObject];
        parsedModelsCounter++;
        if ([self.currentParseBatch count] >= kMaximumNumberOfModelsToParse) {
            [self performSelectorOnMainThread:@selector(addModelsToList:)
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
            self.currentModelObject.title = [title retain];
        }
    }  else if ([elementName isEqualToString:kDescElementName]) {
        // The title element contains the magnitude and location in the following format:
        // <title>M 3.6, Virgin Islands region<title/>
        // Extract the magnitude and the location using a scanner:
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        // Scan past the "M " before the magnitude.
        NSString *desc = nil;
        // Scan the remainer of the string.
        if ([scanner scanUpToCharactersFromSet:[NSCharacterSet illegalCharacterSet] intoString:&desc]) {
            self.currentModelObject.desc = [desc retain];
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
            self.currentModelObject.folder = [folder retain];
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
            self.currentModelObject.filename = [filename retain];
        }
    }else if ([elementName isEqualToString:kUpdatedElementName]) {
        if (self.currentModelObject != nil) {
            self.currentModelObject.date =
            [dateFormatter dateFromString:self.currentParsedCharacterData];
        }
        else {
            // kUpdatedElementName can be found outside an entry element (i.e. in the XML header)
            // so don't process it here.
        }
    } else if ([elementName isEqualToString:kGeoRSSPointElementName]) {
        // The georss:point element contains the latitude and longitude of the Model epicenter.
        // 18.6477 -66.7452
        //
        NSScanner *scanner = [NSScanner scannerWithString:self.currentParsedCharacterData];
        double latitude, longitude;
        if ([scanner scanDouble:&latitude]) {
            if ([scanner scanDouble:&longitude]) {
                self.currentModelObject.latitude = latitude;
                self.currentModelObject.longitude = longitude;
            }
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

// an error occurred while parsing the Model data,
// post the error as an NSNotification to our app delegate.
// 
- (void)handleModelsError:(NSError *)parseError {
    [[NSNotificationCenter defaultCenter] postNotificationName:kModelsErrorNotif
                                                    object:self
                                                  userInfo:[NSDictionary dictionaryWithObject:parseError
                                                                                       forKey:kModelsMsgErrorKey]];
}

// an error occurred while parsing the Model data,
// pass the error to the main thread for handling.
// (note: don't report an error if we aborted the parse due to a max limit of Models)
//
- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    if ([parseError code] != NSXMLParserDelegateAbortedParseError && !didAbortParsing)
    {
        [self performSelectorOnMainThread:@selector(handleModelsError:)
                               withObject:parseError
                            waitUntilDone:NO];
    }
}

@end
