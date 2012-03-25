//
//  Camera.h
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

@interface Camera : SceneNode
{
	float fov, nearPlane, farPlane;

	matrix44f_c projectionMatrix;
	matrix44f_c viewMatrix;
    matrix44f_c viewMatrixNoRotate;
    cml::vector4i viewport;
	vector<matrix44f_c> modelViewMatrices;
    cml::matrix44f_c viewportMatrix; 

}

@property (assign, nonatomic) float fov;
@property (assign, nonatomic) float nearPlane;
@property (assign, nonatomic) float farPlane;
@property (assign, readonly) matrix44f_c projectionMatrix;
@property (assign, readonly) matrix44f_c viewMatrix;
@property (assign, readonly) matrix44f_c viewMatrixNoRotate;
@property (assign, readonly) cml::vector4i viewport;
@property (assign, readonly) matrix44f_c viewportMatrix; 



- (void)updateProjection;
typedef struct {
	vector3f startLocation;	/**< The location where the ray starts. */
	vector3f direction;			/**< The direction in which the ray points. */
} CC3Ray;
/** The coefficients of the equation for a plane in 3D space (ax + by + cz + d = 0). */
typedef struct {
	GLfloat a;				/**< The a coefficient in the planar equation. */
	GLfloat b;				/**< The b coefficient in the planar equation. */
	GLfloat c;				/**< The c coefficient in the planar equation. */
	GLfloat d;				/**< The d coefficient in the planar equation. */
} CC3Plane;
CC3Plane CC3PlaneMake(GLfloat a, GLfloat b, GLfloat c, GLfloat d) ;
vector4f CC3RayIntersectionWithPlane(CC3Ray ray, CC3Plane plane);
-(CC3Ray) unprojectPoint: (CGPoint) cc2Point;
- (matrix44f_c)modelViewMatrix;
- (matrix44f_c)modelViewMatrixMinusRotate;
- (void)loadNoRotate:(matrix44f_c)m;

- (void)load:(matrix44f_c)m;
- (void)push;
- (void)pop;
- (void)identity;
- (void)translate:(vector3f)tra;
- (void)rotate:(vector3f)rot withConfig:(axisConfigurationEnum)axisRotation;
- (CGPoint)transformScreenPt:(vector3f)pt;
-(vector4f) unprojectPoint:(CGPoint) cc2Point ontoPlane: (CC3Plane) plane;
-(vector4f) pick:(CGPoint) cc2Point intoMesh: (struct octree_struct *) thisOctree;
CC3Plane CC3PlaneFromPoints(vector3f p1, vector3f p2, vector3f p3);

-(CC3Ray) unprojectPoint: (CGPoint) cc2Point withModelView: (matrix44f_c) thismodelview ;
GLfloat CC3DistanceFromNormalizedPlane(CC3Plane p, vector3f v) ;
CC3Plane CC3PlaneNormalize(CC3Plane p) ;
#include <OpenGLES/ES1/gl.h>
#include <OpenGLES/ES1/glext.h>

void
gluPerspective(GLfloat fovy, GLfloat aspect, GLfloat zNear, GLfloat zFar);

void
gluLookAt(GLfloat eyex, GLfloat eyey, GLfloat eyez, GLfloat centerx,
          GLfloat centery, GLfloat centerz, GLfloat upx, GLfloat upy,
          GLfloat upz);

GLint
gluProject(GLfloat objx, GLfloat objy, GLfloat objz, 
           const GLfloat modelMatrix[16], 
           const GLfloat projMatrix[16],
           const GLint viewport[4],
           GLfloat *winx, GLfloat *winy, GLfloat *winz);

GLint
gluUnProject(GLfloat winx, GLfloat winy, GLfloat winz,
             const GLfloat modelMatrix[16], 
             const GLfloat projMatrix[16],
             const GLint viewport[4],
             GLfloat *objx, GLfloat *objy, GLfloat *objz);


GLint
gluUnProject4(GLfloat winx, GLfloat winy, GLfloat winz, GLfloat clipw,
              const GLfloat modelMatrix[16], 
              const GLfloat projMatrix[16],
              const GLint viewport[4],
              GLclampf nearVal, GLclampf farVal,      
              GLfloat *objx, GLfloat *objy, GLfloat *objz,
              GLfloat *objw);

void
gluPickMatrix(GLfloat x, GLfloat y, GLfloat deltax, GLfloat deltay,
              GLint viewport[4]);
void __gluMultMatrixVecf(const GLfloat matrix[16], const GLfloat in[4],
                         GLfloat out[4]);
@end
