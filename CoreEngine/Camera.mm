//
//  Camera.m
//  Core3D
//
//  Created by Julian Mayer on 21.11.07.
//  Copyright 2007 - 2010 A. Julian Mayer.
//
/*
This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 3.0 of the License, or (at your option) any later version.

This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License along with this library; if not, see <http://www.gnu.org/licenses/> or write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
*/

#import "Core3D.h"
#include "LibVT_Internal.h"


@implementation Camera

@synthesize fov, nearPlane, farPlane, projectionMatrix, viewMatrix,viewMatrixNoRotate;
extern vtData vt;

- (id)init
{
	if ((self = [super init]))
	{
		fov = 45.0f;
		nearPlane = 1.0f;
		farPlane = 8000.0f;

		[self addObserver:self forKeyPath:@"fov" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"nearPlane" options:NSKeyValueObservingOptionNew context:NULL];
		[self addObserver:self forKeyPath:@"farPlane" options:NSKeyValueObservingOptionNew context:NULL];

		modelViewMatrices.push_back(cml::identity_transform<4,4>());
	}

	return self;
}

- (void)reshapeNode:(NSArray *)size
{
	globalInfo.width = [[size objectAtIndex:0] intValue];
	globalInfo.height = [[size objectAtIndex:1] intValue];

	glViewport(0, 0, globalInfo.width, globalInfo.height);

	[self updateProjection];
}

- (void)transform
{
	/*[[scene camera] rotate:-rotation withConfig:axisConfiguration];
	[[scene camera] translate:-position];

	if (relativeModeTarget != nil)
	{
		[[scene camera] rotate:-[relativeModeTarget rotation] withConfig:relativeModeAxisConfiguration];
		[[scene camera] translate:-[relativeModeTarget position]];
	}
*/
	viewMatrix = modelViewMatrices.back();
   // glLoadMatrixf(modelViewMatrices.back().data());

}

- (CGPoint)transformScreenPt:(vector3f)pt
{
    cml::vector4f tmppt;
    tmppt[0]=pt[0];
    tmppt[1]=pt[1];
    tmppt[2]=pt[2];
    tmppt[3]=1.0;
    printf("AAA %f %f %f\n",tmppt[0],tmppt[1],tmppt[2]);
    CGPoint trans;
    matrix44f_c mvp =matrix44f_c([[scene camera] projectionMatrix]);

    matrix44f_c invmvp=cml::inverse(mvp);
    cml::vector4f rotpt;
    rotpt= tmppt*invmvp;

   rotpt[0]/=rotpt[3];
   rotpt[1]/=rotpt[3];
    rotpt[2]/=rotpt[3];
    printf("BBB %f %f %f\n",rotpt[0],rotpt[1],rotpt[2]);
    trans.x=rotpt[0];
    trans.y=rotpt[1];
    
    return trans;    
}

- (void)updateProjection
{
	matrix_perspective_yfov_RH(projectionMatrix, cml::rad(fov), globalInfo.width / globalInfo.height, nearPlane, farPlane, cml::z_clip_neg_one);
#ifdef TARGET_OS_IPHONE
	matrix_rotate_about_local_z(projectionMatrix, (float) -(M_PI / 2.0));
#endif

#ifndef GL_ES_VERSION_2_0
	glMatrixMode(GL_PROJECTION);
	glLoadMatrixf(projectionMatrix.data());
	glMatrixMode(GL_MODELVIEW);
#endif
}

- (void)observeValueForKeyPath:(NSString *)keyPath ofObject:(id)object change:(NSDictionary *)change context:(void *)context
{
	[self updateProjection];
}

- (matrix44f_c)modelViewMatrix
{
	return modelViewMatrices.back();
}
- (matrix44f_c)modelViewMatrixMinusRotate
{
    return viewMatrixNoRotate;
}

- (void)identity
{
//	cml::identity_transform(modelViewMatrices.back());
}

- (void)translate:(vector3f)tra
{
	matrix44f_c m;
	matrix_translation(m, tra);
	modelViewMatrices.back() *= m;

#ifndef GL_ES_VERSION_2_0
	glLoadMatrixf(modelViewMatrices.back().data());
#endif
}

- (void)load:(matrix44f_c)m
{
	
	modelViewMatrices.back() = m;
    
#ifndef GL_ES_VERSION_2_0
	glLoadMatrixf(modelViewMatrices.back().data());
#endif
}
- (void)loadNoRotate:(matrix44f_c)m;
{
    viewMatrixNoRotate =m;
}

- (void)rotate:(vector3f)rot withConfig:(axisConfigurationEnum)axisRotation;
{
	for (uint8_t i = 0; i < 3; i++)	// this allows us to configure per-node the rotation order and axis to ignore (which is mostly useful for target mode)
	{
		uint8_t axis = (axisRotation >> (i * 2)) & 3;

		if ((axis != kDisabledAxis) && (rot[axis] != 0))
			matrix_rotate_about_local_axis(modelViewMatrices.back(), axis, cml::rad(rot[axis]));
	}

#ifndef GL_ES_VERSION_2_0
	glLoadMatrixf(modelViewMatrices.back().data());
#endif
}

- (void)push
{
	matrix44f_c m = modelViewMatrices.back();
	modelViewMatrices.push_back(m);
}

- (void)pop
{
	modelViewMatrices.pop_back();

#ifndef GL_ES_VERSION_2_0
	glLoadMatrixf(modelViewMatrices.back().data());
#endif
}


/** Returns a string description of the specified CC3Plane struct in the form "(a, b, c, d)" */
static inline NSString* NSStringFromCC3Plane(CC3Plane p) {
	return [NSString stringWithFormat: @"(%.3f, %.3f, %.3f, %.3f)", p.a, p.b, p.c, p.d];
}

/** Returns a CC3Plane structure constructed from the specified coefficients. */
CC3Plane CC3PlaneMake(GLfloat a, GLfloat b, GLfloat c, GLfloat d) {
	CC3Plane p;
	p.a = a;
	p.b = b;
	p.c = c;
	p.d = d;
	return p;
}

/** Returns the normal of the plane, which is (a, b, c) from the planar equation. */
inline vector3f CC3PlaneNormal(CC3Plane p) {
	return vector3f(p.a, p.b, p.c);
}

/**
 * Returns a CC3Plane structure that contains the specified points.
 * 
 * The direction of the normal of the returned plane is dependent on the winding order
 * of the three points. Winding is done in the order the points are specified
 * (p1 -> p2 -> p3), and the normal will point in the direction that has the three points
 * winding in a counter-clockwise direction, according to a right-handed coordinate
 * system. If the direction of the normal is important, be sure to specify the three
 * points in the appropriate order.
 */
CC3Plane CC3PlaneFromPoints(vector3f p1, vector3f p2, vector3f p3) {
	vector3f v12 = (p2- p1);
	vector3f v23 = (p3- p2);
	vector3f n = normalize(cross(v12, v23));
	GLfloat d = -dot(p1, n);
	return CC3PlaneMake(n[0], n[1], n[2], d);
}

/** Returns a normalized copy of the specified CC3Plane so that the length of its normal (a, b, c) is 1.0 */
CC3Plane CC3PlaneNormalize(CC3Plane p) {
	GLfloat normLen = cml::length(CC3PlaneNormal(p));
	CC3Plane np;
	np.a = p.a / normLen;
	np.b = p.b / normLen;
	np.c = p.c / normLen;
	np.d = p.d / normLen;
	return np;
}

/** Returns the distance from the point represented by the vector to the specified normalized plane. */
GLfloat CC3DistanceFromNormalizedPlane(CC3Plane p, vector3f v) {
	return (p.a * v[0]) + (p.b * v[1]) + (p.c * v[2]) + p.d;
}
vector4f CC3RayIntersectionWithPlane(CC3Ray ray, CC3Plane plane) {
	// For a plane defined by v.pn + d = 0, where v is a point on the plane, pn is the normal
	// of the plane and d is a constant, and a ray defined by v(t) = rs + t*rd, where rs is
	// the ray start rd is the ray direction, and t is a multiple, the intersection occurs
	// where the two are equal: (rs + t*rd).pn + d = 0.
	// Solving for t gives t = -(rs.pn + d) / rd.pn
	// The denominator rd.n will be zero if the ray is parallel to the plane.
	vector3f pn = CC3PlaneNormal(plane);
	vector3f rs = ray.startLocation;
	vector3f rd = ray.direction;
	GLfloat dirDotNorm = dot(rd, pn);
	if (dirDotNorm != 0.0f) {
		GLfloat dirDist = -(dot(rs, pn) + plane.d) / dot(rd, pn);
		vector3f loc = (rs+ (rd*dirDist));
		return vector4f(loc[0],loc[1],loc[2], dirDist);
	} else {
		return vector4f(0,0,0,0);
	}
}
-(CC3Ray) unprojectPoint: (CGPoint) cc2Point {
    
	// CC_CONTENT_SCALE_FACTOR = 2.0 if Retina display active, or 1.0 otherwise.
	CGPoint glPoint = cc2Point;//ccpMult(cc2Point, CC_CONTENT_SCALE_FACTOR());
	
	// Express the glPoint X & Y as proportion of the layer dimensions, based
	// on an origin in the center of the layer (the center of the camera's view).
	    cml::matrix44f_c viewportMatrix; 
    cml::matrix_viewport( 
                         viewportMatrix, 
                         0.f, 
                        globalInfo.width,                   
                         0.f, 
                         globalInfo.height, 
                         cml::z_clip_neg_one // Or z_clip_zero, as appropriate 
                         );
    CC3Ray ray;
    make_pick_ray(glPoint.x,glPoint.y,[self modelViewMatrixMinusRotate],[self projectionMatrix],viewportMatrix,ray.startLocation,ray.direction);
	return ray;
}

-(vector4f) unprojectPoint:(CGPoint) cc2Point ontoPlane: (CC3Plane) plane {
	return CC3RayIntersectionWithPlane([self unprojectPoint: cc2Point], plane);
}
@end
