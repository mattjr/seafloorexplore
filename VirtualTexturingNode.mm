//
//  VirtualTexturingNode.m
//  SeafloorExplore
//
//  Modified from Julian Mayer LibVT Project in 2011-2012 for use in The SeafloorExplore Project
//
//  Copyright (C) 2012 Matthew Johnson-Roberson
//
//  See COPYING for license details
//  VTDemo
//
//  Created by Julian Mayer on 12.08.09.
/*	Copyright (c) 2010 A. Julian Mayer
 Permission is hereby granted, free of charge, to any person obtaining a copy of this software and associated documentation files (the "Software"), to deal in the Software without restriction, including without limitationthe rights to use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is furnished to do so, subject to the following conditions:
 The above copyright notice and this permission notice shall be included in all copies or substantial portions of the Software.
 THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
 */

#import "Simulation.h"
#import "LibVT_Internal.h"
#import "LibVT.h"
#import "LibVT_Config.h"
#import "Utilities.h"
//#import "Mesh.h"

extern vtData vt;
char buf[256];

#define NORMAL_TEXUNIT 5

#if !TARGET_OS_IPHONE && !defined(WIN32)
BMFont		*hudFont;
#endif
uint8_t		debugMode;
extern vtConfig c;

@implementation VirtualTexturingNode

- (id)init
{
	renderMode=0;
	[self doesNotRecognizeSelector:_cmd];
    vt.memValid=false;

	return nil;
}



- (id)initWithTileStore:(NSString *)path format:(NSString *)format border:(char)border miplength:(char)miplength tilesize:(int)tilesize
{
	if ((self = [super init]))
	{
#if !defined(WIN32) && !TARGET_OS_IPHONE
		hudFont = [[BMFont alloc] initWithFontNamed:@"fontVT" andTextureNamed:@"fontVT_00"];
		[hudFont setScale:0.2];
#endif
		if(c.tileDir != ""){
			vtShutdown();

			c.tileDir = "";
            c.pageDimension=0;
            
            c.tileDir="";
            c.pageCodec="";
            
            c.pageBorder=0; 
            c.mipChainLength=0;
            
            // derived values:
            c.pageMemsize=c.maxCachedPages=c.physTexDimensionPages=c.virtTexDimensionPages=c.residentPages=0;
            c.pageDataFormat=c.pageDataType=c.pageDXTCompression=0;
            long int sizeofzero= (long int)((long int)&(vt.fovInDegrees)-(long int)&(vt.mipTranslation));
            bzero(&vt,sizeofzero);
            vt.neededPages.clear();
            std::queue<uint32_t> empty;
            std::swap(             vt.newPages, empty );
            vt.cachedPages.clear();
            vt.cachedPagesAccessTimes.clear();
            

		}
        int max_texture_size=0;
        glGetIntegerv(GL_MAX_TEXTURE_SIZE, &max_texture_size);
        max_texture_size=min(max_texture_size,8192);
		if(!vtInit([path UTF8String], [format UTF8String], border, miplength, tilesize,max_texture_size))
            return nil;

		char *prelude = vtGetShaderPrelude();
		readbackShader = LoadShadersNoLink(@"readback", [NSString stringWithUTF8String:prelude]);


//#ifdef DEBUG
	//	renderVTShader = LoadShaders(@"renderVT", [[NSString stringWithUTF8String:prelude] stringByAppendingString:@"\n#define DEBUG=1\n\n"]);
//#else
		renderVTShader = LoadShadersNoLink(@"renderVT", [NSString stringWithUTF8String:prelude]);
//#endif
		passShader = LoadShadersNoLink(@"pass", [NSString stringWithUTF8String:prelude]);


		minMS = 10000;
		maxMS = 0;
		allMS = 0;
        
#if GL_ES_VERSION_2_0
		glBindAttribLocation(renderVTShader, TEXCOORD_ARRAY, "texcoord0");
		glBindAttribLocation(renderVTShader, VERTEX_ARRAY, "vertex");

		glBindAttribLocation(readbackShader, TEXCOORD_ARRAY, "texcoord0");
		glBindAttribLocation(readbackShader, VERTEX_ARRAY, "vertex");
		
        glBindAttribLocation(passShader, VERTEX_ARRAY, "vertex");
		glBindAttribLocation(passShader, NORMAL_ARRAY, "normal");

#endif
        LinkShader(renderVTShader);
        if(!validateProgram(renderVTShader))
            return nil;
        GLint mipcalcTextureLoc=glGetUniformLocation(renderVTShader, "mipcalcTexture");
        GLint normalTextureLoc=glGetUniformLocation(renderVTShader, "normalTexture");
		glUseProgram(renderVTShader);
		glUniform1i(mipcalcTextureLoc, TEXUNIT_FOR_MIPCALC);
		glUniform1i(normalTextureLoc, NORMAL_TEXUNIT);

        
        LinkShader(readbackShader);
        if(!validateProgram(readbackShader))
            return nil;

        LinkShader(passShader);
        if(!validateProgram(passShader))
            return nil;


		glUseProgram(0);



		free(prelude);

		vtPrepare(readbackShader, renderVTShader);

	//	vtPrepareOpenCL(0);
#if !TARGET_OS_IPHONE
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(applicationWillTerminate:)
													 name:NSApplicationWillTerminateNotification object:nil];
#endif



	}

	return self;
}



- (void)reshapeNode:(NSArray *)size
{
	vtReshape([[size objectAtIndex:0] intValue], [[size objectAtIndex:1] intValue], (float)[[scene camera] fov], [[scene camera] nearPlane], [[scene camera] farPlane]);
}


- (void)render
{
	if(renderMode ==SHADED){
		
		glUseProgram(passShader);
	//	zrange[0]=0.25;
	//	zrange[1]=1;	
       // printf("%f %f\n",zrange[0],zrange[1]);
		glUniform2f(glGetUniformLocation(passShader, "zrange"), zrange[0],zrange[1]);
        // Set the diffuse color.
       // vec3 color = visual->Color * 0.75f;
		//GLfloat  color[] ={0.25, 0.25,0.25};

        //glVertexAttrib4f(glGetUniformLocation(passShader, "DiffuseMaterial"), color[0], 
          //               color[1], color[2], 1);
		
		glUniformMatrix4fv(glGetUniformLocation(passShader, "matViewProjection"), 1, GL_FALSE, matrix44f_c([[scene camera] projectionMatrix] * [[scene camera] modelViewMatrix]).data());
		[children makeObjectsPerformSelector:@selector(render)];
		glUseProgram(0);

		return;
	}
	uint64_t readback = 0, extract = 0, upload = 0, all = 0, prep = 0;// render = 0;
	//printf("here\n");
	for (NSString *keyHit in pressedKeys)
	{
		switch ([keyHit intValue])
		{
#if !TARGET_OS_IPHONE
			case NSUpArrowFunctionKey:
				bias += 0.01;
				break;
			case NSDownArrowFunctionKey:
				bias -= 0.01;
				break;
#endif
#ifdef DEBUG
			case '0'...'9':
				debugMode = [keyHit intValue] - '0';

				if ((debugMode == 9) || (debugMode == 8))
				{
					glActiveTexture(GL_TEXTURE0 + NORMAL_TEXUNIT);
					glEnable(GL_TEXTURE_2D);

					static BOOL texloaded = FALSE;
					if (!texloaded)
					{
						((Mesh *)[children objectAtIndex:0])->texName = LoadTexture(@"/Users/julian/Desktop/texture_32k.png", GL_LINEAR_MIPMAP_LINEAR, GL_LINEAR, GL_TRUE, 0.0);
						texloaded = TRUE;
					}

					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, (debugMode == 9) ? GL_NEAREST : GL_LINEAR);
					glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, (debugMode == 9) ? GL_NEAREST_MIPMAP_NEAREST : GL_LINEAR_MIPMAP_LINEAR);
					glActiveTexture(GL_TEXTURE0);
				}
				break;
			case 'e'...'n':
				debugMode = [keyHit intValue] - 'e' + 10;
				break;
			case '+':
			case '-':
				[keyHit intValue] == '+' ? anis += 2 : anis -=2;
				if (anis > 16) anis = 16;
				if (anis < 2) anis = 2;
				glActiveTexture(GL_TEXTURE0 + TEXUNIT_FOR_PHYSTEX);
				//glActiveTexture(GL_TEXTURE0 + TEXUNIT_FOR_MIPCALC);
				//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, GL_LINEAR);
				//glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, GL_LINEAR_MIPMAP_LINEAR);
				glTexParameterf(GL_TEXTURE_2D, GL_TEXTURE_MAX_ANISOTROPY_EXT, anis);
				glActiveTexture(GL_TEXTURE0);
				break;
			case 'y'...'z':
				glActiveTexture(GL_TEXTURE0 + TEXUNIT_FOR_PHYSTEX);
				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MAG_FILTER, [keyHit intValue] == 'y' ? GL_NEAREST : GL_LINEAR);
				glActiveTexture(GL_TEXTURE0);
				break;
//			case 'g'...'l':
//				GLuint modes[] = {GL_NEAREST, GL_LINEAR, GL_NEAREST_MIPMAP_NEAREST, GL_LINEAR_MIPMAP_NEAREST, GL_NEAREST_MIPMAP_LINEAR, GL_LINEAR_MIPMAP_LINEAR};
//				glActiveTexture(GL_TEXTURE0 + TEXUNIT_FOR_PHYSTEX);
//				glTexParameteri(GL_TEXTURE_2D, GL_TEXTURE_MIN_FILTER, modes[[keyHit intValue] - 'g']);
//				glActiveTexture(GL_TEXTURE0);
//				break;
#endif
		}
	}

	MICROSTART(all);
//if (globalInfo.frame > 1)
//	vtExtractNeededPages(NULL);
	if ((debugMode != 9) && (debugMode != 8))
	{
		MICROSTART(prep);

		vtPrepareReadback();


			glUseProgram(readbackShader);


				glUniform1f(glGetUniformLocation(readbackShader, "mip_bias"), vtGetBias() + bias);


#if GL_ES_VERSION_2_0
		if (PREPASS_RESOLUTION_REDUCTION_SHIFT)
		{
			matrix44f_c p = matrix44f_c(matrix44d_ce(vt.projectionMatrix));
			matrix_rotate_about_local_z(p, (float) -(M_PI / 2.0));
			matrix44f_c m = p * [[scene camera] modelViewMatrix];
			glUniformMatrix4fv(glGetUniformLocation(readbackShader, "matViewProjection"), 1, GL_FALSE, m.data());
		}
		else
			glUniformMatrix4fv(glGetUniformLocation(readbackShader, "matViewProjection"), 1, GL_FALSE, matrix44f_c([[scene camera] projectionMatrix] * [[scene camera] modelViewMatrix]).data());
#endif

				globalInfo.renderpass = (renderPassEnum) (kRenderPassUpdateVFC | kRenderPassUseTexture);

				[children makeObjectsPerformSelector:@selector(render)];

			glUseProgram(0);
		MICROSTOP(prep);

		MICROSTART(readback);
        vtPerformReadback();
		//vtPerformOpenCLBufferReduction();

		MICROSTOP(readback);

		MICROSTART(extract);
		vtExtractNeededPages(NULL);

		//vtExtractNeededPagesOpenCL();
		MICROSTOP(extract);

		MICROSTART(upload);
		vtMapNewPages();

		MICROSTOP(upload);

	}
	glUseProgram(renderVTShader);

	glUniform1f(glGetUniformLocation(renderVTShader, "mip_bias"), vtGetBias() + bias);

#ifdef DEBUG
	glUniform1i(glGetUniformLocation(renderVTShader, "debugMode"), debugMode);
#endif	


#if GL_ES_VERSION_2_0
	if (PREPASS_RESOLUTION_REDUCTION_SHIFT)
	{
		matrix44f_c p = matrix44f_c(matrix44d_ce(vt.projectionMatrix));
		matrix_rotate_about_local_z(p, (float) -(M_PI / 2.0));
		matrix44f_c m = p * [[scene camera] modelViewMatrix];
		glUniformMatrix4fv(glGetUniformLocation(renderVTShader, "matViewProjection"), 1, GL_FALSE, m.data());
	}
	else
		glUniformMatrix4fv(glGetUniformLocation(renderVTShader, "matViewProjection"), 1, GL_FALSE, matrix44f_c([[scene camera] projectionMatrix] * [[scene camera] modelViewMatrix]).data());
#endif
	globalInfo.renderpass = (renderPassEnum) ((((debugMode == 9) || (debugMode == 8)) ? kRenderPassUpdateVFC : 0) | kRenderPassSetMaterial | kRenderPassUseTexture);

//	glFinish();
//	MICROSTART(render);

	[children makeObjectsPerformSelector:@selector(render)];

	globalInfo.renderpass = (renderPassEnum) kMainRenderPass;

	glUseProgram(0);

#if !TARGET_OS_IPHONE
#ifdef DISABLE_VBL_AND_BENCH
#ifndef WIN32
//	glFinish();
//	MICROSTOP(render);
//
//	if (globalInfo.frame > 120)
//		printf("%f\n", render / 1000.0);

	if (globalInfo.frame > 10)
		[self renderHUD:(MICROSTOP(all) / 1000.0) prepassTime:prep / 1000.0 readbackTime:readback / 1000.0 extractTime:extract / 1000.0 uploadTime:upload / 1000.0];

#endif
#else
		[self renderHUD:1000.0/globalInfo.fps prepassTime:0 readbackTime:0 extractTime:0 uploadTime:0];
#endif
#endif
    //uint32_t size = (uint32_t)vt.cachedPages.size();
   // printf("Megs %f\n"
     //      ,((float)size*c.pageMemsize / (1024.0 * 1024.0)));
}
-(void) setRenderMode: (int) rt{
	renderMode =rt;
}
-(void) setZRange: (vector2f) range {
	zrange=range;
}	

#if !TARGET_OS_IPHONE
- (void)renderHUD:(float)duration prepassTime:(float)prepass readbackTime:(float)readback extractTime:(float)extract uploadTime:(float)upload
{
	static uint16_t vpc[60], npc[60], mpc[60];
	
//printf("%f\t%f\t%f\n", prepass, readback, extract);

	NSArray *names = [NSArray arrayWithObjects:@"0. VT RENDERING", @"1. MIP CALCULATION", @"2. MIP ACTUAL", @"3. DEBUG STUFF", @"4. VT WITHOUT FALLBACK", @"5. TEST", @"6. TEST", @"7. PHYSICAL TEXTURE", @"8. NORMAL TEXTURING BILINEAR", @"9. NORMAL TEXTURING", @"10. TEST", @"11. TEST", @"12. TEST", @"13. TEST", @"14. TEST", @"15. TEST", @"16. TEST", @"17. TEST", @"18. TEST", @"19. TEST", @"20. TEST", nil];

//	glActiveTexture(GL_TEXTURE0);
//	glMatrixMode(GL_PROJECTION);
//	glPushMatrix();
//	glLoadIdentity();
//
//	glOrtho(0, globalInfo.width, 0, globalInfo.height, -1.0, 1.0);
//	glMatrixMode(GL_MODELVIEW);
//	glPushMatrix();
//	glLoadIdentity();
//
//	glEnable(GL_TEXTURE_2D);
//	glDisable(GL_DEPTH_TEST);
//	glDisable(GL_LIGHTING);
//	glEnable(GL_BLEND);

	
	npc[globalInfo.frame % 60] = vt.newPageCount;
	float npcavg = 0;
	for (int i = 0; i < 60; i++)
		npcavg += npc[i] / 60.0;
	
	vpc[globalInfo.frame % 60] = vt.necessaryPageCount;
	float vpcavg = 0;
	for (int i = 0; i < 60; i++)
		vpcavg += vpc[i] / 60.0;
	
	mpc[globalInfo.frame % 60] = vt.missingPageCount;
	float mpcavg = 0;
	for (int i = 0; i < 60; i++)
		mpcavg += mpc[i] / 60.0;
	
	//snprintf(buf, 128, "FPS %.2f %.2f ms (pp: %.2f rb: %.2f ex: %.2f up: %.2f) bias %.2f", 1000.0/duration, duration, prepass, readback, extract, upload, vtGetBias() + bias);
	snprintf(buf, 256, "FPS %.2f %.2f ms (pp: %.2f rb: %.2f ex: %.2f up: %.2f) bias %.2f   VisiblePages: %i  %.2f NewPages %i  %.2f MissingPages %i  %.2f   MODE: %s", 1000.0/duration, duration, prepass, readback, extract, upload, vtGetBias() + bias, vt.necessaryPageCount, vpcavg, vt.newPageCount, npcavg, vt.missingPageCount, mpcavg, [[names objectAtIndex:debugMode] UTF8String]); 

//	[hudFont addString:buf atPosition:CGPointMake(10, globalInfo.height - 20)];
//	[hudFont addString:(char *)[[names objectAtIndex:debugMode] UTF8String] atPosition:CGPointMake(10, globalInfo.height - 50)];
//	[hudFont render];
//
//	glDisable(GL_BLEND);
//	glDisable(GL_TEXTURE_2D);
//
//	glMatrixMode(GL_PROJECTION);
//	glPopMatrix();
//	glMatrixMode(GL_MODELVIEW);
//	glPopMatrix();
//
//	glEnable(GL_LIGHTING);
//	glEnable(GL_DEPTH_TEST);

	if (globalInfo.frame > 120)
	{
		if (duration < minMS)
			minMS = duration;
		if (duration > maxMS)
			maxMS = duration;
		allMS += duration;
	}
}

- (void)applicationWillTerminate:(NSNotification*)notification
{
	NSLog(@"minMS: %f maxMS: %f avgMS: %f", minMS, maxMS, allMS / (globalInfo.frame - 120));

	vtShutdown();
    vt.memValid=false;
}


#endif
@end
