#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: ccdhedit
#Version: 1.0.1
#
# Edit image header.  Accesses IRAF's ccdhedit routine.
#
# Command-line arguments : (images/-l list) keyword value paramType 
#				--inst=instrument
#
#	images		: List of images
#	-l list	: Name of the file containing the list of images
#	keyword	: Header keyword to edit
#	value		: New value
#	paramType	: Variable type of value ('string', 'real', or 'integer')
#
# Needs:
#   %%%IRAF%%%
#   %%%Iraf.pm%%%

use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::CCDred;

my ($image);

#Set defaults
$setFile="$HOME/iraf/privuparm/setinst.par";
$imtype=$CCDred::imtype;

#Initialise variables
@listOfImages = ();
@otherArgv = ();

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) { $list = shift @ARGV; last SWITCH; }
    if ( /--/ ) {
      s/--//;
      if (/=/) { ($key,$value) = split /=/; }
      else     { $key = $_; $value = 1; }
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;
    push @otherArgv, $_;
  }
}

#Read setinst.par
if (defined $moreParam{'inst'}) { $setFile .= ".$moreParam{'inst'}"; }
$paramFile = Iraf::whereParam($setFile);

#Read project's .cl file
%allParam = Iraf::getParam($paramFile,'=');
foreach $key (keys %moreParam) { $allParam{$key} = $moreParam{$key}; }

#Extract images, keyword, value and paramType form @otherArgv
# 'keyword', 'value' and 'paramType' should be the 3 last elements of @otherArgv
$allParam{'paramType'} = pop @otherArgv;
$allParam{'value'} = pop @otherArgv;
$allParam{'keyword'} = pop @otherArgv;
if ($#otherArgv >= 0) {push @listOfImages, @otherArgv;}

#Read the file with the list of images
if ($list) {
  open(LIST,"<$list") or die "Cannot open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
  close(LIST);
}

#Add the appropriate image type to the images' name
foreach $image (@listOfImages) {$image .= '.'.$imtype;}

#Edit header
CCDred::ccdhedit(\%allParam,@listOfImages);

exit(0);

