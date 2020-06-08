#!/usr/bin/env perl

use autodie qw(open);

my $files;

foreach (@ARGV) {
  my $png = $_;
  if (s{graphics/(icons|technology|entity)/}{graphics/}i) {
    my $match = $1;
    if ($match == "entity") {
      next if m/-(?:shadow|reflection)\.png$/i;
    }
  } else {
    next;
  }
  next unless s/\.png$/.pov/i;
  push @{$files->{$_}}, $png;
}

my @files = keys %$files;

my $seen;

my $deps;
my $incs;

while (my $file = shift @files) {
  next unless -r $file;
  open my $fh, "<", $file;
  while (<$fh>) {
    if (m/#include "(.*)"/) {
      my $inc = $1;
      if (!$seen{$inc}) {
        push @files, $inc;
        $seen{$inc}++;
      }
      next unless -r $inc;
      $deps->{$file}{$inc} = 1;
    }
  }
  close($fh);
}

foreach my $file (keys %$deps) {
  my $deplist = join(" ", sort keys %{$deps->{$file}});
  for my $png (@{$files->{$file}}) {
    print "\$(OUTPUT_DIR)/$png: $deplist\n";
  }
}
