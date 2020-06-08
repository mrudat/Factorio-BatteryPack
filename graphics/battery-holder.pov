#version 3.7;
#include "graphics/common.inc"
#include "graphics/battery-holder-frame.inc"
#include "graphics/battery-contact.inc"

#if(TechnologyRotation)
  #declare scene_transform = transform {
    scale 0.75
    rotate <0,0,45>
    translate <2,-8,0>
  }
#else
  #declare scene_transform = transform {
    scale 0.8
    rotate <0,0,90>
    translate <0,-8,0>
  }
#end

object {
  battery_holder_frame
  transform { scene_transform }
  #if ((Variant = VARIANT_BKG) | (Variant = VARIANT_SHADOW))
    no_image
  #end
}

object {
  battery_contact
  scale 0.6
  rotate <0,0,45>
  rotate <0,0,180>
  rotate <90,0,0>
  translate <-20,18,11>
  transform { scene_transform }
  #if ((Variant = VARIANT_BKG) | (Variant = VARIANT_SHADOW))
    no_image
  #end
}
//
object {
  battery_contact
  scale 0.6
  rotate <0,0,45>
  rotate <0,0,180>
  rotate <90,0,0>
  translate <20,18,11>
  transform { scene_transform }
  #if ((Variant = VARIANT_BKG) | (Variant = VARIANT_SHADOW))
    no_image
  #end
}

sphere_sweep {
  cubic_spline
  9,
  <-20,  0, 20>, 1
  <-20, 20, 20>, 1
  <-22, 22,  6>, 1
  <-32, 22,  5>, 1
  <-28, 12,  5>, 1
  <  0,-10,  5>, 1
  < 10,  0,  5>, 1
  <  0, 10,  5>, 1
  <-10,  0,  5>, 1
  material {
    texture {
      pigment { 
        rgb <0.0,1.0,0,0>
      }
      finish {
        ambient 0
        diffuse 0.6
        specular 0.5
        roughness 0.05
      }
    }
  }
  transform { scene_transform }
  #if (NoImage)
    no_image
  #end
}

sphere_sweep {
  cubic_spline
  10,
  < 20,  0, 20>, 1
  < 20, 20, 20>, 1
  < 10, 22,  5>, 1
  <-22, 22,  3>, 1
  <-32, 22,  3>, 1
  <-28, 12,  3>, 1
  <  0,-10,  3>, 1
  < 10,  0,  3>, 1
  <  0, 10,  3>, 1
  <-10,  0,  3>, 1
  material {
    texture {
      pigment { 
        rgb <1.0,0.0,0,0>
      }
      finish {
        ambient 0
        diffuse 0.6
        specular 0.5
        roughness 0.05
      }
    }
  }
  transform { scene_transform }
  #if (NoImage)
    no_image
  #end
}

sphere {
  <0, 0, 0>, 1.4 // <x, y, z>, radius
  texture { T_Chrome_3A }
  translate <0,0,1>
  translate <-20,18,20>
  transform { scene_transform }
  #if (NoImage)
    no_image
  #end
}

sphere {
  <0, 0, 0>, 1.4 // <x, y, z>, radius
  texture { T_Chrome_3A }
  translate <0,0,1>
  translate <20,18,20>
  transform { scene_transform }
  #if (NoImage)
    no_image
  #end
}
