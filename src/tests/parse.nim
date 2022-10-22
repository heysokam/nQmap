import ../parse
import ../tools

#............................
func testFace()=
  const someT = " ( 1.6 -64 -16 ) ( -16 -63 -16 ) ( -16 -64 -15 ) __TB_empty/folder/texture [  0 -1  0 -0 ] [  0  0 -1 -0 ] -0  1  1"
  var face = someT.parseFace
  echod &"TestFace:   {face.p1.x} {face.p1.y} {face.tex.name} {face.tex.tm1.offset} {face.tex.scale.y}"
#............................


#............................
func testProperty()=
  const someT = "  \"classname\"   \"worldspawn\"   "
  var temp = someT.parseProperty
  echod temp
#............................


#............................
proc run()=
  lineSep()
  const mapFile = "./simple.map"
  # for line in lines(mapFile): echo line
  lineSep()
  let map = parseMap(mapFile)
  echo map.format
  echo map.game
  lineSep()
  echo "texture = ", map.ents[2].brushes[0].faces[0].tex.name
  echo $map
  lineSep()
  var lbuf :seq[string]
  for line in mapFile.lines:
    lbuf.add(line)
#............................
when isMainModule: run()

