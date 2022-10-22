import std/options    # For (type or nil) types
import std/algorithm  # For seq.reversed
#..........
import vmath
#..........
import ./vect
import ./plane
#............................
type Vertex * = seq[DVec3]
#............................
func expand*(verts :Vertex; origin :DVec3; radius :float64) :Vertex=
  for vert in verts:
    result.add((vert-origin).normalize * radius + origin)

#............................
type Polygon * = object
  ## Represents a coplanar, directed polygon with at least 3 vertices.
  ## Uses high-precision value types.
  vertex *:Vertex
#............................
template count*(p :Polygon) :int= p.vertex.len
template plane*(p :Polygon) :Plane= newPlane(p.vertex[0], p.vertex[1], p.vertex[2])
func origin*(p :Polygon) :DVec3= average(p.vertex, vec3Zero)
#............................

#............................
func average*(polygons :seq[Polygon]; point :DVec3= vec3Zero) :DVec3=
  ## Average all polygon origins together into one point
  result = point
  for poly in polygons:
    result = result + poly.origin
  result = result / polygons.len


#............................
func newPolygon*(vertex :Vertex) :Polygon= result.vertex = vertex
  ## Creates a polygon from a list of points
  ## - vertex : The vertices of the polygon

#............................
func newPolygon*(plane :Plane; radius :float64= 1000000) :Polygon=
  ## Creates a polygon from a plane and a radius.
  ## Expands the plane to the radius size to create a large polygon with 4 vertices.
  ## - plane  : The polygon plane
  ## - radius : The polygon radius
  # Get aligned up and right axes to the plane
  var dir   = plane.closestAxisToNormal
  var tmp   = if dir == vec3UnitZ: -vec3UnitY else: -vec3UnitZ
  var up    = tmp.cross(plane.normal).normalize
  var right = plane.normal.cross(up).normalize
  var verts :Vertex= @[
    plane.ptOnPlane + right + up, # Top right
    plane.ptOnPlane - right + up, # Top left
    plane.ptOnPlane - right - up, # Bot left
    plane.ptOnPlane + right - up, # Bot right
  ]
  var origin    = verts.average
  result.vertex = verts.expand(origin, radius)

#............................
func classify*(poly :Polygon; plane :Plane) :PlaneType=
  var count = poly.count
  var fr :int  # Front
  var bk :int  # Back
  var op :int  # On Plane
  for vert in poly.vertex:
    var test:int = plane.onPlane(vert)
    # Vertices on the plane are both in front and behind the plane in this context
    if test <= 0: bk.inc
    if test >= 0: fr.inc
    if test == 0: op.inc
  if   count == op: result = PlaneType.OnPlane
  elif count == fr: result = PlaneType.Front
  elif count == bk: result = PlaneType.Back
  else:             result = PlaneType.Spanning

#............................
template toNil*(a,b,c,d :var Option[Polygon]) :void=
  a = none(Polygon)
  b = none(Polygon)
  c = none(Polygon)
  d = none(Polygon)

#............................
func split*(poly :Polygon; plane :Plane; back, front, coBack, coFront :var Option[Polygon]) :bool=
  ## Splits this polygon by a clipping plane, returning the back and front planes.
  ## The original polygon is not modified.
  ## - clip   : The clipping plane
  ## - back   : The back polygon
  ## - front  : The front polygon
  ## - coBack : Coplanar. If the polygon rests on the plane and points backward, this will not be null
  ## - coFront: Coplanar. If the polygon rests on the plane and points forward, this will not be null
  ## Returns:
  ## - True if the split was successful
  var distances :seq[float64]
  for vert in poly.vertex:  distances.add(plane.evalAtPoint(vert))

  var cb, cf :int
  for dist in distances.mitems:
    if   dist < -Epsilon: cb.inc
    elif dist >  Epsilon: cf.inc
    else:                 dist = 0
  # Check non-spanning cases
  # Co-planar
  if cb == 0 and cf == 0:
    toNil(back, front, coBack, coFront)
    if (poly.plane.normal.dot(plane.normal) > 0):
      coFront = some(poly)
    else:
      coBack  = some(poly)
    return false
  # All vertex in front
  elif cb == 0:
    toNil(back, front, coBack, coFront)
    front = some(poly)
    return false
  # All vertex behind
  elif cf == 0:
    toNil(back, front, coBack, coFront)
    back = some(poly)
    return false
  # Get the new front and back vertices
  var backVerts, frontVerts :Vertex
  for this, vert in poly.vertex:
    let next = (this + 1) mod poly.count # Make next poly the first, if we are at the last
    let sv = poly.vertex[this]  # Start vert
    let ev = poly.vertex[next]  # End   vert
    let sd = distances[this]    # Start distance to
    let ed = distances[next]    # End   distance to
    if sd <= 0: backVerts.add(sv)
    if sd >= 0: frontVerts.add(sv)
    if (sd < 0 and ed > 0) or (ed < 0 and sd > 0):
      # Calculate how far the intersection point is from the start/end (interpolation)
      # Convert the point to vector form, and add it to the front and back verts lists
      let interp = sd / (sd - ed)
      let inters = sv * (1-interp) + ev*interp
      backVerts.add(inters)
      frontVerts.add(inters)
    back    = some(newPolygon(backVerts))
    front   = some(newPolygon(frontVerts))
    coBack  = none(Polygon)
    coFront = none(Polygon)
    return true

#............................
func split*(poly :Polygon; plane :Plane; back, front :var Option[Polygon]) :bool=
  ## Splits this polygon by a clipping plane, returning the back and front planes.
  ## The original polygon is not modified.
  ## - clip  : The clipping plane
  ## - back  : The back polygon
  ## - front : The front polygon
  ## Returns:
  ## - True if the split was successful
  var coBack  :Option[Polygon]
  var coFront :Option[Polygon]
  result = poly.split(plane, back, front, coBack, coFront)
  discard coBack; discard coFront

#............................
template reversed*(p :Polygon) :Polygon= newPolygon(p.vertex.reversed)

#............................
