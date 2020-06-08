#declare VARIANT_TEST=0;    // normal render (for testing)

// for icon
#declare VARIANT_ICON=7;   // alpha render (for foreground)

// for technology - different rotation
#declare VARIANT_ALPHA=1;   // alpha render (for foreground)
#declare VARIANT_BKG=2;     // background render (for shadow color)
#declare VARIANT_SHADOW=3;  // shadow render (for shadow shape)

// for entity - different lighting
#declare VARIANT_ALPHA2=4;   // alpha render (for foreground)
#declare VARIANT_BKG2=5;     // background render (for shadow color)
#declare VARIANT_SHADOW2=6;  // shadow render (for shadow shape)

#ifndef (Variant)
  #declare Variant=VARIANT_TEST;
#end

// hide foreground to capture shadow.
#switch (Variant)
  #case (VARIANT_BKG)
  #case (VARIANT_BKG2)
  #case (VARIANT_SHADOW)
  #case (VARIANT_SHADOW2)
    #declare NoImage=1;
  #break
  #else
    #declare NoImage=0;
#end

// radiosity only for foreground
// hide background to capture foreground.
#switch (Variant)
  #case (VARIANT_ICON)
  #case (VARIANT_ALPHA)
  #case (VARIANT_ALPHA2)
    #declare Radiosity=1;
    #declare NoPlane=1;
  #break
  #else
    #declare Radiosity=0;
    #declare NoPlane=0;
#end

// alternate rotation to show off technology.
#switch (Variant)
  #case (VARIANT_ALPHA)
  #case (VARIANT_BKG)
  #case (VARIANT_SHADOW)
    #declare TechnologyRotation=1;
  #break
  #else
    #declare TechnologyRotation=0;
#end

global_settings{
  assumed_gamma 1.0
  #if (Radiosity)
    radiosity {}
  #end
}

camera {
  orthographic
  location <0,-1,1> * 50
  right x*image_width/image_height
  look_at  <0,0,0>
  angle 45
}

// alternate lighting for entity shadows.
#switch (Variant)
  #case (VARIANT_ALPHA) // technology
  #case (VARIANT_BKG)
  #case (VARIANT_SHADOW)
    light_source {
      <0,0,2> * 100
      color <1.0, 1.0, 1.0>
      parallel
      point_at <0,0,0>
      area_light x*10, y*10, 4, 4
      adaptive 0
      circular
      rotate <5,0,0>
    }
  #break
  #case (VARIANT_ALPHA2) // entity
  #case (VARIANT_BKG2)
  #case (VARIANT_SHADOW2)
    light_source {
      <0,0,2> * 100
      color <1.0, 1.0, 1.0>
      parallel
      point_at <0,0,0>
      area_light x*10, y*10, 4, 4
      adaptive 0
      circular
      rotate <0,45,0>
    }
  #break
  #else // item
    light_source {
      <0,0,2> * 100
      color <1.0, 1.0, 1.0>
      parallel
      point_at <0,0,0>
      area_light x*10, y*10, 4, 4
      adaptive 0
      circular
      rotate <5,0,0>
    }
#end

plane {
  z, 0
  texture {
    pigment {
      rgb 1
    }
    #switch (Variant)
      #case (VARIANT_TEST)
        finish { ambient 0 diffuse 0.5 }
      #break
      #case (VARIANT_ALPHA)
      #case (VARIANT_ALPHA2)
        finish { ambient 0 diffuse 0.5 }
      #break
      #case (VARIANT_BKG)
      #case (VARIANT_BKG2)
        finish { ambient 0 diffuse 0.25 }
      #break
      #case (VARIANT_SHADOW)
      #case (VARIANT_SHADOW2)
        finish { ambient 0.05 diffuse 1.05 }
      #break
    #end
  }
  #if (NoPlane)
    no_image
  #end
}
