//
//  TrackerOverlay.h
//  originally written for the polyvision game GunocideIIExTurbo
//
//  Created by Alexander Bierbrauer on 23.10.08.
//  Copyright 2008 polyvision.org. All rights reserved.
//
// This software is released under a BSD license. See LICENSE.TXT
// You must accept the license before using this software.
//
// parts of this code is based on the works of legolas558 who wrote a TrackerOverlay loader called oglTrackerOverlay

// Parts Copyright A. Julian Mayer 2009. 

#import "Core3D.h"
#import "TrackerOverlay.h"
//#include <OpenGLES/ES1/gl.h>



@implementation TrackerOverlay

@synthesize scale, infoCommonLineHeight, color,pos;

- (id)init;
{
	if ((self = [super init]))
	{
		

		[self setScale:10.0f];
		[self setColor:vector4f(1.0, 1.0, 0.0, 1.0)];

		current = 0;
	}

	return self;
}
-(void)switchToOrtho
{
    glDisable(GL_DEPTH_TEST);
    glDisable(GL_LIGHTING); 
    glMatrixMode(GL_PROJECTION);
    glPushMatrix();
    glLoadIdentity();
    int width =1024;
    int height =768;
    glOrtho(0, width, 0, height, -5, 1);
    glMatrixMode(GL_MODELVIEW);
    glLoadIdentity();
}

-(void)switchBackToFrustum
{
    glEnable(GL_DEPTH_TEST);
    glEnable(GL_LIGHTING);
    glMatrixMode(GL_PROJECTION);
    glPopMatrix();
    glMatrixMode(GL_MODELVIEW);
}
- (void)render
{
    
	// we have some implicit preconditions here:	glEnable(GL_BLEND); glEnable(GL_TEXTURE_2D); glDisable(GL_LIGHTING); glDisable(GL_DEPTH_TEST);
//	glPushMatrix();
       
	//if (rotation)	glRotatef(rotation, 0, 0, 1);

	//myBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);

	myClientStateVTN(kNeedEnabled, kNeedEnabled, kNeedDisabled);

	myColor(color[0], color[1], color[2], color[3]);

    GLfloat bbox_pts[] = {
        pos3d[1][0],pos3d[1][1],pos3d[0][2], //0
        pos3d[0][0],pos3d[1][1],pos3d[0][2], //1
        pos3d[0][0],pos3d[0][1],pos3d[0][2], //2
        pos3d[1][0],pos3d[0][1],pos3d[0][2], //3
        
        pos3d[1][0],pos3d[0][1],pos3d[1][2], //4
        pos3d[1][0],pos3d[1][1],pos3d[1][2], //5
        pos3d[0][0],pos3d[1][1],pos3d[1][2], //6
        pos3d[0][0],pos3d[0][1],pos3d[1][2], //7
        
        pos3d[1][0],pos3d[1][1],pos3d[0][2], //0
        pos3d[1][0],pos3d[1][1],pos3d[1][2], //5
        pos3d[0][0],pos3d[1][1],pos3d[1][2], //6
        pos3d[0][0],pos3d[1][1],pos3d[0][2], //1
        
        pos3d[1][0],pos3d[0][1],pos3d[1][2], //4
        pos3d[0][0],pos3d[0][1],pos3d[1][2], //7
        pos3d[0][0],pos3d[0][1],pos3d[0][2], //2
        pos3d[1][0],pos3d[0][1],pos3d[0][2] //3
    };
    glDisable(GL_LIGHTING);

    glEnableClientState(GL_VERTEX_ARRAY);
    glTranslatef(0,0,0);
    glVertexPointer(3, GL_FLOAT, 0, bbox_pts);
    glDrawArrays(GL_LINE_LOOP, 0, 16);
    

    [self switchToOrtho ];

   /*GLfloat rect[] = {
        -0.5, -0.5,
        0.5, -0.5,
        0.5, 0.5,
        -0.5, 0.5
    };*/
    GLfloat rect[] = {
        -scale, -scale,
        scale, -scale,
        scale, scale,
        -scale, scale,
        -scale, -scale

    };


    glEnableClientState(GL_VERTEX_ARRAY);
    glTranslatef(pos[0],pos[1],0.0);

    glVertexPointer(2, GL_FLOAT, 0, rect);
    glDrawArrays(GL_LINE_STRIP, 0, 5);

    [self switchBackToFrustum ];

    current = 0;

	globalInfo.drawCalls++;
}

-(void)updatePos:(vector2f)setposition{
    self.pos= setposition;
    double currentTime=[[NSDate date] timeIntervalSince1970];
   // printf("Update Pos %f\n",_lastTime-currentTime);

    _lastTime=currentTime;

}

-(void)updatePos3d:(vector3f*)setposition{
    self->pos3d[0]= setposition[0];
    self->pos3d[1]= setposition[1];

    
}

- (void)dealloc
{

	[super dealloc];
}


@end
