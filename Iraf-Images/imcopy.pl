#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imcopy
#Version: 0.1.0
#  Copy an image section.
#
#Usage: img1 img2 [--section=[x1:x2,y1:y2]]
#
#	img1 	  : Input image
#	img2 	  : Output image
#	--section : Section of the input image to extract
#

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#**** WARNING ****
$"=',';
#**** WARNING ****

#Set defaults
@listOfImages=();
$imtype=$Images::imtype;
$moreParam{'section'}="";
$moreParam{'verbose'}='yes';

$|=1;		#OUTPUT_AUTOFLUSH ON

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /--/ ) {
      s/--//;
      ($key,$value) = split /=/;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;		# img.fits -> img
    push @listOfImages, $_;
  }
}

#Add section
$listOfImages[0] .= $moreParam{'section'};

#Insert the right image type extension for the output image
$listOfImages[1] .= '.'.$imtype;

#Copy image
Images::imcopy(\%moreParam,$listOfImages[0],$listOfImages[1]);
$|=0;		#OUTPUT_AUTOFLUSH OFF

exit(0);
