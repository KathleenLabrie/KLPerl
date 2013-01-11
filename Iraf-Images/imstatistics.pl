#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imstatistic_sub
#Version: 1.0.0
#
#Usage : imstatistic_sub list_of_images --fields=fields

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#**** WARNING ****
$"=',';
#**** WARNING ****

$moreParam{'lower'} = 'INDEF';
$moreParam{'upper'} = 'INDEF';
$moreParam{'binwidth'} = '0.1';
$moreParam{'format'} = 'yes';

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /--/ ) {
      s/--//;
      if (/=/) { ($key,$value) = split /=/; }
      else     { $key = $_; $value = 1;     }
      $moreParam{$key} = $value;
      last SWITCH;
    }
    push @listOfImages, $_;
  }
}
    
Images::imstatistics(\%moreParam,@listOfImages);

exit(0);
