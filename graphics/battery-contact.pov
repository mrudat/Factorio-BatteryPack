#version 3.7;
#include "graphics/common.inc"
#include "graphics/battery-contact.inc"

#declare scene_transform = transform {
  scale 1.6
  translate <2,-8,0>
}

object {
  battery_contact
  transform { scene_transform }
  #if ((Variant = VARIANT_BKG) | (Variant = VARIANT_SHADOW))
    no_image
  #end
}
