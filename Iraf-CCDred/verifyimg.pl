#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: verifyimg
#Version: 1.2.3
#
# Verification of image header and identification of the processing steps
# needed.
#
# Command-line arguments : images -o output --inst=instrument
#	images    : list of images to verify.
#	-o output : Name of the output file.  This file will contain the 
#			information concerning the processing steps required for
#			each image.  Format : imageName [abmotzdf bit-format Hex]
#
#Needs :
#   %%%Iraf::Tv%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdlist.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdhedit.pl%%%
# %%%/astro/labrie/progp/iraf/tv/display.pl%%%

use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use Iraf::Tv;

#Definitions
 $NONE		= 0;	# x = 0;
 $OVERSCAN 	= 1;	# o = 1 << 0;
 $TRIM		= 2;	# t = 1 << 1;
 $ZEROCOR	= 4;	# z = 1 << 2;
 $DARKCOR	= 8;	# d = 1 << 3;
 $FLATCOR	= 16;	# f = 1 << 4;
 $FIXPIX	= 32;	# b = 1 << 5;
 $MOVFIXPIX	= 64;	# m = 1 << 6;
 $DCCOR		= 128;	# c = 1 << 7;
 $SKYCOR	= 256;	# s = 1 << 8;
 $FRINGECOR	= 512;	# g = 1 << 9;
 $ALL		= $OVERSCAN + $TRIM + $ZEROCOR + $DARKCOR + $FLATCOR + $FIXPIX +
 		  $MOVFIXPIX + $DCCOR + $SKYCOR + $FRINGECOR;		
		  	# a = \x1F;
 $UNDO		= 0;	# u = 0;

#Set defaults
$ccdlist = $CCDred::ccdlist;
$ccdhedit = $CCDred::ccdhedit;
$display = $Tv::display;
$imageDisplay = $Tv::imageDisplay;
$output = 'verify.out';
$setFile = "$HOME/iraf/privuparm/setinst.par";
$moreParam{'instrument'}="";

#Initialise
@images = ();

#Start image display
system ("$imageDisplay > /dev/null \&");

#Read-in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-o/ ) { $output = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      if (/=/) { ($key,$value) = split /=/; }
      else     { $key=$_; $value=1; }
      $moreParam{$key} = $value;
      last SWITCH;
    }
    push @images, $_;
  }
}

SWITCH: {
  if ($moreParam{'inst'} eq 'palomar') {$stdimage = 'imt800'; last SWITCH;}
  if ($moreParam{'inst'} eq 'aobir')   {$stdimage = 'imt1024'; last SWITCH;}
  #default
  $stdimage = 'imt512';
}

#Do a listing of all the images (global idea of the type of images)
system "clear";
if (-e "$setFile.$moreParam{'inst'}") {
    system ("$ccdlist @images --inst=$moreParam{'inst'}");
} else {
    system ("$ccdlist @images");
}
#&DoCCDlist(@images);
print '-' x 40;
print "\n";

open (OUTPUT,">>$output") or &ShutdownApp("Cannot open $output for writing.\n");
foreach $image (@images) {
if (-e "$setFile.$moreParam{'inst'}") {
    system ("$ccdlist $image --inst=$moreParam{'inst'}");
} else {
    system ("$ccdlist $image");
}
#  &DoCCDlist($image);
  system("$display $image --stdimage=$stdimage > /dev/null");
  print "  Check ID, image type, and subsets. (? for help; n to continue)\n";
  &CheckHeader ($image,$moreParam{'inst'});
  print "  Identify processing steps needed. (? for help; n to continue)\n";
  &IDProcessingSteps ($image);
}

&ShutdownApp('0');

exit(0);

#-------------------------

#-------------------------\
#      ShutdownApp         \
#---------------------------\
sub ShutdownApp {
  local ($message) = @_;

  close (OUTPUT);
  unless ($message eq '0') {print "$message";}
  &KillProcess($imageDisplay);
  ($message eq '0') ? exit(0) : exit(1);
}

#-------------------------\
#      KillProcess         \
#---------------------------\
use Shell qw(ps);
sub KillProcess {
  local ($process) = @_;
  local (@lines);

  $process = substr $process, 0, 15;
  @lines = grep /$process/, ps ("-x");
  $lines[$#lines] =~ s/\s*(\d+).+\n/$1/;
  kill 9, $lines[$#lines];

  return();
}


# The normal ccdlist does the same thing.  I guess the original
# ccdlist didn't clean up the lines, now it does.
#-------------------------\
#        doCCDlist         \
#---------------------------\
#
#sub DoCCDlist {
#  local (@images) = @_;
#  local ($substr) = '/astro/labrie/progp/general/substr.pl';
#  local ($regexp) = '(> \n)|(> (\w+: )+)';
#
#  if (-e "$setFile.$moreParam{'inst'}") {
#    system ("$ccdlist @images --inst=$moreParam{'inst'} > junk.ccdlist");
#  } else {
#    system ("$ccdlist @images > junk.ccdlist");
#  }
#  system ("$substr junk.ccdlist -o STDOUT \"$regexp\" ''");
#  system ("rm junk.ccdlist");
#
#  return();
#}

#-------------------------\
#       CheckHeader        \
#---------------------------\
sub CheckHeader {
  local ($img,$instrument) = @_;

  print "  > ";
  while ((($_ = <STDIN>) ne "n\n") and ($_ ne "q\n")) {
    s/\n//;
    SWITCH: {
      if ( /^i/ ) 	{&ChangeHeader('  New ID: ','id'); last SWITCH;}
      if ( /^f/ )	{
      		if ($instrument =~ /palomar/) { $fltr = 'filter_pal'; }
		else                          { $fltr = 'filter';     }
		&ChangeHeader('  New Filter: ',$fltr);
		last SWITCH;
      }
      if ( /^s/ )	{&ChangeHeader('  New Subset: ','subset'); last SWITCH;}
      if ( /^t/ )	{&ChangeHeader('  New Image Type: ','type'); last SWITCH;}
      if ( /^\?/ )	{&PrintHelp('CheckHeader'); last SWITCH;}
      print "  $_ is not a valid command.\n";
      &PrintHelp('CheckHeader');
    }
    print "  > ";
  }
  ($_ eq "n\n") ? return() : &ShutdownApp("Exiting.\n");
}

#-------------------------\
#       ChangeHeader       \
#---------------------------\
sub ChangeHeader {
  local ($queryString,$option) = @_;
  local ($paramType) = 'string';

  print "$queryString";
  SWITCH: {
    if ($option eq 'id')         {$keyword = 'OBJECT'; last SWITCH;}
    if ($option eq 'filter')     {$keyword = 'FILTER'; last SWITCH;}
    if ($option eq 'filter_pal') {$keyword = 'FILTER1'; last SWITCH;}
    if ($option eq 'subset')     {$keyword = 'subset'; last SWITCH;}
    if ($option eq 'type')       {$keyword = 'imagetyp'; last SWITCH;}
  }
  $value = <STDIN>;
  $value =~ s/\n//;
  $value =~ s/^'|'$//g;
  if (-e "$setFile.$moreParam{'inst'}") {
    system ("$ccdhedit $img $keyword '$value' $paramType --inst=$moreParam{'inst'} > /dev/null");
  } else {
    system ("$ccdhedit $img $keyword '$value' $paramType > /dev/null");
  }
    
  return();
}

#-------------------------\
#    IDProcessingSteps     \
#---------------------------\
sub IDProcessingSteps {
  local ($img) = @_;
  local ($steps) = 0;

  print "  > ";
  while ((($_ = <STDIN>) ne "n\n") and ($_ ne "q\n")) {
    s/\n//;
    SWITCH: {
      if ( /\?/ )	{&PrintHelp('IDProcessingSteps');            last SWITCH;}
      if ( /a/ )	{$steps  = $ALL;  	print "  All steps\n";  last SWITCH;}
      if ( /u/ )	{$steps  = $UNDO;	print "  No steps\n";   last SWITCH;}
      if ( /x/ )	{$steps  = $NONE;	print "  Needs nothing\n"; last SWITCH;}
      if ( /b|m|o|t|z|d|f|c|s|g/ ) {
	 if ( /b/ )	{$steps |= $FIXPIX;}
	 if ( /m/ )	{$steps |= $MOVFIXPIX;}
	 if ( /o/ )	{$steps |= $OVERSCAN;}
	 if ( /t/ )	{$steps |= $TRIM;}
	 if ( /z/ )	{$steps |= $ZEROCOR;}
	 if ( /d/ )	{$steps |= $DARKCOR;}
	 if ( /f/ )	{$steps |= $FLATCOR;}
	 if ( /c/ )	{$steps |= $DCCOR;}
	 if ( /s/ )	{$steps |= $SKYCOR;}
	 if ( /g/ )	{$steps |= $FRINGECOR;}
	 last SWITCH;
      }
      print "$_ is not a valid command.\n";
      &PrintHelp('IDProcessingSteps');
    }
    print "  > ";
  }
  print OUTPUT "$img\t$steps\n";
  ($_ eq "n\n") ? return() : &ShutdownApp("Exiting.\n");
}

#-------------------------\
#        PrintHelp         \
#---------------------------\
sub PrintHelp {
  local ($sub) = @_;
  local ($checkHeader) = 
	"\ti : Change ID ('OBJECT')\n\tf : Change filter ('FILTER1 Only palomar')\n".
	"\ts : Change subset (subset, i.e. filter)\n\tt : Change image type (imagetyp)\n".
	"\tn : Continue\n\tq : Quit\n\t? : See this help page\n";
  local ($idProcessingSteps) =
  	"\tb : fix bad pix\n\tm : fix moving bad pix\n".
  	"\to : overscan\n\tt : trim\n\tz : zero\n\td : dark\n\tf : flat\n".
	"\tc : sky dc\n\ts : sky illumination\n\tg : fringe\n".
	"\ta : all of the above\n\tx : none\n\tu : undo (erase all steps)\n".
  	"\tn : Continue\n\tq : Quit\n\t? : See this help page\n";

  SWITCH: {
    if ($sub eq 'CheckHeader') {print "$checkHeader"; last SWITCH;}
    if ($sub eq 'IDProcessingSteps') {print "$idProcessingSteps"; last SWITCH;}
    print "No help available for '$sub'.\n";
  }
  
  return();
}
