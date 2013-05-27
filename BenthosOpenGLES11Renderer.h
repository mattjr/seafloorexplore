//
//  BenthosOpenGLES11Renderer.h
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
//  Created by Brad Larson on 4/12/2011.
//
//  This is the old renderer, split out into a separate class for OpenGL ES 1.1 devices

#import "BenthosOpenGLESRenderer.h"

@interface BenthosOpenGLES11Renderer : BenthosOpenGLESRenderer 
{
}

// Model 3-D geometry generation
- (void)addNormal:(GLfloat *)newNormal forAtomType:(BenthosAtomType)atomType;
- (void)addBondNormal:(GLfloat *)newNormal;

@end
