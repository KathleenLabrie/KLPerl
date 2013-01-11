#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: cr
#Version: 1.0.2
#	Cosmic ray removal.  Uses C-programs 'findbadpix' and 'fixbadpix'.
#
# Usages: cr.pl images [-o output] [searchParameters] [--log=logfile] 
#			[--inst=instrument]
#	   cr.pl -l listOfImages [-o output] [searchParameters] [--log=logfile]
#			[--inst=instrument]
#	   cr.pl reducDir [-o output] [options] [searchParameters] 
#			[--log=logfile] [--inst=instrument]
#
#	-o output	: If only one input image, name of the output file.
#			  If multiple input images, prefix of the output files.
#			  [Default: overwrites input images]
#
#	Options:
#	-lr runList	: Name of the file containing the list of runs/objects.
#	-ln nightList	: Name of the file containing the list of nights, i.e.
#			  their "eYYMMDD" identification
#	-r run		: ID of the run/objects.
#	-n night	: ID of the night.
#
#	If none of the two switches below are toggled, will by default do both.
#	Otherwise, only the one(s) specified will be done.
#	--find		: Find the cosmic rays
#	--fix		: Fix the cosmic rays
#
#	--log=logfile : Name of the logfile
#	--inst=instrument: Name of the instrument
#
#	Search Parameters:
#
# Needs :
#   %%%Cccdred%%%
#   %%%/astro/labrie/progc/img/ccdred/findbadpixR%%%
#   %%%/astro/labrie/progc/img/ccdred/fixbadpix%%%
#   %%%/astro/labrie/progp/iraf/ccdred/ccdhedit.pl%%%

use FileHandle;	# $fh files
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

###########
$| = 1;
$DEBUG = 0;
$CLOBBER = 1;
###########

#Definitions
$FIND = 1;		#1 << 0
$FIX = 2;		#1 << 1

#Error codes
$FILE_NOT_FOUND = 101;

#Set Defaults
$status = 0;
$flag = 0;
$imtype= $CCDred::imtype;
$suffix = 'crc';
$findbadpix = $CCDred::findbadpixR;
$fixbadpix = $CCDred::fixbadpix;
$runs=();
$nights=();
$images=();
#$outImages=();
$param{'medX'} = 21;
$param{'medY'} = 21;
$param{'sbox'} = '21,21,21,21';
$param{'lsigma'} = '50,50';		#Don't bother with low pixels
$param{'hsigma'} = '3,4';
$param{'tclip'} = '2,3';
$param{'niter'} = 2;

$interativeParams='^log|^inst|^medX|^medY|^sbox|^lsigma|^hsigma|^tclip|^niter';

#Read command line
while ($_ = shift @ARGV) {
  if ( /^--/ ) {
    s/^--//;
    SWITCH: {
      if (/^find/)		{$flag |= 1 << 0; last SWITCH;}
      if (/^fix/)		{$flag |= 1 << 1; last SWITCH;}
      elsif (/$interativeParams/) {
        if (/=/) { ($key,$value) = split /=/, $_; }
	 else     { $key = $_; $value=1; }
	 $param{$key} = $value;
	 last SWITCH;
      }
      else 			{die "ERROR: Unknown switch ($_)\n";}
    }
  }
  elsif ( /^-/ ) {
    s/^-//;
    SWITCH: {
      if (/^lr$/)		{$runList = shift @ARGV; last SWITCH;}
      if (/^ln$/)		{$nightList = shift @ARGV; last SWITCH;}
      if (/^l$/)		{$imageList = shift @ARGV; last SWITCH;}
      if (/^r$/)		{push @runs, shift @ARGV; last SWITCH;}
      if (/^n$/)		{push @nights, shift @ARGV; last SWITCH;}
      if (/^o$/)		{$param{'output'} = shift @ARGV; last SWITCH;}
      else			{die "ERROR: Unknown switch ($_)\n";}
    }
  }
  else {
    push @otherArgv, $_;
  }
}

#Figure out what the user wants to do.
if ($flag == 0) {	#default -> find and fix
	$flag = $FIND + $FIX;
}			#otherwise use his/her flag

#Parse @otherArgv
if ($#otherArgv+1 == 0) {	# should have a list of images then
	die "ERROR: No input images.\n" if (not defined $imageList);
} else {			# image or reducDir
	@dir = grep {-d} @otherArgv;
	if ($#dir+1 > 1) { die "ERROR: Only one directory name please.\n"; }
	if ($#dir+1 == 0) { 	# all images
	  foreach $_ (@otherArgv) {
	    if (not -e $_) { 
	    	warn "ERROR: Image not found. ($_)\n";
		$status = $FILE_NOT_FOUND;
	    } else {
	    	push @images, $_;
	    }
	  }
	}
	if ($#dir+1 == 1) {
	  if ($#dir == $#otherArgv) {	# directory
	    $reducDir = $dir[0].'/';
	    $reducDir =~ tr/\///s;
	  } else {			#Mix of directory and images
	    die "ERROR: Only directories or only images, not both.\n";
	  }
	}
}

#Read image list
if (defined $imageList) {
  $fhrd = new FileHandle "< $imageList" or 
  			die "ERROR: Unable to open $imageList for reading.\n";
  while (<$fhrd>) {
    if (not -e $_) {
    	warn "ERROR: Image not found. ($_)\n";
	$status = $FILE_NOT_FOUND;
    } else {
    	push @images, $_;
    }
  }
  $fhrd->close;
}

if ($status != 0) { die "Error Code $status\n"; }

#Get list of runs if in reducDir mode
if ((defined $reducDir) && (defined $runList)) {
  push @runs, Util::getListOf('-d','-l',$runList,$reducDir);
}
grep { $_ .= '/'; tr/\///s; } @runs;

#Get list of nights if in reducDir mode
if ((defined $reducDir) && (defined $nightList)) {
  push @nights, Util::getListOf('-d','-l',$nightList,$reducDir);
}
grep { $_ .= '/'; tr/\///s; } @nights;

if ($flag & ($FIND + $FIX)) {
  if (defined $reducDir) {

    # Loop through the runs
    foreach $run (@runs) {
      @epochs = ();
      @nightAvail = Util::getListOf('-d','-p','e??????',$reducDir.$run);
      if (defined @nights) {
        foreach $avail (@nightAvail) {
	   $avail =~ /(e\d+)$/;
	   $epoch2Find = $1;
	   if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
	 }
      }
      else { push @epochs, @nightAvail; }
      grep { $_ .= '/'; tr/\///s; } @epochs;

      # Loop through the epochs
      foreach $epoch (@epochs) {
        print "\n$epoch\n";
	 if (defined $param{'log'}) {
	   $fhlog = new FileHandle ">> $param{'log'}" or
	   		die "ERROR: Unable to open $param{'log'} for writing.\n";
	   print $fhlog "\n${epoch}: COSMIC RAY REJECTION\n";
	   $fhlog->close;
	 }
	 
	 #Get image names
	 @images = Util::getListOf('-e','-p','*.fits',$epoch);

	 #------------------#
	 # Find cosmic rays #
	 #------------------#
	 if ($flag & $FIND) {
	   if ($DEBUG) { print "Here I would do FindBadpix on @images\n"; }
	   else        { CCDred::findBadPix(\%param,@images); }
	 }

	 #-----------------#
	 # Fix cosmic rays #
	 #-----------------#
	 if ($flag & $FIX) {
	   if ($DEBUG) { print "Here I would do FixBadpix on @images\n"; }
	   else        { CCDred::fixBadPix(\%param,@images); }
	 }
	 
      }	#end of loop through the epochs      
    }	#end of loop through the runs
  }

  else {		# image names were provided

    #------------------#
    # Find cosmic rays #
    #------------------#
    if ($flag & $FIND) {
      if ($DEBUG) { print "Here I would do FindBadpix on @images\n"; }
      else 	    { CCDred::findBadPix(\%param,@images); }
    }

    #-----------------#
    # Fix cosmic rays #
    #-----------------#
    if ($flag & $FIX) {
      if ($DEBUG) { print "Here I would do FixBadpix on @images\n"; }
      else        { CCDred::fixBadPix(\%param,@images); }
    }
  }
}


exit(0);
