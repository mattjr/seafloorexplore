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

#import "CollideableMesh.h"
@implementation Camera

@synthesize fov, nearPlane, farPlane, projectionMatrix, viewMatrix,viewMatrixNoRotate,viewport,viewportMatrix;
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
    viewport[0]=0;
    viewport[1]=0;
    viewport[2]=globalInfo.width;
    viewport[3]=globalInfo.height;
    cml::matrix_viewport( 
                         viewportMatrix, 
                         0.f, 
                         globalInfo.width,                   
                         0.f, 
                         globalInfo.height, 
                         cml::z_clip_neg_one // Or z_clip_zero, as appropriate 
                         );

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
    //printf("%f %f\n",cc2Point.x,cc2Point.y);
	CGPoint glPoint = cc2Point;//ccpMult(cc2Point, CC_CONTENT_SCALE_FACTOR());
    CGFloat scale = [[UIScreen mainScreen] scale];
    glPoint.x*=scale;
    glPoint.y*=scale;
    glPoint.y=globalInfo.height-glPoint.y;

    //printf("%f %f\n",glPoint.x,glPoint.y);
	// Express the glPoint X & Y as proportion of the layer dimensions, based
	// on an origin in the center of the layer (the center of the camera's view).
    CC3Ray ray;
    make_pick_ray(glPoint.x,glPoint.y,[self modelViewMatrix],[self projectionMatrix],viewportMatrix,ray.startLocation,ray.direction,true);
   // printf("%f %f %f -- %f %f %f\n",ray.startLocation[0],ray.startLocation[1],ray.startLocation[2],ray.direction[0],ray.direction[1],ray.//direction[2]);
	return ray;
}

-(CC3Ray) unprojectPoint: (CGPoint) cc2Point withModelView: (matrix44f_c) thismodelview {
    
	// CC_CONTENT_SCALE_FACTOR = 2.0 if Retina display active, or 1.0 otherwise.
	CGPoint glPoint = cc2Point;//ccpMult(cc2Point, CC_CONTENT_SCALE_FACTOR());
	// Express the glPoint X & Y as proportion of the layer dimensions, based
	// on an origin in the center of the layer (the center of the camera's view).
    CGFloat scale = [[UIScreen mainScreen] scale];
    
    glPoint.x*=scale;
    glPoint.y*=scale;
	glPoint.y=globalInfo.height-glPoint.y;

    CC3Ray ray;
    make_pick_ray(glPoint.x,glPoint.y,thismodelview,[self projectionMatrix],viewportMatrix,ray.startLocation,ray.direction,true);
    // printf("%f %f %f -- %f %f %f\n",ray.startLocation[0],ray.startLocation[1],ray.startLocation[2],ray.direction[0],ray.direction[1],ray.direction[2]);
	return ray;
}

-(vector4f) unprojectPoint:(CGPoint) cc2Point ontoPlane: (CC3Plane) plane {
	return CC3RayIntersectionWithPlane([self unprojectPoint: cc2Point], plane);
}
#define POW2(x) ((x)*(x))

-(vector4f) pick:(CGPoint) cc2Point intoMesh: (struct octree_struct *) thisOctree {
	CC3Ray ray=[self unprojectPoint: cc2Point];
    
    float intersectionPoint[3];
    if(intersectOctreeNodeWithRay(thisOctree, 0,ray, intersectionPoint))
        ;//printf("Hit %f %f %f\n",intersectionPoint[0],intersectionPoint[1],intersectionPoint[2]);
    else{
        printf("No hit\n");
        return vector4f(INFINITY,INFINITY,INFINITY,INFINITY);
    }
    
    vector4f ret(intersectionPoint[0],intersectionPoint[1],intersectionPoint[2],1);
    return ret;
    
}
/*
 ** Make m an identity matrix
 */
static void __gluMakeIdentityf(GLfloat m[16])
{
    m[0+4*0] = 1; m[0+4*1] = 0; m[0+4*2] = 0; m[0+4*3] = 0;
    m[1+4*0] = 0; m[1+4*1] = 1; m[1+4*2] = 0; m[1+4*3] = 0;
    m[2+4*0] = 0; m[2+4*1] = 0; m[2+4*2] = 1; m[2+4*3] = 0;
    m[3+4*0] = 0; m[3+4*1] = 0; m[3+4*2] = 0; m[3+4*3] = 1;
}

#define __glPi 3.14159265358979323846

void
gluPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar)
{
    GLfloat m[4][4];
    float sine, cotangent, deltaZ;
    float radians = fovy / 2 * __glPi / 180;
    
    deltaZ = zFar - zNear;
    sine = sin(radians);
    if ((deltaZ == 0) || (sine == 0) || (aspect == 0)) {
        return;
    }
    cotangent = cos(radians) / sine;
    
    __gluMakeIdentityf(&m[0][0]);
    m[0][0] = cotangent / aspect;
    m[1][1] = cotangent;
    m[2][2] = -(zFar + zNear) / deltaZ;
    m[2][3] = -1;
    m[3][2] = -2 * zNear * zFar / deltaZ;
    m[3][3] = 0;
    glMultMatrixf(&m[0][0]);
}

static void normalize(float v[3])
{
    float r;
    
    r = sqrt( v[0]*v[0] + v[1]*v[1] + v[2]*v[2] );
    if (r == 0.0) return;
    
    v[0] /= r;
    v[1] /= r;
    v[2] /= r;
}

static void cross(float v1[3], float v2[3], float result[3])
{
    result[0] = v1[1]*v2[2] - v1[2]*v2[1];
    result[1] = v1[2]*v2[0] - v1[0]*v2[2];
    result[2] = v1[0]*v2[1] - v1[1]*v2[0];
}

void
gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez, GLfloat centerx,
          GLfloat centery, GLfloat centerz, GLfloat upx, GLfloat upy,
          GLfloat upz)
{
    float forward[3], side[3], up[3];
    GLfloat m[4][4];
    
    forward[0] = centerx - eyex;
    forward[1] = centery - eyey;
    forward[2] = centerz - eyez;
    
    up[0] = upx;
    up[1] = upy;
    up[2] = upz;
    
    normalize(forward);
    
    /* Side = forward x up */
    cross(forward, up, side);
    normalize(side);
    
    /* Recompute up as: up = side x forward */
    cross(side, forward, up);
    
    __gluMakeIdentityf(&m[0][0]);
    m[0][0] = side[0];
    m[1][0] = side[1];
    m[2][0] = side[2];
    
    m[0][1] = up[0];
    m[1][1] = up[1];
    m[2][1] = up[2];
    
    m[0][2] = -forward[0];
    m[1][2] = -forward[1];
    m[2][2] = -forward[2];
    
    glMultMatrixf(&m[0][0]);
    glTranslatef(-eyex, -eyey, -eyez);
}

 void __gluMultMatrixVecf(const GLfloat matrix[16], const GLfloat in[4],
                                GLfloat out[4])
{
    int i;
    
    for (i=0; i<4; i++) {
        out[i] = 
        in[0] * matrix[0*4+i] +
        in[1] * matrix[1*4+i] +
        in[2] * matrix[2*4+i] +
        in[3] * matrix[3*4+i];
    }
}

/*
 ** Invert 4x4 matrix.
 ** Contributed by David Moore (See Mesa bug #6748)
 */
static int __gluInvertMatrixf(const GLfloat m[16], GLfloat invOut[16])
{
    float inv[16], det;
    int i;
    
    inv[0] =   m[5]*m[10]*m[15] - m[5]*m[11]*m[14] - m[9]*m[6]*m[15]
    + m[9]*m[7]*m[14] + m[13]*m[6]*m[11] - m[13]*m[7]*m[10];
    inv[4] =  -m[4]*m[10]*m[15] + m[4]*m[11]*m[14] + m[8]*m[6]*m[15]
    - m[8]*m[7]*m[14] - m[12]*m[6]*m[11] + m[12]*m[7]*m[10];
    inv[8] =   m[4]*m[9]*m[15] - m[4]*m[11]*m[13] - m[8]*m[5]*m[15]
    + m[8]*m[7]*m[13] + m[12]*m[5]*m[11] - m[12]*m[7]*m[9];
    inv[12] = -m[4]*m[9]*m[14] + m[4]*m[10]*m[13] + m[8]*m[5]*m[14]
    - m[8]*m[6]*m[13] - m[12]*m[5]*m[10] + m[12]*m[6]*m[9];
    inv[1] =  -m[1]*m[10]*m[15] + m[1]*m[11]*m[14] + m[9]*m[2]*m[15]
    - m[9]*m[3]*m[14] - m[13]*m[2]*m[11] + m[13]*m[3]*m[10];
    inv[5] =   m[0]*m[10]*m[15] - m[0]*m[11]*m[14] - m[8]*m[2]*m[15]
    + m[8]*m[3]*m[14] + m[12]*m[2]*m[11] - m[12]*m[3]*m[10];
    inv[9] =  -m[0]*m[9]*m[15] + m[0]*m[11]*m[13] + m[8]*m[1]*m[15]
    - m[8]*m[3]*m[13] - m[12]*m[1]*m[11] + m[12]*m[3]*m[9];
    inv[13] =  m[0]*m[9]*m[14] - m[0]*m[10]*m[13] - m[8]*m[1]*m[14]
    + m[8]*m[2]*m[13] + m[12]*m[1]*m[10] - m[12]*m[2]*m[9];
    inv[2] =   m[1]*m[6]*m[15] - m[1]*m[7]*m[14] - m[5]*m[2]*m[15]
    + m[5]*m[3]*m[14] + m[13]*m[2]*m[7] - m[13]*m[3]*m[6];
    inv[6] =  -m[0]*m[6]*m[15] + m[0]*m[7]*m[14] + m[4]*m[2]*m[15]
    - m[4]*m[3]*m[14] - m[12]*m[2]*m[7] + m[12]*m[3]*m[6];
    inv[10] =  m[0]*m[5]*m[15] - m[0]*m[7]*m[13] - m[4]*m[1]*m[15]
    + m[4]*m[3]*m[13] + m[12]*m[1]*m[7] - m[12]*m[3]*m[5];
    inv[14] = -m[0]*m[5]*m[14] + m[0]*m[6]*m[13] + m[4]*m[1]*m[14]
    - m[4]*m[2]*m[13] - m[12]*m[1]*m[6] + m[12]*m[2]*m[5];
    inv[3] =  -m[1]*m[6]*m[11] + m[1]*m[7]*m[10] + m[5]*m[2]*m[11]
    - m[5]*m[3]*m[10] - m[9]*m[2]*m[7] + m[9]*m[3]*m[6];
    inv[7] =   m[0]*m[6]*m[11] - m[0]*m[7]*m[10] - m[4]*m[2]*m[11]
    + m[4]*m[3]*m[10] + m[8]*m[2]*m[7] - m[8]*m[3]*m[6];
    inv[11] = -m[0]*m[5]*m[11] + m[0]*m[7]*m[9] + m[4]*m[1]*m[11]
    - m[4]*m[3]*m[9] - m[8]*m[1]*m[7] + m[8]*m[3]*m[5];
    inv[15] =  m[0]*m[5]*m[10] - m[0]*m[6]*m[9] - m[4]*m[1]*m[10]
    + m[4]*m[2]*m[9] + m[8]*m[1]*m[6] - m[8]*m[2]*m[5];
    
    det = m[0]*inv[0] + m[1]*inv[4] + m[2]*inv[8] + m[3]*inv[12];
    if (det == 0)
        return GL_FALSE;
    
    det = 1.0 / det;
    
    for (i = 0; i < 16; i++)
        invOut[i] = inv[i] * det;
    
    return GL_TRUE;
}

static void __gluMultMatricesf(const GLfloat a[16], const GLfloat b[16],
                               GLfloat r[16])
{
    int i, j;
    
    for (i = 0; i < 4; i++) {
        for (j = 0; j < 4; j++) {
            r[i*4+j] = 
            a[i*4+0]*b[0*4+j] +
            a[i*4+1]*b[1*4+j] +
            a[i*4+2]*b[2*4+j] +
            a[i*4+3]*b[3*4+j];
        }
    }
}

GLint
gluProject(GLfloat objx, GLfloat objy, GLfloat objz, 
           const GLfloat modelMatrix[16], 
           const GLfloat projMatrix[16],
           const GLint viewport[4],
           GLfloat *winx, GLfloat *winy, GLfloat *winz)
{
    float in[4];
    float out[4];
    
    in[0]=objx;
    in[1]=objy;
    in[2]=objz;
    in[3]=1.0;
    __gluMultMatrixVecf(modelMatrix, in, out);
    __gluMultMatrixVecf(projMatrix, out, in);
    if (in[3] == 0.0) return(GL_FALSE);
    in[0] /= in[3];
    in[1] /= in[3];
    in[2] /= in[3];
    /* Map x, y and z to range 0-1 */
    in[0] = in[0] * 0.5 + 0.5;
    in[1] = in[1] * 0.5 + 0.5;
    in[2] = in[2] * 0.5 + 0.5;
    
    /* Map x,y to viewport */
    in[0] = in[0] * viewport[2] + viewport[0];
    in[1] = in[1] * viewport[3] + viewport[1];
    
    *winx=in[0];
    *winy=in[1];
    *winz=in[2];
    return(GL_TRUE);
}

GLint
gluUnProject(GLfloat winx, GLfloat winy, GLfloat winz,
             const GLfloat modelMatrix[16], 
             const GLfloat projMatrix[16],
             const GLint viewport[4],
             GLfloat *objx, GLfloat *objy, GLfloat *objz)
{
    float finalMatrix[16];
    float in[4];
    float out[4];
    
    __gluMultMatricesf(modelMatrix, projMatrix, finalMatrix);
    if (!__gluInvertMatrixf(finalMatrix, finalMatrix)) return(GL_FALSE);
    
    in[0]=winx;
    in[1]=winy;
    in[2]=winz;
    in[3]=1.0;
    
    /* Map x and y from window coordinates */
    in[0] = (in[0] - viewport[0]) / viewport[2];
    in[1] = (in[1] - viewport[1]) / viewport[3];
    
    /* Map to range -1 to 1 */
    in[0] = in[0] * 2 - 1;
    in[1] = in[1] * 2 - 1;
    in[2] = in[2] * 2 - 1;
    
    __gluMultMatrixVecf(finalMatrix, in, out);
    if (out[3] == 0.0) return(GL_FALSE);
    out[0] /= out[3];
    out[1] /= out[3];
    out[2] /= out[3];
    *objx = out[0];
    *objy = out[1];
    *objz = out[2];
    return(GL_TRUE);
}

GLint
gluUnProject4(GLfloat winx, GLfloat winy, GLfloat winz, GLfloat clipw,
              const GLfloat modelMatrix[16], 
              const GLfloat projMatrix[16],
              const GLint viewport[4],
              GLclampf nearVal, GLclampf farVal,      
              GLfloat *objx, GLfloat *objy, GLfloat *objz,
              GLfloat *objw)
{
    float finalMatrix[16];
    float in[4];
    float out[4];
    
    __gluMultMatricesf(modelMatrix, projMatrix, finalMatrix);
    if (!__gluInvertMatrixf(finalMatrix, finalMatrix)) return(GL_FALSE);
    
    in[0]=winx;
    in[1]=winy;
    in[2]=winz;
    in[3]=clipw;
    
    /* Map x and y from window coordinates */
    in[0] = (in[0] - viewport[0]) / viewport[2];
    in[1] = (in[1] - viewport[1]) / viewport[3];
    in[2] = (in[2] - nearVal) / (farVal - nearVal);
    
    /* Map to range -1 to 1 */
    in[0] = in[0] * 2 - 1;
    in[1] = in[1] * 2 - 1;
    in[2] = in[2] * 2 - 1;
    
    __gluMultMatrixVecf(finalMatrix, in, out);
    if (out[3] == 0.0) return(GL_FALSE);
    *objx = out[0];
    *objy = out[1];
    *objz = out[2];
    *objw = out[3];
    return(GL_TRUE);
}

void
gluPickMatrix(GLfloat x, GLfloat y, GLfloat deltax, GLfloat deltay,
              GLint viewport[4])
{
    if (deltax <= 0 || deltay <= 0) { 
        return;
    }
    
    /* Translate and scale the picked region to the entire window */
    glTranslatef((viewport[2] - 2 * (x - viewport[0])) / deltax,
                 (viewport[3] - 2 * (y - viewport[1])) / deltay, 0);
    glScalef(viewport[2] / deltax, viewport[3] / deltay, 1.0);
}

@end
