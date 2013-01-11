#!/usr/local/bin/perl -w
#
#Package: Iraf::System
#Name: dellist
#Version: 1.0.0
#
#******** IRAF ********
#Delete files listed in a file named on the command line
# A file extension, to be added to the file names in the list,
# can be specified.
#
#Command-line arguments : delList fextn
#	delList : Name of the file containing all the name of the files
#		    to delete.
#	fextn   : File extension to be appended to the file names.
#
#Needs:

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::System;

# Read command-line arguments
$delList = shift @ARGV;
unless (defined ($fextn = shift @ARGV)) {$fextn = '';}

#Set other defaults
$moreParam{'verify'}='no';
$moreParam{'allVersion'}='yes';
$moreParam{'subFiles'}='yes';

# Open delList and delete the files
open (DELLIST,"<$delList") or die "Can't open $delList for reading.\n";
while (<DELLIST>) {
  next if ( /^#/ );
  s/\n//;
  $file=$_.$fextn;
  System::delete(\%moreParam,$file);
}
close (DELLIST);

exit(0);
