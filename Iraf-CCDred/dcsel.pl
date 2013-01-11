#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: dcsel
#Version: 1.0.1
# ****Should add a routine to check if the sky images have been pre-processed.
#
# Manage the selection of blank sky images to use to calculate the
# DC sky level for each target images.
#
# Usage: dcsel.pl images -o dcselfile --inst=instrument --datadir=datadir
#
#	images: 	Target images
#	-o dcselfile:	Output file with info on which sky to use for each img.
#
# Needs:
#   %%%/astro/labrie/progc/img/fits/getkeyval%%%
#

use FileHandle;
use Time::Local;
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use Img::Header;

#Definitions
$HAPPY = 1;
$NOTHAPPY = 0;
$TSTRING = 16;
$getkeyval = $CCDred::getkeyval;

#Defaults
$FMT = $Header::CFHT::DATE_FMT;
$PTRN = $Header::CFHT::DATE_PTRN;
$TKEY = $Header::CFHT::LOCALTIME_KEY;
$FKEY = $Header::CFHT::FILTER_KEY;
$userParam{'datadir'}='.';

#Initialise
@images = ();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
   if ( /-o/ ) { $output = shift @ARGV; last SWITCH; }
   if ( /--/ ) { 
     s/--//;
     if (/=/) { ($key, $value) = split /=/; }
     else	{ $key = $_; $value = 1; }
     $userParam{$key} = $value;
     last SWITCH;
   }
   push @images, $_;
  }
}

if ($#images < 0) {
  die "ERROR: No input images.\n";
}
if (not defined $output) {
  die "ERROR: No output file specified.\n";
}
if (defined $userParam{'inst'}) {
  SWITCH: {
    if ($userParam{'inst'} eq 'aobir') { 
    		$FMT = $CFHT_FMT;
		$TKEY = $CFHT_TKEY;
		$PTRN = $CFHT_PTRN;
		last SWITCH;
    }
    # unknown instrument 
    die "ERROR: Time format for $userParam{'inst'} has not been implemented.\n";
  }
}

#Build the database
%list = ();
print "Enter the name of the sky image(s) (separated by a coma) for :\n";
foreach $image (@images) {
  $FLAG = $NOTHAPPY;
  #Get filter and time
  $imgFilter = Header::getkeyval($FKEY,'string',$image);
  $imgTime = Header::getTime($TKEY,$FMT,$PTRN,$image);	# in sec since 1 jan 70
  while ( $FLAG == $NOTHAPPY )  {
    print "${image}: ";
    $userInput = <STDIN>;
    $userInput =~ s/\s|\n//g;
    @skyImages = split /,/, $userInput;
    #make sure all sky images do exist
    $FLAG = $HAPPY;
    foreach $skyImage (@skyImages) {
      unless ( -e "$userParam{'datadir'}/$skyImage" ) {
        print "WARNING: $userParam{'datadir'}/$skyImage cannot be found!\n";
	 print "\tTry again\n";
	 $FLAG = $NOTHAPPY;
      }
    }
    next if ($FLAG == $NOTHAPPY);
    #calculate deltaT and get filter
    foreach $skyImage( @skyImages ) {
      $skyFilter = Header::getkeyval($FKEY,'string',"$userParam{'datadir'}/$skyImage");
      $skyTime = Header::getTime($TKEY,$FMT,$PTRN,"$userParam{'datadir'}/$skyImage");	
      $deltaT = abs($imgTime - $skyTime) / 60.;
      $deltaT =~ s/(\d*)\.(\d{2})\d*/$1.$2/;
      if ($imgFilter ne $skyFilter) {
        print "********  WARNING: Filters do not match. *********\n";
      }
      print "$skyImage: $deltaT minutes from $image.\n";
    }
    #Happy?
    print "Happy with current selection? (y/n): ";
    $happy = <STDIN>;
    if (lc($happy) =~ /^y/) { $FLAG=$HAPPY; }
    else { $FLAG=$NOTHAPPY; }
  }
  foreach $skyImage (@skyImages) { 
    $skyImage = "$userParam{'datadir'}/$skyImage";
    $skyImage =~ s/\/\//\//;
  }
  push @{ $list{$image} }, @skyImages;
}

#Write the database to file
$db = new FileHandle ">>$output";
$"=',';
foreach $image (sort keys %list) {
  print $db "$image\:\:@{ $list{$image} }\n";
}
$"=' ';
$db->close();

exit(0);

