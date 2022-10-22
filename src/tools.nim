import std/tables
#............................

#............................
template lineSep*()= echod ".............................................."
const echod * = debugEcho
#............................
# Workaround Vector types:
#   strscans.$f doesnt allow for float32 vector types (vmath.Vec*)
type V3 * = object
  x*, y*, z* :float
type V2 * = object
  x*, y*     :float
#............................
# Python-like behavior for checking strings/ints as conditionals
converter toBool*(s:string):bool= result = if s == "": false else: true
converter toBool*(n:int)   :bool= result = if n == 0:  false else: true
converter toBool*(t:Table[string,string]):bool=
  if t.len == 0: result = false
  elif t == {"":""}.toTable: result = false
  else: result = true
#............................
proc clear*(s :var seq) :void= s.setLen(0)
#............................
func merge*(t1, t2 :Table[string, string]) :Table[string, string]=
  for key, val in t1: result[key] = val
  for key, val in t2: result[key] = val
#............................
