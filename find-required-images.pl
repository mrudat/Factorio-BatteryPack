#!/usr/bin/env perl

use warnings;
use strict;

my $images;

while (<>) {
  chomp;
  next unless m/\.png/;
  next if m/(?:__|--)/;
  s/^.* \.\. //;
  s/(["'])([^"]+)\1,?/$2/;
  if (m/^entity/) {
    next if m{-shadow\.}; # created as side effect of rendering an entity.
    next if m{-reflection\.}; # created as side effect of rendering an entity.
  }
  $images->{$_}++;
}

foreach my $image (keys %$images) {
  my $source = $image;
  $source =~ s{^.*/}{};
  $source =~ s/\.png/.pov/;
  $source = "graphics/$source";
  my $target = "graphics/$image";
  if (-f $source) {
    print "$target\n"
  }
}