//
//  BenthosOpenGLES20Renderer.h
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

#import "BenthosOpenGLESRenderer.h"

#define ENABLETEXTUREDISPLAYDEBUGGING 1

@class GLProgram;
@class Scene;
@class Simulation;
@class DownloadedModel;
@interface MyOpenGLES20Renderer : BenthosOpenGLESRenderer 
{
   
   
    CGSize currentViewportSize;
    Scene *scene;
    Simulation *sim ;
    GLuint ambientOcclusionTexture,offscreenFramebuffer,offscreenDepthBuffer;
    CVOpenGLESTextureCacheRef texCache;
    CVOpenGLESTextureRef renderTexture;

	NSString *defaultModelName;
    int drawn;
    BOOL removeOnceRender;
}
@property(assign,nonatomic)     Simulation *sim ;
@property(assign,nonatomic)     Scene *scene ;
@property(assign,atomic)      BOOL removeOnceRender;



// OpenGL drawing support
- (BOOL)createFramebuffer:(GLuint *)framebufferPointer size:(CGSize)bufferSize renderBuffer:(GLuint *)renderbufferPointer depthBuffer:(GLuint *)depthbufferPointer texture:(GLuint *)backingTexturePointer layer:(CAEAGLLayer *)layer;
- (void)switchToDisplayFramebuffer;
- (void)shutdownVT;
-(void)startupVT:(BenthosModel *)model;
- (void)showStatusIndicator;
- (void)hideStatusIndicator;
- (void)reshapeScenes;


@end

