#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: median
#Version: 1.0.0
#   Median filter an image.
#
#Command-line : inputImage outputImage --xbox=dx --ybox=dy (--zlo=lo --zhi=hi)

use lib qw(/home/labrie/prgp/include);		#prepend the dir to @INC
use Iraf::Images;

#Set defaults
$imtype=$Images::imtype;
$moreParam{'zlo'}='INDEF';
$moreParam{'zhi'}='INDEF';
$moreParam{'boundary'} = 'nearest';
$moreParam{'constant'} = '0.';
$moreParam{'verbose'} = 'yes';

#Initialise variables
@imageNames = ();

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /--/ ) {
      s/--//;
      ($key,$value) = split /=/;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/(.fits|.imh)$//;
    $_ .= '.'.$imtype;
    push @imageNames, $_;
  }
}

#Calculate median
Images::median(\%moreParam,@imageNames);

exit(0);

