import strscans  # For parsing the data without Regex
import tables    # For entity properties
#............................

import ./tools

#............................
# // Game: Quake
const pGame = "$s//$sGame:$s$*$."
proc parseGame(lbuf :seq[string]) :string= 
  for line in lbuf:
    if line.scanf(pGame, result): return
#............................


#............................
# // Format: Valve
const pFormat = "$s//$sFormat:$s$*$."
proc parseFormat(lbuf :seq[string]) :string= 
  for line in lbuf:
    if line.scanf(pFormat, result): return
#............................


#............................
type Block = object
  title   :string
  content :seq[string]
#............................
const pComment    = "$s//$*" # Comment line. Modern apps also use it to differentiate brush/entity and store its id number
const pBlockOpen  = "$s{$s"  # Block or sub-block starts
const pBlockClose = "$s}$s"  # Block or sub-block ends
func isBOpen (line :string) :bool= line.scanf(pBlockOpen)
func isBClose(line :string) :bool= line.scanf(pBlockClose)
#............................
proc parseBlocks(lbuf :seq[string]) :seq[Block]= 
  var buf:seq[string]
  for line in lbuf: buf.add(line)
  var bCount = 0            # Block count
  var level  = 0            # Current Brackets level. Increases every {, decreases every }
  var titles   :seq[string] # Comment lines buffer
  for id,line in buf:
    var thisLine :string
    if line.scanf(pComment, thisLine): 
      if level == 0:        # Add comment to titles only outside of a block
        titles.add(thisline)
        continue            # Line is title, so skip adding it to content
    elif line.isBOpen:
      if level == 0: 
        bCount.inc          # Increase total block count
        result.add(Block(title: "//" & titles[^1], content: @[])) # Add last found comment as title, and init block content
      level.inc                        # Increase bracket level
    elif line.isBClose:      # When we find a closing bracket
      level.dec                        # Reduce the bracket level / count
    result[bCount-1].content.add(line) # Add the line to the corresponding block
#............................


#............................
type TexMap = object
  x, y, z :float
  offset  :float
#............................
type Texture = object
  name   :string
  tm1    :TexMap
  tm2    :TexMap
  rot    :float
  scale  :V2
#............................
type Face = object
  p1, p2, p3 :V3
  tex        :Texture
#............................
# Face
const pFace = """
$s($s$f$s$f$s$f$s)$s($s$f$s$f$s$f$s)$s($s$f$s$f$s$f$s)$s$* [$s$f$s$f$s$f$s$f$s]$s[$s$f$s$f$s$f$s$f$s]$s$f$s$f$s$f"""
# (  x1  y1  z1  )  (  x2  y2  z2  )  (  x3  y3  z3  ) TEXTURE [ Tx1 Ty1 Tz1 Toffset1 ] [ Tx2 Ty2 Tz2 Toffset2 ] rotation Xscale Yscale
func parseFace(line :string) :Face= 
  if line.scanf(  pface, 
    result.p1.x, result.p1.y, result.p1.z,
    result.p2.x, result.p2.y, result.p2.z,
    result.p3.x, result.p3.y, result.p3.z,
    result.tex.name,
    result.tex.tm1.x, result.tex.tm1.y, result.tex.tm1.z, result.tex.tm1.offset,
    result.tex.tm2.x, result.tex.tm2.y, result.tex.tm2.z, result.tex.tm2.offset,
    result.tex.rot, result.tex.scale.x, result.tex.scale.y
    ): return
#............................


#............................
type Brush = object
  id    :int
  faces :seq[Face]
#..........
proc clear(b :var Brush) :void= b.id = -1; b.faces.setLen(0)

#...................
type Properties = Table[string,string]
#...................
const pProperties = "$s\"$w\"$s\"$w\"$s$."
func parseProperty(line :string) :Properties=
  var key, val :string
  if line.scanf(pProperties, key, val): result[key] = val
#..........
func parseProperties(buf :Block) :Properties=
  var tmp :Properties
  for line in buf.content:
    tmp    = parseProperty(line)
    result = result.merge(tmp)

#...................
type Entity = object
  id         :int
  typ        :string
  properties :Properties
  brushes    :seq[Brush]
#...................
const pId = "$s//$w$s$i$s"
func parseId(b :Block) :tuple=
  var id  :int
  var typ :string
  if b.title.scanf(pId, typ, id): return (id, typ)
#............................



# WIP:
#............................
func toMain(b :Block) :Block=
  result    = b
  let last  = b.content.high
  let first = 0
  if b.content[last].isBClose: result.content.delete(last)
  if b.content[first].isBOpen: result.content.delete(first)

#............................
const pFaceCheck = "$s($s"
func isFace(line :string) :bool= line.scanf(pFaceCheck)
func hasFace(b :Block) :bool=
  for line in b.content:
    if line.isFace: result = true; break
    else: result = false
#............................
func parseBrushes(buf :Block) :seq[Brush]=
  if not buf.hasFace: return @[]
  var bBuf     = buf.toMain  # Remove opening/closing brackets, if present
  var tmpBrush :Brush
  var typ      :string
  for lnum, line in bBuf.content:
    var idPrev     = (lnum-1).max(0)
    var idPrevprev = (lnum-2).max(0)
    var prev       = bBuf.content[idPrev]
    var prevprev   = bBuf.content[idPrevprev]
    var lineIsFace = line.isFace
    var prevIsFace = prev.isFace
    if lineIsFace and prev.isBOpen:                  # Starting a new brush block
      tmpBrush.clear                                 #   Clear the temp brush
      discard prevprev.scanf(pId, typ, tmpBrush.id)  #   Set tempbrush id with the Id 2lines above
    elif lineIsFace and prevIsFace:                  # Inside a brush block
      tmpBrush.faces.add(line.parseFace)             #   Add the face to the temp brush
    elif line.isBClose and prevIsFace:               # Finishing a brush block
      result.add(tmpBrush)                           #   Add the temp brush buffer to the result

#............................
func parseEnt(buf :Block) :Entity= 
  var id  :int    = 0
  var typ :string = ""
  var prp :Properties
  var brs :seq[Brush]
  # Get the id and type
  (id, typ) = buf.parseId
  prp = buf.parseProperties
  brs = buf.parseBrushes
  # Add the fields
  result.id         = id
  result.typ        = typ
  result.properties = prp
  result.brushes    = brs

#............................
#............................
proc parseEntities(lbuf :seq[string]) :seq[Entity]= 
  let blocks = parseBlocks(lbuf)
  for it in blocks:
    result.add(parseEnt(it))

#....................
const kClassname  = "classname"
const kWorldspawn = "worldspawn"
const kOrigin     = "origin"
#..........
func getClass(ent :Entity) :string= 
  for key, val in ent.properties:
    if key in [kClassname]: result = val; break
#..........
const pOrigin = "$s$f$s$f$s$f"
#..........
func parseOrigin(val :string) :V3=
  if val.scanf(pOrigin, result.x, result.y, result.z): return
#..........
func getOrigin(ent :Entity) :V3=
  for key, val in ent.properties:
    if key in [kOrigin]: result = val.parseOrigin; break
#....................
type EntityWorld = object
  brushes    :seq[Brush]
#..........
type EntityOther = object
  id         :int
  class      :string
  origin     :V3
  properties :Properties
  brushes    :seq[Brush]
#..........
func toOther(ent :Entity) :EntityOther=
  # Create properties buffer, and remove object duplicates
  var prp = ent.properties
  prp.del(kClassname)
  prp.del(kOrigin)
  # Add all fields
  result.id         = ent.id
  result.class      = ent.getClass
  result.origin     = ent.getOrigin
  result.properties = prp
  result.brushes    = ent.brushes
#..........
#....................
func getWorldAndOthers(ent :seq[Entity]) :tuple=
  var world :EntityWorld
  var other :seq[EntityOther]
  for it in ent:
    if it.getClass in [kWorldspawn]:
      world.brushes &= it.brushes
    else: 
      other.add(it.toOther)
  return (world, other)
#..........
func getAllBrushes(ent :seq[Entity]) :seq[Brush]=
  var world :EntityWorld
  var other :seq[EntityOther]
  (world, other) = getWorldAndOthers(ent)
  result &= world.brushes
  for it in other: result &= it.brushes
#..........

#............................
type Map * = object
  format   *:string
  game     *:string
  brushes  *:EntityWorld
  ents     *:seq[EntityOther]
  # properties :Properties  #TODO
#..........
proc mapToLines(file :string) :seq[string]=
  for line in file.lines:
    result.add(line)
#..........
proc parseMap*(file :string) :Map=
  let mapl       = file.mapToLines
  result.format  = mapl.parseFormat
  result.game    = mapl.parseGame
  var allEnts    = mapl.parseEntities
  (result.brushes, result.ents) = allEnts.getWorldAndOthers
#..........
func `$`*(e :EntityWorld) :string= discard
#..........
func `$`*(m :Map) :string=
  for name, value in m.fieldPairs:
    when name in ["format"]: result.add("Format:\t" & value & "\n")
    when name in ["game"]:   result.add("Game:\t" & value & "\n")
    when name in ["brushes"]:
      for it in value.brushes: result.add($it)
    when name in ["ents"]:
      for it in value: result.add($it)

