#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: ccdlist-sub
#Version: 1.1.2
#
#Command-line : images --quiet --inst=instrument

use FileHandle;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

#Set defaults
$setFile="$HOME/iraf/privuparm/setinst.par";
$imtype=$CCDred::imtype;

#Defaults for ccdlist
$moreParam{'ccdtype'}='';
$moreParam{'names'}='no';
$moreParam{'long'}='no';

#Initialise variables
@listOfImages = ();
$moreParam{'quiet'}=0;

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      if ( /=/ ) { ($key, $value) = split /=/; }
      else { $key = $_; $value = 1;}
      $moreParam{$key} = $value;
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
#Also check that the image actually exists
@finalList=();
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
  if (-e $image) { push @finalList, $image; }
  else {
    unless ($moreParam{'quiet'}) { warn "$image not found.\n"; }
  }
}

#Read setinst.par
if (defined $moreParam{'inst'}) {$setFile .= ".$moreParam{'inst'}";}
$paramFile = Iraf::whereParam($setFile);

#Read project's .cl file
%allParam = Iraf::getParam($paramFile,'=');
foreach $key (keys %moreParam) { $allParam{$key}=$moreParam{$key}; }

#List information
CCDred::ccdlist(\%allParam,@finalList);

exit(0);
