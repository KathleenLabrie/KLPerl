#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: hselect
#Version: 1.0.0
#  Select a subset of images satisfying a boolean expression
#
#Command-line: images/-l list --fields='field1..fieldN' --expr='expresion'
#
#	images				: Set of images
#	-l list			: File with the list of images.
#	--fields='field1..fieldN'	: List of output fields ('$I' for image name)
#	--expr'expression'		: Boolean expression
#					  (eg. 'OBSTYPE == "Skycalib"')

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#Set defaults
$imtype=$Images::imtype;

#Initialse variables
@listOfImages=();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
    	s/--//;
	($key,$value) = split /=/, $_, 2;
	$moreParam{$key} = $value;
	last SWITCH;
    }
    s/\.fits$|\.imh//;	# img.fits -> img
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if (defined $list) {
  open(LIST,"<$list") or die "Cannot open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;	#img.fits -> img
    push @listOfImages, $_;
  }
  close(LIST);
}

#Insert the right image type extension
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

#Select
Images::hselect(\%moreParam,@listOfImages);

exit(0);
