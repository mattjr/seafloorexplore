//
//  BenthosOpenGLES11Renderer.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
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
