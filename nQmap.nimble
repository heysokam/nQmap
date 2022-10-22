#......................
version       = "0.00a"
author        = "sOkam!"
description   = "Quake Map tools for Nim"
license       = "GPL3 or higher"   # Ask for MIT if you need it
#......................
let shortname = "nQmap"

#......................
# Dependencies
requires "nim   >= 1.6.8" # Set to current 2022 version, without explicit needs for this version
requires "vmath"          # Pure Nim vector math. Didn't like glm much when I tried it
#
#......................
# Folder config
srcDir = "src"
binDir = "bin"

#......................
# Binaries
namedBin[shortname] = "nQmap"  # Compiles "".nim from srcDir as shortname

#......................
before build: echo shortname,": Building ",description," | v",version
after  build: echo shortname,": Done building."
