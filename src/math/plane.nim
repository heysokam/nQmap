import std/options
#..........
import ./core
import ./vect
#............................
type Plane * = object
  ## Defines a plane in the form Ax + By + Cz + D = 0
  ## Uses high-precision value types.
  normal       *:DVec3 #?
  distFromOrig *:float64
  ABCD         *:DVec4
  ptOnPlane    *:DVec3
#............................
type PlaneType * = enum Front, Back, OnPlane, Spanning
#............................

#............................
template toABCD*(norm :DVec3; dist :float64) :DVec4= dvec4(norm.x, norm.y, norm.z, -dist)
template A*(p :Plane) :float64= p.ABCD.x
template B*(p :Plane) :float64= p.ABCD.y
template C*(p :Plane) :float64= p.ABCD.z
template D*(p :Plane) :float64= p.ABCD.w

#............................
func newPlane*(p1, p2, p3 :DVec3) :Plane=
  var ab = p2-p1
  var ac = p3-p1
  result.normal       = ac.cross(ab).normalize()
  result.distFromOrig = result.normal.dot(p1)
  result.ptOnPlane    = p1
  result.ABCD         = toABCD(result.normal, result.distFromOrig)

#............................
func newPlane*(norm, ptOnPlane :DVec3) :Plane=
  result.normal       = norm.normalize
  result.distFromOrig = result.normal.dot(ptOnPlane)
  result.ptOnPlane    = ptOnPlane
  result.ABCD         = toABCD(result.normal, result.distFromOrig)

#............................
func newPlane*(norm :DVec3; distFromOrig :float64) :Plane=
  result.normal       = norm.normalize
  result.distFromOrig = distFromOrig
  result.ptOnPlane    = result.normal * result.distFromOrig
  result.ABCD         = toABCD(result.normal, result.distFromOrig)

#............................
func evalAtPoint*(p :Plane; pt :DVec3) :float64= p.A*pt.x + p.B*pt.y + p.C*pt.z + p.D

#............................
func onPlane*(p :Plane; pt :DVec3; epsilon :float64= Epsilon) :int=
  ## Find if the given point is above, below, or on the plane.
  ## - co      : The Vector3 to test
  ## - epsilon : Tolerance value
  ## ---
  ## Returns:
  ## -1 : if Vector3 is below the plane
  ##  1 : if Vector3 is above the plane
  ##  0 : if Vector3 is on the plane
  # eval (s = Ax + By + Cz + D) at point (x,y,z)
  # if s > 0 then point is "above" the plane (same side as normal)
  # if s < 0 then it lies on the opposite side
  # if s = 0 then the point (x,y,z) lies on the plane
  var eval = p.evalAtPoint(pt)
  if eval.abs < epsilon: result =  0
  elif eval < 0:         result = -1
  else:                  result =  1

#............................
func intersectionPt*(p :Plane; startp, endp :DVec3; ignoreDir :bool= false; ignoreSegment :bool= false) :Option[DVec3]=
  ## Gets the point that the line intersects with this plane.
  ## - startp:        The start of the line to intersect with
  ## - endp:          The end of the line to intersect with
  ## - ignoreDir:     Set to true to ignore the direction of the plane and line when intersecting. Defaults to false.
  ## - ignoreSegment: Set to true to ignore the start and end points of the line in the intersection. Defaults to false.
  ## ---
  ## Returns:   Option[DVec3]
  ## - Point of intersection
  ## - nil if the line does not intersect
  ## Access the result with OUTP.get  
  ##   eg: var thing = intersectionPt(args); thing.get
  ## ---
  ## http://softsurfer.com/Archive/algorithm_0104/algorithm_0104B.htm#Line%20Intersections
  ## http://paulbourke.net/geometry/planeline/
  var dir = endp-startp
  var den = -p.normal.dot(dir)
  var num = p.normal.dot(startp - p.normal*p.distFromOrig)
  if den.abs < Epsilon or (not ignoreDir and den < 0): return none(DVec3)
  var u = num/den
  if (not ignoreSegment and u notin 0..1): return none(DVec3)
  return some(startp + u*dir)

#............................
func project*(p :Plane; pt :DVec3) :DVec3= pt - ((pt-p.ptOnPlane).dot(p.normal)) * p.normal
  ## Project a point into the space of this plane. I.e. Get the point closest
  ## to the provided point that is on this plane.
  ## - point: The point to project
  ## Returns:
  ## - The point projected onto this plane
  ## ---
  ## Projected = Point - ((Point - PointOnPlane) . Normal) * Normal
  ## http://www.gamedev.net/topic/262196-projecting-vector-onto-a-plane/

#............................
func closestAxisToNormal*(p :Plane) :DVec3=
  ## Gets the axis closest to the normal of this plane
  ## Returns: 
  ## - Vector3.UnitX, Vector3.UnitY, or Vector3.UnitZ depending on the plane's normal
  var  norm = p.normal.abs
  if   norm.x >= norm.y and norm.x >= norm.z: result = vec3UnitX
  elif norm.y >= norm.z:                      result = vec3UnitY
  else:                                       result = vec3UnitZ

#............................
template clone*(p :Plane) :Plane= Plane(p.normal, p.distFromOrig)

#............................
func intersect*(p1, p2, p3 :Plane) :Option[DVec3]=
  ## Intersects three planes and gets the point of their intersection.
  ## ---
  ## Returns:    Option[DVec3]
  ## - The point that the planes intersect at 
  ## - nil if they do not intersect at a point
  ## ---
  ## http://paulbourke.net/geometry/3planes/
  var c1 = p2.normal.cross(p3.normal)
  var c2 = p3.normal.cross(p1.normal)
  var c3 = p1.normal.cross(p2.normal)
  var den = p1.normal.dot(c1)
  if den < Epsilon: return none(DVec3)  # No intersection. Planes must be parallel
  var num = (-p1.D*c1) + (-p2.D*c2) + (-p3.D*c3)
  result = some(num/den)

#............................
func equivalentTo*(p, other :Plane; delta :float64= Epsilon) :bool=
  result = p.normal.equivalentTo(other.normal, delta) and (p.distFromOrig - other.distFromOrig).abs < delta

#............................
