import std/options
#............................
import vmath
#............................
import ./polyg
import ./plane
import ./vect
#............................

type Polyhedron = object
  ## Convex polyhedron with at least 4 sides.
  ## High-precision value types.
  polygons :seq[Polygon]
#............................


#............................
func average*(polygons :seq[Polygon]; point :DVec3= vec3Zero) :DVec3=
  ## Average all origins together into one origin
  result = point                  # var origin = Vector3.Zero
  for poly in polygons:           # foreach (var p in polygons)
    result += poly.origin         #   origin += p.Origin;
  result = result / polygons.len  # origin = origin / polygons.Count;
#............................
template origin*(p :Polyhedron) :DVec3= p.polygons.average
#............................

#............................
func newPolyhedron*(polys :seq[Polygon]) :Polyhedron=  result.polygons = polys
  ## Creates a polyhedron from a list of polygons which are assumed to be valid.

#............................
func newPolyhedron*(planes :seq[Plane]) :Polyhedron=
  ## Creates a polyhedron by intersecting a list of at least 4 planes.
  for this,plane in planes:
    # Split the polygon by all other planes
    var poly = newPolygon(plane)      # Make a giant polygon first
    var back, front :Option[Polygon]  # Back and front polys, with (Poly or nil) type
    for other in 0..planes.high:
      if this != other and poly.split(plane, back, front):
        poly = back.get
    result.polygons.add(poly)
  # Ensure all the faces point outwards
  var origin = result.polygons.average
  for poly in result.polygons.mitems:
    if poly.plane.onPlane(origin) >= 0:
      poly = poly.reversed

#............................
template toNil*(a,b :var Option[Polyhedron])=
  a = none(Polyhedron)
  b = none(Polyhedron)

#............................
func classify*(ph :Polyhedron; plane :Plane) :set[PlaneType]=
  for poly in ph.polygons:
    result.incl poly.classify(plane)

#............................
func split*(ph :Polyhedron; plane :Plane; back, front :var Option[Polyhedron]) :bool=
  ## Splits this polyhedron into two polyhedron by intersecting against a plane.
  ## - plane : The splitting plane
  ## - back  : The back side of the polyhedron
  ## - front : The front side of the polyhedron
  ## Returns:
  ## - true  : if the plane splits the polyhedron, 
  ## - false : if the plane doesn't intersect
  toNil(back, front)
  # Check that this solid actually spans the plane
  let classified = ph.classify(plane)
  if not classified.contains(PlaneType.Spanning):
    if   classified.contains(PlaneType.Back):  back  = some(ph)
    elif classified.contains(PlaneType.Front): front = some(ph)
    return false
  var backPlanes  = @[plane]
  var frontPlanes = @[newPlane(-plane.normal, -plane.distFromOrig)]
  for face in ph.polygons:
    let classif = face.classify(plane)
    if classif != PlaneType.Back:  frontPlanes.add(face.plane)
    if classif != PlaneType.Front: backPlanes.add(face.plane)
  back  = some(newPolyhedron(backPlanes))
  front = some(newPolyhedron(frontPlanes))
  return true

#............................
