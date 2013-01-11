#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: rotate
#Version: 0.1.0
#  Rotate an image
#
#Usage: rotate.pl inimg outimg angle
#
#	inimg	: Input image
#	outimg	: Output image
#	angle	: Rotation angle (+ counter-clockwise; - clockwise)
#

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#**** WARNING ****
$"=',';
#**** WARNING ****

#Set defaults
@otherArgs=();
$imtype=$Images::imtype;
$moreParam{'rotation'}=0;
$moreParam{'xin'}='INDEF';
$moreParam{'yin'}='INDEF';
$moreParam{'xout'}='INDEF';
$moreParam{'yout'}='INDEF';
$moreParam{'ncols'}='INDEF';
$moreParam{'nlines'}='INDEF';
$moreParam{'interpo'}='linear';
$moreParam{'boundar'}='nearest';
$moreParam{'constan'}=0.;
$moreParam{'nxblock'}=512;
$moreParam{'nyblock'}=512;
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
    push @otherArgs, $_;
  }
}

$moreParam{'input'} = $otherArgs[0].'.'.$imtype;
$moreParam{'output'} = $otherArgs[1].'.'.$imtype;
$moreParam{'rotation'} = $otherArgs[2];

#Rotate
Images::rotate(\%moreParam);
$|=0;		#OUTPUT_AUTOFLUSH OFF

exit(0);
