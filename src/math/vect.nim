import ./core as math; export math
#............................
template vec3Zero*()  :DVec3= dvec3(0,0,0)
template vec3Unit*()  :DVec3= dvec3(1,1,1)
template vec3UnitX*() :DVec3= dvec3(1,0,0)
template vec3UnitY*() :DVec3= dvec3(0,1,0)
template vec3UnitZ*() :DVec3= dvec3(0,0,1)
#............................
func `/` *(v :DVec3; num :int) :DVec3=  dvec3(v.x / num.float64, v.y / num.float64, v.z / num.float64)
func `/=`*(v :DVec3; num :int) :DVec3=  v/num
#............................
func equivalentTo*(v, other :DVec3, delta :float64= Epsilon) :bool=
  var xd = (v.x - other.x).abs
  var yd = (v.y - other.y).abs
  var zd = (v.z - other.z).abs
  result = xd < delta and yd < delta and zd < delta
#............................
func average*(vertex :seq[DVec3]; point :DVec3= vec3Zero) :DVec3=
  ## Average all vectors together into one point
  result = point
  for vert in vertex:
    result += vert
  result = result / vertex.len

