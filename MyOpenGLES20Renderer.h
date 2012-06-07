//
//  BenthosOpenGLES20Renderer.h
//  Models
//
//  The source code for Models is available under a BSD license.  See License.txt for details.
//
//  Created by Brad Larson on 4/12/2011.
//

#import "BenthosOpenGLESRenderer.h"

#define ENABLETEXTUREDISPLAYDEBUGGING 1

@class GLProgram;
@class Scene;
@class Simulation;
@class Model;
@interface MyOpenGLES20Renderer : BenthosOpenGLESRenderer 
{
   
   
    CGSize currentViewportSize;
    Scene *scene;
    Simulation *sim ;
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

