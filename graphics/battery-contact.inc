#include "metals.inc"

#local spring_height = 9;

// each entry is a full revolution.
#local spring_data = array[spring_height][2] {
  { 0,  3},
  { 0,  5},
  { 0,  5},
  { 2, 10},
  { 5, 10},
  {10,  8},
  {15,  6}
  {20,  5}
  {20,  3}
}

#declare battery_contact = union {
  difference {
    merge {
      cylinder {
        <0, 0, 0>, <0, 0, 0.5>, 10
      }
      box {
        <-2.5, -20, 0>, <2.5, 0, 0.5>
        rotate <0,0,-45>
      }
      cylinder {
        <0, 0, 0>, <0, 0, 0.5>, 2.5
        translate <0,-20,0>
        rotate <0,0,-45>
      }
    }
    cylinder {
      <0, 0, -1>, <0, 0, 1.5>, 1
      translate <0,-20,0>
      rotate <0,0,-45>
    }
    cylinder {
      <0, 0, -1>, <0, 0, 1.5>, 3
    }
  }

  sphere_sweep {
    cubic_spline
    (spring_height-1)*8,
    #for(i,0,spring_height - 2)
      #local h1 = spring_data[i][0];
      #local r1 = spring_data[i][1];
      #local h2 = spring_data[i+1][0];
      #local r2 = spring_data[i+1][1];
      #for(j,1,8)
        #local frac = j/8;
        #local r = r1 + (r2 - r1) * frac;
        #local h = h1 + (h2 - h1) * frac;
        vaxis_rotate(<r,0,h>,z,360 * frac), 0.5
      #end
    #end
  }
  texture { T_Chrome_4C }
  translate <0,0,1>
}
