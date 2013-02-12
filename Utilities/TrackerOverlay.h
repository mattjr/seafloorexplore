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


@interface TrackerOverlay : SceneNode {
	uint32_t				infoFontSize, infoCommonLineHeight,	infoCommonBase, infoCommonScaleWidth, infoCommonScaleHeight;

	float					scale;
	vector4f				color;
    vector2f                pos;
    
	uint8_t					current;
    double _lastTime;

}
@property (assign, nonatomic) vector2f pos;

@property (assign, nonatomic) vector4f color;
@property (assign, nonatomic) float scale;
@property (readonly, nonatomic) uint32_t infoCommonLineHeight;
-(void)switchToOrtho;
-(void)switchBackToFrustum;
-(void)updatePos:(vector2f)setposition;


- (id)init;
- (void)render;

@end