#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: ccdlist
#Version: 1.1.2
#
#Command-line : (images|-l list) --ccdtype=ccdtype  --quiet --inst=instrument
#
#Needs:
#  %%% /astro/labrie/progp/iraf/ccdred/ccdlist-sub.pl %%%

use FileHandle;
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

#Set defaults
$ccdlist=$CCDred::ccdlist_sub;
$regexp = '(> \n)|((> )+(\w+: )+)';
$imtype=$CCDred::imtype;

#Initialise variables
@listOfImages = ();
$moreParam{'quiet'}=0;
$options='';

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ )  {
      s/--//;
      if (/=/) { 
        ($key,$value) = split /=/;
        $moreParam{$key} = $value;
      }
      else { $moreParam{$_} = 1; }
      last SWITCH;
    }
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if ($list) {
  $fhrdList = new FileHandle "<$list";
  while (<$fhrdList>) {
    s/\n//;
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
  $fhrdList->close();
}

#Check for imtype extension and put the right one
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

#List information
if ($moreParam{'quiet'}) { $options .= ' --quiet'; }
if (defined $moreParam{'inst'}) { $options .= " --inst=$moreParam{'inst'}"};
$fhChild = new FileHandle "$ccdlist @listOfImages $options|" or
		die "Can't open pipe from $ccdlist\n";
while (<$fhChild>) {
  if (defined $moreParam{'ccdtype'}) {
    next unless (/$moreParam{'ccdtype'}/);
  }
  s/$regexp//;
  print;
}
$fhChild->close();

exit(0);
