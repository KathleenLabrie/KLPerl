#!/usr/local/bin/perl -w
#
#Package: Iraf::Images		#doesn't really belong here
#Name: thumbnail
#Version: 0.1.0
#  Get thumbnails.  Rotate is an option
#
#Usage: thumbnail.pl masterimg thumbimg x0 y0 wx wy [--rotation=angle]
#       thumbnail.pl masterimg thumbimg -c coofile wx wy [--rotation=angle]
#
#	masterimg	: Master image
#	thumbimg	: Thumbnail
#	x0,y0		: Center of the section to extract
#	wx,wy		: Width of the section to extract
#	-c coofile	: Name of the coordinate file
#	--rotate=angle	: Rotate thumbnail by <angle> degres counter-clockwise
#

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#**** WARNING ****
$"=',';
#**** WARNING ****

#Set defaults
$rotate = $Images::rotate;
$imcopy = $Images::imcopy;
@otherArgs=();
$imtype=$Images::imtype;
$moreParam{'rotation'} = 0.;

$|=1;		#OUTPUT_AUTOFLUSH ON

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^--/ ) {
      s/^--//;
      ($key,$value) = split /=/;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    if ( /^-/ ) {
      if ( /^-c/ ) { $moreParam{'coofile'} = shift @ARGV; }
      else {print "ERROR: Unknown option ($_)\n"; die;}
      last SWITCH;
    }
    s/\.fits$|\.imh$//;		# img.fits -> img
    push @otherArgs, $_;
  }
}

$moreParam{'masterimg'} = $otherArgs[0].'.'.$imtype;
$moreParam{'thumbimg'} = $otherArgs[1].'.'.$imtype;
if (defined $moreParam{'coofile'}) {
   $moreParam{'wx'}=$otherArgs[2];
   $moreParam{'wy'}=$otherArgs[3];
   open (COO, "<$moreParam{'coofile'}") or 
   		die "Unable to open $moreParam{'coofile'} for reading.\n";
   $line = <COO>;
   close(COO);
   $line =~ s/\n//;
   ($moreParam{'x0'},$moreParam{'y0'}) = split /\s+/,$line;
} else {
   $moreParam{'x0'}=$otherArgs[2];
   $moreParam{'y0'}=$otherArgs[3];
   $moreParam{'wx'}=$otherArgs[4];
   $moreParam{'wy'}=$otherArgs[5];
}

#Calculate section
$moreParam{'x0'} = int $moreParam{'x0'};
$moreParam{'y0'} = int $moreParam{'y0'};
$x1 = $moreParam{'x0'} - int($moreParam{'wx'}/2);
$x2 = $moreParam{'x0'} + int($moreParam{'wx'}/2);
$y1 = $moreParam{'y0'} - int($moreParam{'wy'}/2);
$y2 = $moreParam{'y0'} + int($moreParam{'wy'}/2);
$section = "[$x1:$x2,$y1:$y2]";

if ($moreParam{'rotation'} != 0.) { $outimg = "scratch.fits"; }
else { $outimg = $moreParam{'thumbimg'}; }

$command = "$imcopy $moreParam{'masterimg'} $outimg --section='$section'";
system ("$command");

if ($moreParam{'rotation'} != 0.) {
  $command = "$rotate $outimg $moreParam{'thumbimg'} $moreParam{'rotation'}";
  system ("$command");
  system ("\\rm -f scratch.fits");
}

$|=0;		#OUTPUT_AUTOFLUSH OFF

exit(0);
