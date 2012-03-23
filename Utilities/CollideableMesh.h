//
//  CollideableMesh.h
//  Core3D
//
//  Created by Julian Mayer on 14.05.08.
//  Copyright 2008 - 2010 A. Julian Mayer.
//
/*
 This library is free software; you can redistribute it and/or modify it under the terms of the GNU Lesser General Public License as published by the Free Software Foundation; either version 3.0 of the License, or (at your option) any later version.

 This library is distributed in the hope that it will be useful, but WITHOUT ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU Lesser General Public License for more details.

 You should have received a copy of the GNU Lesser General Public License along with this library; if not, see <http://www.gnu.org/licenses/> or write to the Free Software Foundation, Inc., 59 Temple Place, Suite 330, Boston, MA 02111-1307 USA
 */


@interface CollideableMesh : Mesh
{
	struct octree_struct	*octree_collision;
}

bool IntersectionLineTriangle(CC3Ray r,
                              vector3f vert0, vector3f vert1, vector3f vert2,
                              float *t, float *u, float *v);
- (vector3f)intersectWithLineStart:(vector3f)startPoint end:(vector3f)endPoint;
bool intersectsWithRay( const CC3Ray& ray ,const vector3f center, const vector3f extent) ;
- (TriangleIntersectionInfo)intersectWithMesh:(CollideableMesh *)otherMesh;
BOOL intersectOctreeNodeWithLine(struct octree_struct *thisOctree, int nodeNum, const vector3f startPoint, const vector3f endPoint, float intersectionPoint[3]); BOOL intersectOctreeNodeWithRay(struct octree_struct *thisOctree, int nodeNum, CC3Ray ray, float intersectionPoint[3]) ;
@end