#version 3.7;
#include "graphics/common.inc"
#include "graphics/battery-holder-frame.inc"

#declare scene_transform = transform {
  scale 0.8
  rotate <0,0,90>
  translate <0,-8,0>
}

object {
  battery_holder_frame
  transform { scene_transform }
  #if ((Variant = VARIANT_BKG) | (Variant = VARIANT_SHADOW))
    no_image
  #end
}
