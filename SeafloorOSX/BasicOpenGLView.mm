#import "Core3D.h"
#import "BasicOpenGLView.h"
#include "Simulation.h"
#include "Scene.h"
#import "NSArray+CHCSVAdditions.h"
// For functions like gluErrorString()
#import <OpenGL/glu.h>
#ifdef __APPLE__
#define _MACOSX
#endif
#define FORMAT(format, ...) [NSString stringWithFormat:(format), ##__VA_ARGS__]

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
    //damage = true;
    return false;
  }
-(IBAction) revertDocumentToSaved: (id) sender{
    [self runUDPServerToLog];
}

-(void) runUDPServerToLog {
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
    NSError *error = nil;

    if (![udpSocket bindToPort:IPAD_PORT error:&error])
    {
        [self logError:FORMAT(@"Error starting server (bind): %@", error)];
        return;
    }
    if (![udpSocket beginReceiving:&error])
    {
        [udpSocket close];
        
        [self logError:FORMAT(@"Error starting server (recv): %@", error)];
        return;
    }
    
    [self logError:FORMAT(@"Udp Echo server started on port %hu", [udpSocket localPort])];

}
- (void)logError:(NSString *)msg
{
    NSLog(@"%@\n",msg);
}

- (void)udpSocket:(GCDAsyncUdpSocket *)sock didReceiveData:(NSData *)data
      fromAddress:(NSData *)address
withFilterContext:(id)filterContext
{
    
    NSKeyedUnarchiver *unarchiver = [[NSKeyedUnarchiver alloc] initForReadingWithData:data];
    NSDictionary *myDictionary = [[unarchiver decodeObjectForKey:@"STATE_PACKET"] retain];
    [unarchiver finishDecoding];
    [unarchiver release];

    [self logError:@"GotMsg"];

	/*NSString *msg = [[NSString alloc] initWithData:data encoding:NSUTF8StringEncoding];
	if (msg)
	{
		[self logMessage:msg];
	}
	else
	{
		[self logError:@"Error converting received data into UTF-8 String"];
	}
	
	[udpSocket sendData:data toAddress:address withTimeout:-1 tag:0];*/
    [myDictionary release];

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
        [arr addObject:[[[ReplayData alloc] initWith: centerX :centerY :centerZ :tilt :dist :heading :time] autorelease]];
       
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

	[scene update];
	[scene render];
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
    
	[[self window] zoom:self];
    udpSocket = [[GCDAsyncUdpSocket alloc] initWithDelegate:self delegateQueue:dispatch_get_main_queue()];
    
}

- (void)animationTimer:(NSTimer *)timer
{
	//[self drawRect:[self bounds]]; // redraw now instead dirty to enable updates during live resize
	[self setNeedsDisplay:YES];
}


  - (void) terminate:(NSNotification *)aNotification
  {
    // TODO: delete your app's object
    NSLog(@"Terminating");
  }
@end
