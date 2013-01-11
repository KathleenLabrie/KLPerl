#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imstatsel
#Version: 1.0.0
#
#******** IRAF ********
#Delete images listed in a file named on the command line
# An image name extension, to be added to the image names in the list,
# can be specified.
#
#Command-line arguments : delList fextn
#	delList : Name of the file containing all the name of the images
#		    to delete.
#	fextn   : File extension to be appended to the image names.
#
#Needs:


use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

# Read command-line arguments
$imdelList = shift @ARGV;
unless (defined ($fextn = shift @ARGV)) {$fextn = '';}

#Set other defaults
$moreParam{'verify'}='no';

# Open delList and delete the files
open (IMDELLIST,"<$imdelList") or die "Can't open $imdelList for reading.\n";
while (<IMDELLIST>) {
  next if ( /^#/ );
  s/\n//;
  $image=$_.$fextn;
  Images::imdelete(\%moreParam,$image);
}
close (IMDELLIST);

exit(0);
