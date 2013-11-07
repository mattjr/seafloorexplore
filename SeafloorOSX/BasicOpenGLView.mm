//  SeafloorExplore
//
//
//  Copyright (C) 2012 Matthew Johnson-Roberson
//
//  See COPYING for license details

#import "Core3D.h"
#import "BasicOpenGLView.h"
#include "Simulation.h"
#include "Scene.h"
#import "TrackerOverlay.h"
#import "NSArray+CHCSVAdditions.h"
// For functions like gluErrorString()
#import <OpenGL/glu.h>
#ifdef __APPLE__
#define _MACOSX
#endif
#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]
#define GAZE_PORT 4242
#define GAZE_IP @"192.168.1.212"
#include "LibVT_Internal.h"
extern vtData vt;

void reportError (char * strError)
{
  // Set up a fancy font/display for error messages
  NSMutableDictionary *attribs = [NSMutableDictionary dictionary];
  [attribs setObject: [NSFont fontWithName: @"Monaco" size: 9.0f] 
    forKey: NSFontAttributeName];
  [attribs setObject: [NSColor whiteColor] 
    forKey: NSForegroundColorAttributeName];
  // Build the error message string
  NSString * errString = [NSString stringWithFormat:@"Error: %s.", strError];
  // Display to log
  NSLog (@"%@\n", errString);
}

GLenum glReportError (void)
{
  // Get current OpenGL error flag
  GLenum err = glGetError();
  // If there's an error report it
  if (GL_NO_ERROR != err)
  {
    reportError ((char *) gluErrorString (err));
  }
  return err;
}

@implementation BasicOpenGLView

  -(IBAction) openDocument: (id) sender
  {
/*    NSOpenPanel *tvarNSOpenPanelObj  = [NSOpenPanel openPanel];
    // TODO: Add a item to this list corresponding to each file type extension
    // this app supports opening
    // Create an array of strings specifying valid extensions and HFS file types.
    NSArray *fileTypes = [NSArray arrayWithObjects:
      @"obj",
      @"OBJ",
      NSFileTypeForHFSTypeCode('TEXT'),
      nil];
    // Create an Open file... dialog
    NSInteger tvarNSInteger = [tvarNSOpenPanelObj runModalForTypes:fileTypes];
    // If the user selected OK then load the file
    if(tvarNSInteger == NSOKButton)
    {
      // Pass on file name to opener helper
      [self openDocumentFromFileName:[tvarNSOpenPanelObj filename]];
    }*/
      // Get the main window for the document.
      NSWindow* window = [self window];
      
      // Create and configure the panel.
      NSOpenPanel* panel = [NSOpenPanel openPanel];
      [panel setCanChooseDirectories:YES];
      [panel setCanChooseFiles:NO];

      [panel setAllowsMultipleSelection:NO];
      [panel setMessage:@"Open mesh directory."];
      
      // Display the panel attached to the document's window.
      [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
          if (result == NSFileHandlingPanelOKButton) {
                [self openDocumentFromFileName: [[panel URL] path] ];
              
              // Use the URLs to build a list of items to import.
          }
          
      }];
  }

  - (BOOL)openDocumentFromFileName:(NSString *) file_name
  {
    // convert cocoa string to c string
    const char * c_file_name = [file_name UTF8String];
    // TODO: handle loading a file from filename
    NSLog(@"Opening file: %s", c_file_name);
      //scene = [Scene sharedScene];
      scene = [[Scene alloc] init];
      
      
      //id sim = [[[NSClassFromString([[NSBundle mainBundle] objectForInfoDictionaryKey:@"SimulationClass"]) alloc] init] autorelease];
      id sim = [[[Simulation alloc] initWithString:file_name withScene:scene] autorelease];
      if (sim)
          [scene setSimulator:sim];
      else
          fatal("Error: there is no valid simulation class");
      
      [scene setSimulator:sim];
      [self reshape];
      if(logFile != NULL)
          fprintf(logFile,"OPEN %f %s\n",[[NSDate date] timeIntervalSince1970],[[file_name lastPathComponent] UTF8String]);
      [sim setupOverlay];

      
    //damage = true;
    return false;
  }
-(IBAction) revertDocumentToSaved: (id) sender{
    NSRect rect=[[self window] frame];

    CGFloat titleBarHeight = self.window.frame.size.height - ((NSView*)self.window.contentView).frame.size.height;
    CGSize windowSize = CGSizeMake(1024, 704 + titleBarHeight);
    rect.size=windowSize;

    [[self window ] setFrame:rect display:YES animate:YES];

    [self runUDPServerToLog];
}

- (NSString *)input: (NSString *)prompt defaultValue: (NSString *)defaultValue {
    NSAlert *alert = [NSAlert alertWithMessageText: prompt
                                     defaultButton:@"OK"
                                   alternateButton:@"Cancel"
                                       otherButton:nil
                         informativeTextWithFormat:@""];
    
    NSTextField *input = [[NSTextField alloc] initWithFrame:NSMakeRect(0, 0, 200, 24)];
    [input setStringValue:defaultValue];
    [input autorelease];
    [alert setAccessoryView:input];
    NSInteger button = [alert runModal];
    if (button == NSAlertDefaultReturn) {
        [input validateEditing];
        return [input stringValue];
    } else if (button == NSAlertAlternateReturn) {
        return nil;
    } else {
        NSAssert1(NO, @"Invalid input dialog button %ld",(long) button);
        return nil;
    }
}

-(void) runUDPServerToLog {
   
    networkQueue = dispatch_queue_create("com.acfr.netqueue", 0);
    if(udpSocketIpad != nil){
        NSLog(@"Closing udpSocketIpad\n");
       [udpSocketIpad close];
    }
    
    if(tcpSocketGaze != nil){
        NSLog(@"Closing udpSocketGaze\n");

       // [tcpSocketGaze close];
    }
    
    if(logFile != nil){
        NSLog(@"Closing file\n");
        fclose(logFile);
    }
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *documentsDirectory = [paths objectAtIndex:0]; // Get documents folder
    NSString *dataPath = [documentsDirectory stringByAppendingPathComponent:@"SeafloorExplore"];
    
    if (![[NSFileManager defaultManager] fileExistsAtPath:dataPath]){
        
        NSError* error;
        if(  [[NSFileManager defaultManager] createDirectoryAtPath:dataPath withIntermediateDirectories:NO attributes:nil error:&error])
            ;// success
        else
        {
            NSLog(@"[%@] ERROR: attempting to write create SeafloorExplore directory", [self class]);
            NSAssert( FALSE, @"Failed to create directory maybe out of disk space?");
        }
    }
    NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
    [dateFormatter setDateFormat:@"ddMMyyyy-HH-mm"];
    NSString *textDate = [NSString stringWithFormat:@"%@",[dateFormatter stringFromDate:[NSDate date]]];
    [dateFormatter release];
    NSArray *files = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:dataPath error:nil];
    

    NSString *value=[self input: @"Enter User Name" defaultValue:@""];
    static int sequenceNumber = 0;

    NSString *name;
    NSArray *matchedFiles = NULL;
    do {
        NSString *match = [NSString stringWithFormat:@"%@-%02d-*",value,sequenceNumber ];
        NSPredicate *predicate = [NSPredicate predicateWithFormat:@"SELF like %@", match];
        matchedFiles = [files filteredArrayUsingPredicate:predicate];
        

        name = [dataPath stringByAppendingPathComponent: [NSString stringWithFormat:@"%@-%02d-%@.txt",value,sequenceNumber,textDate]];
        sequenceNumber++;
    
    }while (matchedFiles && [matchedFiles count] > 0 );
    NSLog(@"Open %@\n",name);
    logFile = fopen([name UTF8String], "w");
    
    udpSocketIpad = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:networkQueue];
    tcpSocketGaze = [[GCDAsyncSocket alloc] initWithDelegate:self delegateQueue:networkQueue];

    NSError *error = nil;

    if (![udpSocketIpad bindToPort:IPAD_PORT error:&error])
    {
        [self logError:FORMAT(@"Error starting ipad server (bind): %@", error)];
        return;
    }
    if (![udpSocketIpad beginReceiving:&error])
    {
        [udpSocketIpad close];
        
        [self logError:FORMAT(@"Error starting ipad server (recv): %@", error)];
        return;
    }
    
    [self logError:FORMAT(@"Udp Ipad server started on port %hu", [udpSocketIpad localPort])];
    
    
    error = nil;
    
    if (![tcpSocketGaze connectToHost:GAZE_IP onPort:GAZE_PORT error:&error])
    {
        [self logError:FORMAT(@"Error connecting to gaze server: %@", error)];
        return;
    }
  
    
   /* if (![tcpSocketGaze beginReceiving:&error])
    {
        [tcpSocketGaze close];
        
        [self logError:FORMAT(@"Error starting server (recv): %@", error)];
        return;
    }*/
    
   // [self logError:FORMAT(@"Udp Echo server started on port %hu", [tcpSocketGaze localPort])];
    [tcpSocketGaze readDataToData:[GCDAsyncSocket CRLFData] withTimeout:30.0 tag:0];


}
- (void)logError:(NSString *)msg
{
    NSLog(@"%@\n",msg);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    double currentTime=[[NSDate date] timeIntervalSince1970];
    if([sock localPort] == IPAD_PORT){
        
        NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
        NSDictionary *stateDict = [[unarchiver decodeObjectForKey:@"STATE_PACKET"] retain];
        [unarchiver finishDecoding];
        [unarchiver release];
    
        [[scene simulator] unpackDict:stateDict];
       
        fprintf(logFile,"MOVE %f %s\n",currentTime,[[[stateDict description] stringByReplacingOccurrencesOfString:@"\n" withString:@" "]  UTF8String]);
        [stateDict release];
    }/*else if([sock localPort] == GAZE_PORT){
        NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
        if (msg)
        {
         //   NSLog(@"RCV: %@", msg);
             NSString* strType = @"STREAM_DATA";
             NSScanner *scanner = [NSScanner scannerWithString:msg];
            double x,y;
            long long timeStamp;
             if ( [ scanner scanString: strType intoString: NULL] )
             {
                 [scanner scanLongLong: &timeStamp];
                 [scanner scanDouble: &x];
                 [scanner scanDouble: &y];
            //     printf("%f %f %lld\n",x,y,timeStamp);
                 fprintf(logFile,"GAZE %f %f %f %lld\n",currentTime,x,y,timeStamp);
              //  printf("Delta %f %lld\n",_lastGaze-currentTime,_lastGazeTimeStamp-timeStamp);
                 _lastGazeTimeStamp=timeStamp;
                 _lastGaze=currentTime;
                 vector2f pos;
                 pos[0]=x;
                 pos[1]=768-y;
                 [[[scene simulator] toverlay] updatePos:pos];
             }else{
                 NSLog(@"Failed to parse\n");
             }

        }
        else
        {
            NSString *host = nil;
            uint16_t port = 0;
            [GCDAsyncUdpSocket getHost:&host port:&port fromAddress:address];
            NSLog(@"Unknown message from : %@:%hu", host, port);
        }
        [msg release];

    }*/

}


-(BOOL) loadGazeReplay: (NSString *)file_name{
    NSRect rect=[[self window] frame];

    CGFloat titleBarHeight = self.window.frame.size.height - ((NSView*)self.window.contentView).frame.size.height;
    CGSize windowSize = CGSizeMake(1024, 704 + titleBarHeight);
    rect.size=windowSize;
    
    [[self window ] setFrame:rect display:YES animate:YES];

   	char tmp[8192];
    char line[8192];

    FILE *fp = fopen([file_name UTF8String], "r");
    NSMutableArray *meshes=[[[NSMutableArray alloc] init] autorelease];
    while(!feof(fp)){
        fgets(line,8192,fp);
        sscanf(line,"%s",tmp);
        if(strncmp(tmp,"OPEN",8192) == 0 ){
            double timestamp;
            char fname[1024];

            sscanf(line+5,"%lf %s",&timestamp,fname);
            [meshes addObject:[NSString stringWithUTF8String:fname]];
        }
    }

    fclose(fp);
  
    NSString *targetModel = nil;
    // Create and configure the panel.
    NSAlert *alert = [NSAlert alertWithMessageText: @"Select Model"
                                     defaultButton:@"Replay"
                                   alternateButton:@"Cancel"
                                       otherButton:@"Dump"
                         informativeTextWithFormat:@""];

   // NSOpenPanel* panel = [NSOpenPanel openPanel];
   // [panel setCanChooseDirectories:NO];
    //[panel setAllowsMultipleSelection:NO];
    //[panel setMessage:@"Open csv replay."];
    NSPopUpButton *button = [[NSPopUpButton alloc] init];
    /*[button setButtonType:NSSwitchButton];
    button.title = NSLocalizedString(@"Dump to file", @"");*/
    [button addItemsWithTitles:meshes];
    [button sizeToFit];
    
    [alert setAccessoryView:button];
    // panel.delegate = self;
    
  
    NSInteger result = [alert runModal];
    targetModel= [button titleOfSelectedItem];
    [button release];
    if(result == NSAlertAlternateReturn )
        return NO;
    NSLog(@"%@",targetModel);
    fp = fopen([file_name UTF8String], "r");
    NSMutableArray *arr=nil;

    while(!feof(fp)){
        fscanf(fp,"%s",tmp);
        if(strncmp(tmp,"OPEN",8192) == 0 ){
            double timestamp;
            char fname[1024];
            fscanf(fp,"%lf %s",&timestamp,fname);
            if(arr){
                break;
            }
            [self openDocumentFromFileName: [NSString stringWithFormat:@"/Users/mattjr/Desktop/IJCV/%s",fname ]];
            if(strncmp([targetModel UTF8String], fname,1024) == 0){
                NSLog(@"Running %@\n",targetModel);
                arr=[[[NSMutableArray alloc] init] autorelease];
            }
            
        }else if(strncmp(tmp,"GAZE",8192) == 0 ){
            double timestamp,x,y;
            long long time;
            fscanf(fp,"%lf %lf %lf %lld\n",&timestamp,&x,&y,&time);
            MovementType movement=kNoLog;
            if(arr)
                [arr addObject:[[[ReplayData alloc] initWith: x :y :0 :0 :0 :0 :time :movement] autorelease]];
        }else if(strncmp(tmp,"MOVE",8192) == 0 ){
            double timestamp;
            fscanf(fp,"%lf ",&timestamp);
            char tmp2[8192];
            char mesh[1024];
            char movement[1024];
            fgets(tmp2,8192,fp);
            NSString *str = [[NSMutableString stringWithUTF8String:tmp2] stringByReplacingOccurrencesOfString:@"\"" withString:@""];

            double centerX,centerY,centerZ,tilt,dist,heading,time;

            sscanf([str UTF8String],"{     centerX = %lf;     centerY = %lf;     centerZ = %lf;     distance = %lf;     heading = %lf;     mesh = %s     movement = %s     tilt = %lf;     time = %lf; }",&centerX,&centerY,&centerZ,&dist,&heading,mesh,movement,&tilt ,&time);
            if(arr)
                [arr addObject:[[[ReplayData alloc] initWith: centerX :centerY :centerZ :tilt :dist :heading :time :kPanning] autorelease]];
           // printf("ME %f %s\n",centerX,mesh);

        }


     /*   double centerX,centerY,centerZ,tilt,dist,heading,time;
        NSMutableArray *arr=[[[NSMutableArray alloc] init] autorelease];
        char movement[8192],mesh_name[8192];
        for (id object in fields) {
            NSString * str=[object objectAtIndex:8];
            sscanf([str UTF8String], "{ centerZ : %lf;  time : %lf;  distance : %lf;  centerY : %lf;  centerX : %lf;  tilt : %lf;  movement : %s heading : %lf;  mesh : %s}", &centerZ,&time, &dist,&centerY,&centerX,&tilt,movement,&heading,mesh_name);*/
            
        
        //printf(" centerZ : %lf;  time : %lf;  distance : %lf;  centerY : %lf;  centerX : %lf;  tilt : %lf;  movement : %s;  heading : %lf;  mesh : %s\n}",centerZ,time, dist,centerY,centerX,tilt,movement,heading,mesh_name);
        
    }
    if(arr){
        if(result == NSAlertOtherReturn){
            NSString *dumpName=[NSString stringWithFormat:@"/Users/mattjr/Desktop/IJCV/%@-%@.dat",[[file_name lastPathComponent] stringByDeletingPathExtension], targetModel ];
        
            [[scene simulator] dumpVisInfo:arr intoFile:dumpName];
        
        }else if(result == NSAlertDefaultReturn){
            [[scene simulator] loadReplay:arr];
        }
    }
    
    
    
    fclose(fp);

    return YES;
}


-(BOOL) loadCSVReplay: (NSString *)file_name shouldDump:(BOOL)dump{
/*
    NSString *csvString = [NSString stringWithContentsOfFile:file_name encoding:NSUTF8StringEncoding error:&error];
    
	if (!csvString)
	{
		printf("Couldn't read file at path %s\n. Error: %s",
               [file_name UTF8String],
               [[error localizedDescription] ? [error localizedDescription] : [error description] UTF8String]);
		exit(1);
	}*/
    NSStringEncoding encoding = 0;
	NSError * error = nil;
	NSArray * fields = [NSArray arrayWithContentsOfCSVFile:file_name usedEncoding:&encoding error:&error];
    double centerX,centerY,centerZ,tilt,dist,heading,time;
    NSMutableArray *arr=[[[NSMutableArray alloc] init] autorelease];
    char movement[8192],mesh_name[8192];
    for (id object in fields) {
        NSString * str=[object objectAtIndex:8];
        sscanf([str UTF8String], "{ centerZ : %lf;  time : %lf;  distance : %lf;  centerY : %lf;  centerX : %lf;  tilt : %lf;  movement : %s heading : %lf;  mesh : %s}", &centerZ,&time, &dist,&centerY,&centerX,&tilt,movement,&heading,mesh_name);
        [arr addObject:[[[ReplayData alloc] initWith: centerX :centerY :centerZ :tilt :dist :heading :time :kPanning] autorelease]];
       
        //printf(" centerZ : %lf;  time : %lf;  distance : %lf;  centerY : %lf;  centerX : %lf;  tilt : %lf;  movement : %s;  heading : %lf;  mesh : %s\n}",centerZ,time, dist,centerY,centerX,tilt,movement,heading,mesh_name);
    }
    if(dump){
        NSLog(@"Dumping to file\n");
        NSString *dumpName=[file_name stringByAppendingString:@".dat"];
        [[scene simulator] dumpVisInfo:arr intoFile:dumpName];
    }
    else
    	[[scene simulator] loadReplay:arr];

    
	//NSLog(@"read: %@", [[fields objectAtIndex:0] objectAtIndex:8]);
    
    /*NSArray *keys=[NSArray arrayWithObjects:
                   @"Date",
                   @"Code",
                   @"event",
                   @"blank",
                   @"type",
                   @"version",
                   @"model",
                   @"modellong",
                   @"data",
                   nil];*/

    
return YES;
}
-(IBAction) saveDocumentTo:(id) sender{
    
    NSWindow* window = [self window];
    
    // Create and configure the panel.
    NSOpenPanel* panel = [NSOpenPanel openPanel];
    [panel setCanChooseDirectories:NO];
    [panel setAllowsMultipleSelection:NO];
    [panel setMessage:@"Open gaze replay."];
  /*  NSButton *button = [[NSButton alloc] init];
    [button setButtonType:NSSwitchButton];
    button.title = NSLocalizedString(@"Dump to file", @"");
    [button sizeToFit];
    [panel setAccessoryView:button];*/
    // panel.delegate = self;
    
    // Display the panel attached to the document's window.
    [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
        if (result == NSFileHandlingPanelOKButton) {
           // BOOL checkboxOn = (((NSButton*)panel.accessoryView).state);
            
            [self loadGazeReplay: [[panel URL] path]];
            
            // Use the URLs to build a list of items to import.
        }
        
    }];
   // [button release];

    
    
}


  -(IBAction) saveDocumentAs: (id) sender
  {
   
      NSWindow* window = [self window];
      
      // Create and configure the panel.
      NSOpenPanel* panel = [NSOpenPanel openPanel];
      [panel setCanChooseDirectories:NO];      
      [panel setAllowsMultipleSelection:NO];
      [panel setMessage:@"Open csv replay."];
      NSButton *button = [[NSButton alloc] init];
      [button setButtonType:NSSwitchButton];
      button.title = NSLocalizedString(@"Dump to file", @"");
      [button sizeToFit];
      [panel setAccessoryView:button];
     // panel.delegate = self;
      
      // Display the panel attached to the document's window.
      [panel beginSheetModalForWindow:window completionHandler:^(NSInteger result){
          if (result == NSFileHandlingPanelOKButton) {
              BOOL checkboxOn = (((NSButton*)panel.accessoryView).state);

              [self loadCSVReplay: [[panel URL] path] shouldDump:checkboxOn ];
              
              // Use the URLs to build a list of items to import.
          }
          
      }];
      [button release];

   /* NSSavePanel *savePanel = [NSSavePanel savePanel];
    [savePanel setTitle:@"Save as (.obj by default)"];
    // TODO: Add a item to this list corresponding to each file type extension
    // this app supports opening
    // Create an array of strings specifying valid extensions and HFS file types.
    NSArray *fileTypes = [NSArray arrayWithObjects:
      @"obj",
      @"OBJ",
      NSFileTypeForHFSTypeCode('TEXT'),
      nil];
    // Only allow these file types
    [savePanel setAllowedFileTypes:fileTypes]; 
    [savePanel setTreatsFilePackagesAsDirectories:NO]; 
    // Allow user to save file as he likes
    [savePanel setAllowsOtherFileTypes:YES];
    // Create save as... dialog
    NSInteger user_choice =  
      [savePanel runModalForDirectory:NSHomeDirectory() file:@""];
    // If user selected OK then save the file
    if(NSOKButton == user_choice)
    {
      // convert cocoa string to c string
      const char * file_name = [[savePanel filename] UTF8String];
      // TODO: handle saving default file
      NSLog(@"Saving file to %s", file_name);
    } */
  }

  -(void)keyDown:(NSEvent *)theEvent
  {
    // NOTE: holding a key on the keyboard starts to signal multiple down
    // events (the only one final up event)
    NSString *characters = [theEvent characters];
    if ([characters length])
    {
      // convert characters to single char
     // char character = [characters characterAtIndex:0];
      // TODO: Handle key down event
    	[pressedKeys addObject:[[NSNumber numberWithUnsignedInt:[[theEvent characters] characterAtIndex:0]] stringValue]];
//  NSLog(@"Keyboard down: %c\n",character);
    }
   // damage = true;
  }

  -(void)keyUp:(NSEvent *)theEvent
  {
    NSString *characters = [theEvent characters];
    if ([characters length])
    {
      // convert characters to single char
     // char character = [characters characterAtIndex:0];
      // TODO: Handle key up event
      //NSLog(@"Keyboard up: %c\n",character);
#ifdef WIN32
        [pressedKeys removeObject:[[NSNumber numberWithUnsignedInt:[[theEvent characters] characterAtIndex:0] + 32] stringValue]];
#else
        [pressedKeys removeObject:[[NSNumber numberWithUnsignedInt:[[theEvent characters] characterAtIndex:0]] stringValue]];
#endif

    }
    //damage = true;
  }

  - (void)mouseDown:(NSEvent *)theEvent
  {
    // Get location of the click
    NSPoint location = 
      [self flip_y:
        [self convertPoint:[theEvent locationInWindow] fromView:nil]];
    // TODO: Handle mouse up event
   // NSLog(@"Mouse down at (%g,%g)\n",location.x,location.y);
      if ([[scene simulator] respondsToSelector:@selector(pancont:)])		[[scene simulator] pancont:location];

  //  damage = true;
  }

  - (void)rightMouseDown:(NSEvent *)theEvent
  {
    // TODO: Handle right mouse button down event
    // For now just treat as left mouse button down event
    [self mouseDown: theEvent];
  }

  - (void)otherMouseDown:(NSEvent *)theEvent
  {
    // TODO: Handle other strange mouse button bown events
    // For now just treat as left mouse button down event
    [self mouseDown: theEvent];
  }

  - (void)mouseUp:(NSEvent *)theEvent
  {
    // Get location of the click
   // NSPoint location =
     // [self flip_y:
       //s [self convertPoint:[theEvent locationInWindow] fromView:nil]];
    // TODO: Handle mouse up event
   // NSLog(@"Mouse up at (%g,%g)\n",location.x,location.y);
    //damage = true;
  }

  - (void)rightMouseUp:(NSEvent *)theEvent
  {  
    // TODO: Handle right mouse button up event
    // For now just treat as left mouse button up event
    [self mouseUp: theEvent];
  }

  - (void)otherMouseUp:(NSEvent *)theEvent
  {
    // TODO: Handle other strange mouse button up events  
    // For now just treat as left mouse button up event
    [self mouseUp: theEvent];
  }

  - (void)mouseMoved:(NSEvent *)theEvent
  {
  /*  NSPoint location =
      [self flip_y:
        [self convertPoint:[theEvent locationInWindow] fromView:nil]];
    // TODO: Handle mouse move event
    NSLog(@"Mouse moved to (%g,%g)\n",location.x,location.y);
  //  damage = true;*/
  }

  - (void)mouseDragged:(NSEvent *)theEvent
  {
    
    NSPoint location = 
      [self flip_y:
        [self convertPoint:[theEvent locationInWindow] fromView:nil]];
    // TODO: Handle mouse drag event
  //  NSLog(@"Mouse dragged to (%g,%g)\n",location.x,location.y);
      if([theEvent modifierFlags] & NSControlKeyMask){
          CGPoint pt;
          pt.x=[theEvent deltaY];
          pt.y=[theEvent deltaX];
          [(Simulation *)[scene simulator] orient:pt];
      }
      else{
          [(Simulation *)[scene simulator] mouseDragged:location withFlags:(uint32_t)[theEvent modifierFlags]];
      }
   // damage = true;
  }

  - (void)rightMouseDragged:(NSEvent *)theEvent
  { 
    // TODO: Handle right mouse button drag event
    // For now just treat as left mouse button drag event
    [self mouseDragged: theEvent];
  }

  - (void)otherMouseDragged:(NSEvent *)theEvent
  {
    // TODO: Handle other strange mouse button drag event
    // For now just treat as left mouse button drag event
    [self mouseDragged: theEvent];
  }


  - (void)scrollWheel:(NSEvent *)theEvent
  {

  //  NSPoint location =
    //  [self flip_y:
      //  [self convertPoint:[theEvent locationInWindow] fromView:nil]];
    // TODO: Handle mouse scroll event
    //NSLog(@"Mouse scroll wheel at (%g,%g) by (%g,%g)\n",
      //location.x,location.y,[theEvent deltaX],[theEvent deltaY]);
      if ([[scene simulator] respondsToSelector:@selector(scrollWheel:)])		[(Simulation *)[scene simulator] scrollWheel:[theEvent deltaY]];

    //damage = true;
  }

  - (void) viewDidMoveToWindow
  {
    // Listen to all mouse move events (not just dragging)
    [[self window] setAcceptsMouseMovedEvents:YES];
    // When view changes to this window then be sure that we start responding
    // to mouse events
    [[self window] makeFirstResponder:self];
  }

  - (NSPoint) flip_y:(NSPoint) location
  {
    // Get openGL context size
    NSRect rectView = [self bounds];
    // Cocoa gives opposite of OpenGL y direction, flip y direction
    location.y = rectView.size.height - location.y;
    return location;
  }

/*  - (void) reshape
  {
    NSRect rectView = [self bounds];
    // TODO: Handle resize window using the following
    NSLog(@"New context size: %g %g\n",
      rectView.size.width,rectView.size.height);
  }*/
- (void)reshape
{
#ifndef WIN32
	[[self openGLContext] update];
#endif
	[scene reshape:[NSArray arrayWithObjects:[NSNumber numberWithInt:[self bounds].size.width], [NSNumber numberWithInt:[self bounds].size.height], nil]];
}

  /*- (void) drawRect:(NSRect)rect
  {
    // TODO: handle draw event
    // For now just clear the screen with a time dependent color
    glClearColor(
      fabs(sin([self getElapsedTime])),
      fabs(sin([self getElapsedTime]/3)),
      fabs(sin([self getElapsedTime]/7)),
      0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    // Elapsed time in seconds: getElapsedTime()
    // Report any OpenGL errors
    glReportError ();
    // Flush all OpenGL calls
    glFlush();
    // Flush OpenGL context
    [[self openGLContext] flushBuffer];
  }
*/
- (void)drawRect:(NSRect)rect
{
   /* glClearColor(
                 fabs(sin([self getElapsedTime])),
                 fabs(sin([self getElapsedTime]/3)),
                 fabs(sin([self getElapsedTime]/7)),
                 0);
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);*/
    glClear(GL_COLOR_BUFFER_BIT | GL_DEPTH_BUFFER_BIT);
    glClearColor(0.5,0.5,0.5,1.0);
	[scene update];
	[scene render];

    glBindTexture(GL_TEXTURE_2D, vt.physicalTexture);
    
    RenderTexture(256);

    glFlush();

	[[self openGLContext] flushBuffer];
}
  - (void) prepareOpenGL
  {
    const GLint swapInt = 1;
    // set to vbl sync
    [[self openGLContext] setValues:&swapInt 
      forParameter:NSOpenGLCPSwapInterval];
    if(!openGL_initialized)
    {
      // Get command line arguments and find whether stealFocus is set to YES
      NSUserDefaults *args = [NSUserDefaults standardUserDefaults];
      // also find out if app should steal focus
      bool stealFocus = [args boolForKey:@"stealFocus"];
      if(stealFocus)
      {
        // Steal focus means that the apps window will appear in front of all
        // other programs when it launches even in front of the calling
        // application (e.g. a terminal)
        [[NSApplication sharedApplication] activateIgnoringOtherApps:YES];
      }
      // TODO: Initialize OpenGL app, do anything here that you need to *after*
      // the OpenGL context is initialized (load textures, shaders, etc.)
      openGL_initialized = true;
    }
#ifndef WIN32
      const GLint swap = !globalSettings.disableVBLSync;
      CGLSetParameter(CGLGetCurrentContext(), kCGLCPSwapInterval, &swap);
#else
      typedef BOOL (WINAPI * PFNWGLSWAPINTERVALEXTPROC) (int interval);
      PFNWGLSWAPINTERVALEXTPROC wglSwapIntervalEXT = NULL;
      wglSwapIntervalEXT = (PFNWGLSWAPINTERVALEXTPROC) wglGetProcAddress("wglSwapIntervalEXT");
      wglSwapIntervalEXT(!globalSettings.disableVBLSync);
#endif
   [self reshape];
    NSLog(@"prepareOpenGL\n");
  }

  - (void) update 
  {
    [super update];  
  }

 /* - (void)animationTimer:(NSTimer *)timer
  { 
    // TODO: handle timer based redraw (animation) here
    bool your_app_says_to_redraw = true;
    if(your_app_says_to_redraw || damage)
    {
      damage = false;
      [self drawRect:[self bounds]];
    }
  }*/

  - (void) setStartTime
  {   
    start_time = CFAbsoluteTimeGetCurrent ();
  }

  - (CFAbsoluteTime) getElapsedTime
  {   
    return CFAbsoluteTimeGetCurrent () - start_time;
  }

  - (BOOL)acceptsFirstResponder
  {
    return YES;
  }

  - (BOOL)becomeFirstResponder
  {
    return  YES;
  }

  - (BOOL)resignFirstResponder
  {
    return YES;
  }

  /*- (void) awakeFromNib
  {
    openGL_initialized = false;
    // keep track of start/launch time
    [self setStartTime];
    // start animation timer
    timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self 
      selector:@selector(animationTimer:) userInfo:nil repeats:YES];
    [[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
    // ensure timer fires during resize
    [[NSRunLoop currentRunLoop] addTimer:timer 
      forMode:NSEventTrackingRunLoopMode]; 
  }*/
- (void)awakeFromNib
{
#ifndef WIN32
	ProcessSerialNumber psn;
	GetCurrentProcess(&psn);
	SetFrontProcess(&psn);
#endif
    
	timer = [NSTimer timerWithTimeInterval:(1.0f/60.0f) target:self selector:@selector(animationTimer:) userInfo:nil repeats:YES];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSDefaultRunLoopMode];
	[[NSRunLoop currentRunLoop] addTimer:timer forMode:NSEventTrackingRunLoopMode]; // ensure timer fires during resize
    
	pressedKeys = [[NSMutableArray alloc] initWithCapacity:5];
    NSRect rect = [self window].frame;
    NSSize size;
    size.width = 1024;
    size.height = 768;
    rect.size = size;
    [[self window] setFrame:rect display:YES];
	[[self window] zoom:self];
    udpSocketIpad = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void)animationTimer:(NSTimer *)timer
{
	//[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
	[self setNeedsDisplay:YES];
}


  - (void) terminate:(NSNotification *)aNotification
  {
    // TODO: delete your app's object
      [networkQueue release];
      if(udpSocketIpad != nil){
          NSLog(@"Closing udpSocketIpad\n");
          [udpSocketIpad close];
      }
      
      if(tcpSocketGaze != nil){
          NSLog(@"Closing udpSocketGaze\n");
          
         // [tcpSocketGaze close];
      }
      
      if(logFile != nil){
          NSLog(@"Closing file\n");
          fclose(logFile);
      }
    NSLog(@"Terminating");
  }

-(void)sendGazeCmd:(GCDAsyncSocket *)sock withCommand:(NSString *)requestStr
{
    NSMutableData *requestData = [NSMutableData dataWithData:[requestStr dataUsingEncoding:NSUTF8StringEncoding]];
    [requestData appendData:[GCDAsyncSocket CRLFData]];
    NSLog(@"Sending %@\n",requestStr);
    [sock writeData:requestData withTimeout:-1.0 tag:0];
}
- (void)socket:(GCDAsyncSocket *)sock didConnectToHost:(NSString *)host port:(UInt16)port
{
    NSLog(@"Socket:DidConnectToHost: %@ Port: %hu", host, port);
    [self sendGazeCmd: sock withCommand:@"<SET ID=\"ENABLE_SEND_POG_FIX\" STATE=\"1\" />"];
    [self sendGazeCmd: sock withCommand:@"<SET ID=\"ENABLE_SEND_POG_BEST\" STATE=\"1\" />"];
    [self sendGazeCmd: sock withCommand:@"<SET ID=\"ENABLE_SEND_EYE_LEFT\" STATE=\"1\" />"];
    [self sendGazeCmd: sock withCommand:@"<SET ID=\"ENABLE_SEND_EYE_RIGHT\" STATE=\"1\" />"];
    [self sendGazeCmd: sock withCommand:@"<SET ID=\"ENABLE_SEND_DATA\" STATE=\"1\" />"];


    
}


- (void)socket:(GCDAsyncSocket *)sock didReadData:(NSData *)data withTag:(long)tag
{
  //  NSLog(@"socket:didReadData:withTag:");
    double currentTime=[[NSDate date] timeIntervalSince1970];

    NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
    NSArray *arr = [msg componentsSeparatedByCharactersInSet: [NSCharacterSet newlineCharacterSet]];
   // NSLog(@"%@\n",arr);
    for (int i = 0; i < [arr count]-2; i++){
        
       // NSLog(@"Full httpResponse:\n%@", [arr objectAtIndex: i]);
        /* NSString* strType = @"<ACK";
         
         NSScanner *scanner = [NSScanner scannerWithString:msg];
         if ( [ scanner scanString: strType intoString: NULL] ){
         [msg release];
         return;
         }
         */
        if ([arr objectAtIndex: i])
        {
           // NSLog(@"RCV: %@", msg);
            [self parseXMLString:[arr objectAtIndex: i]];
            //NSLog(@"%@\n",gazeDict);
            
            // long long timeStamp;
            if (!errorParsing )
            {
                int fixValid=[[gazeDict objectForKey:@"FPOGV"] intValue];
                if(fixValid){
                    float gTime=[[gazeDict objectForKey:@"FPOGS"] floatValue];
                    float duration=[[gazeDict objectForKey:@"FPOGD"] floatValue];
                    float x=[[gazeDict objectForKey:@"FPOGX"] floatValue];
                    float y=[[gazeDict objectForKey:@"FPOGY"] floatValue];
                    int fixID=[[gazeDict objectForKey:@"FPOGID"] intValue];
                    
                    
                    x*=1024.0;
                    y*=768.0;
                    printf("%f %f %f\n",x,y,currentTime);
                    fprintf(logFile,"FIX %f %f %f %f %f %d\n",currentTime,x,y,gTime,duration,fixID);
                    //  printf("Delta %f %lld\n",_lastGaze-currentTime,_lastGazeTimeStamp-timeStamp);
                    //_lastGazeTimeStamp=timeStamp;
                    _lastGaze=currentTime;
                    vector2f pos;
                    pos[0]=x;
                    pos[1]=768-y;
                    [[[scene simulator] toverlay] updatePos:pos];
                }
                int pogValid=[[gazeDict objectForKey:@"BPOGV"] intValue];
                if(pogValid){
                    float x=[[gazeDict objectForKey:@"BPOGX"] floatValue];
                    float y=[[gazeDict objectForKey:@"BPOGY"] floatValue];
                    
                    
                    x*=1024.0;
                    y*=768.0;
                    //printf("%f %f %f\n",x,y,currentTime);
                    fprintf(logFile,"POG %f %f %f\n",currentTime,x,y);
                    //  printf("Delta %f %lld\n",_lastGaze-currentTime,_lastGazeTimeStamp-timeStamp);
                    //_lastGazeTimeStamp=timeStamp;
                    /*vector2f pos;
                     pos[0]=x;
                     pos[1]=768-y;
                     [[[scene simulator] toverlay] updatePos:pos];*/
                }
                int lePosV=[[gazeDict objectForKey:@"LPUPILV"] intValue];
                if(lePosV){
                    float x=[[gazeDict objectForKey:@"LEYEX"] floatValue];
                    float y=[[gazeDict objectForKey:@"LEYEY"] floatValue];
                    float z=[[gazeDict objectForKey:@"LEYEZ"] floatValue];
                    //printf("%f %f %f\n",x,y,currentTime);
                    fprintf(logFile,"LEYE %f %f %f %f\n",currentTime,x,y,z);
                }
                
                int riPosV=[[gazeDict objectForKey:@"RPUPILV"] intValue];
                if(riPosV){
                    float x=[[gazeDict objectForKey:@"REYEX"] floatValue];
                    float y=[[gazeDict objectForKey:@"REYEY"] floatValue];
                    float z=[[gazeDict objectForKey:@"REYEZ"] floatValue];
                    //printf("%f %f %f\n",x,y,currentTime);
                    fprintf(logFile,"REYE %f %f %f %f\n",currentTime,x,y,z);
                }
                
                
                
                
            }else{
                NSLog(@"Failed to parse\n");
            }
        }
    }
    [sock readDataWithTimeout:-1 tag:0];
    [msg release];

}

- (void)socketDidDisconnect:(GCDAsyncSocket *)sock withError:(NSError *)err
{
    // Since we requested HTTP/1.0, we expect the server to close the connection as soon as it has sent the response.
    
    NSLog(@"socketDidDisconnect:withError:%@", err);
}

- (void)parser:(NSXMLParser *)parser parseErrorOccurred:(NSError *)parseError {
    
    NSString *errorString = [NSString stringWithFormat:@"Error code %li", (long)[parseError code]];
    NSLog(@"Error parsing XML: %@", errorString);
    
    errorParsing=YES;

}
- (void)parser:(NSXMLParser *)parser didStartElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName attributes:(NSDictionary *)attributeDict{
//    NSLog(@"Started %@", elementName);
    if ([elementName isEqualToString:@"REC"]) {
       // NSLog(@"attrib %@", attributeDict);
        gazeDict = [attributeDict copy];
    }
}
- (void)parser:(NSXMLParser *)parser foundCharacters:(NSString *)string{
    //[ElementValue appendString:string];
   // NSLog(@"append %@", string);

}

- (void)parser:(NSXMLParser *)parser didEndElement:(NSString *)elementName namespaceURI:(NSString *)namespaceURI qualifiedName:(NSString *)qName{

    
}

- (void)parserDidEndDocument:(NSXMLParser *)parser {
    
    if (errorParsing == NO)
    {
       // NSLog(@"XML processing done!");
    } else {
        NSLog(@"Error occurred during XML processing");
    }
    
}

- (void)parseXMLString:(NSString *)str
{
    NSCharacterSet *set = [NSCharacterSet whitespaceCharacterSet];
    if ([[str stringByTrimmingCharactersInSet: set] length] == 0)
    {
        return;
    }
    
   // articles = [[NSMutableArray alloc] init];
    
    gazeDict = nil;
    errorParsing=NO;
    NSMutableData *requestData = [NSMutableData dataWithData:[str dataUsingEncoding:NSUTF8StringEncoding]];

    xmlParser = [[NSXMLParser alloc] initWithData:requestData];
    [xmlParser setDelegate:self];
    
    // You may need to turn some of these on depending on the type of XML file you are parsing
    [xmlParser setShouldProcessNamespaces:NO];
    [xmlParser setShouldReportNamespacePrefixes:NO];
    [xmlParser setShouldResolveExternalEntities:NO];
    
    [xmlParser parse];
    if(errorParsing)
        NSLog(@"Invalid XML: %@\n",str);
    
}


@end
