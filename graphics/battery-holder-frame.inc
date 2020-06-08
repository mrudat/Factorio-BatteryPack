#version 3.7;
#include "shapes.inc"

#local plastic = material {
  texture {
    pigment {
      rgb 0.1
    }
    normal {
      bumps 0.25
    }
    finish {
      ambient 0
      diffuse 0.6
      specular 0.5
      roughness 0.05
    }
  }
}

// box height, width, depth
#local bw = 60; // x
#local bh = 40; // y
#local bd = 20; // z

#local bt = 2; // box thicknes
#local er = bt/2; // edge radius

#local td = 40; // terminal distance

#local sl = 20; // side length
#local sh = bd/2; // side height

#local lw = 20; // lip width
#local bl = 30; // bottom length

#declare battery_holder_frame = difference {
  merge {
    object { Round_Box_Merge(<    -bw/2,     -bh/2,     0>, <    bw/2,        bh/2,    bt>, er) } // back
    object { Round_Box_Merge(<    -bw/2, (bh/2)-bt,     0>, <    bw/2,        bh/2,    bd>, er) } // top
    object { Round_Box_Merge(<    -bw/2,     -sl/2,     0>, <-bw/2+bt,        sl/2,    sh>, er) } // side 1
    object { Round_Box_Merge(<(bw/2)-bt,     -sl/2,     0>, <    bw/2,        sl/2,    sh>, er) } // side 2
    object { Round_Box_Merge(<    -bl/2,     -bh/2,     0>, <    bl/2,    -bh/2+bt,    bd>, er) } // bottom
    object { Round_Box_Merge(<    -lw/2,     -bh/2, bd-er>, <    lw/2,-bh/2+(bt*2),    bd>, er) } // bottom lip
  }
  // mounting holes.
  cylinder { <-td/2, bh/2+1, bd/2>, <-td/2, bh/2-bt-1, bd/2>, 2 }
  cylinder { < td/2, bh/2+1, bd/2>, < td/2, bh/2-bt-1, bd/2>, 2 }
  material { plastic }
}
