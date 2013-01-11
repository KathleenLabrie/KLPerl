#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: enametype
#Version: 0.1.1
$prog = 'enametype';
$version = '0.1.1';
#
# Based on object type, append a one-letter qualifier to the image name.
# 	object, standard, sky 	: 'o'
#	flat, domeflat, skyflat	: 'f'
#	dark 			: 'd'
#	bias			: 'b'
#	none			: 'n'
#
# Usage: enametype images [--inst=intrument] [--test]
#        enametype -l imlist [--inst=intrument] [--test]
#	 enametype -h|--help
#	 enametype --version
#
#	images	: list of images to fix
#	--inst	: specify the instrument (STRONGLY recommended)
#	--test	: Do not rename the files, just output the new names
#	--version: Print version to stdout
#	-h, --help: Print help page
#
# Needs:
#   %%%-- translation files for the instrument --%%%

use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use FileHandle;
use File::Copy;

#Define
$SUCCESS = 1;
$USAGE = "Usage: enametype images [--inst=intrument] [--test]\n".
	 "       enametype -l imlist [--inst=intrument] [--test]\n".
	 "       enametype -h|--help\n".
	 "       enametype --version\n";
$HELP = "\timages       : list of images to fix\n".
	"\t--inst       : specify the instrument (STRONGLY recommended)\n".
	"\t--test       : Do not rename the files, just output the new names\n".
	"\t--version    : Print version to stdout\n".
	"\t-h, --help   : Print help page\n";
$FALSE=$CCDred::FALSE;
$TRUE=$CCDred::TRUE;

#Set defaults
$ccdlist = $CCDred::ccdlist;
$moreParam{'instrument'}="";
$moreParam{'help'} = $FALSE;
$moreParam{'test'} = $FALSE;
$moreParam{'version'} = $FALSE;
@recognizedOptions = ( 'inst', 'help', 'test', 'version');
%types = ( 'object' => 'o',
	   'other'  => 'o',
	   'flat'   => 'f',
	   'dark'   => 'd',
	   'zero'   => 'b',
	   'none'   => 'n'
);

#Initialize
@images = ();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^--/ ) {
    	s/^--//;
	if ( /=/ ) 	{ ($key,$value) = split /=/; }
	else		{ $key=$_; $value=$TRUE; }
	if ( grep { /^$key$/ } @recognizedOptions ) {
	  $moreParam{$key} = $value;
	  last SWITCH;
	}
	else { die "ERROR: Unrecognized option, '$key'\n$USAGE\n"; }
    }
    if ( /^-l$/ ) { $imList = shift @ARGV; last SWITCH;}
    if ( /^-h$/ ) { $moreParam{'help'} = $TRUE; last SWITCH;}
    if ( /^-/ ) { die "ERROR: Unrecognized option, '$_'\n$USAGE\n"; }
    push @images, $_;
  }
}

if ( $moreParam{'help'} ) {
	print "$USAGE\n$HELP\n";
	exit(0);
}
if ( $moreParam{'version'} ) {
	print "$prog v$version\n";
	exit(0);
}

#Get image names from list
if (defined $imList) {
  $fhrd = new FileHandle "<$imList" or die "Unable to open $imList for reading.\n";;
  while (<$fhrd>) {
    s/\n//;
    push @images, $_;
  }
  $fhrd->close() or die "Unable to close $imList\n";
}

# ccdlist the images
@ccdlines=();
$command = "$ccdlist @images --quiet";
if (defined $moreParam{'inst'}) { $command .= " --inst=$moreParam{'inst'}"; }
$fhpipe = new FileHandle "$command|" or die "Unable to pipe from $ccdlist.\n";
@ccdlines = <$fhpipe>;
$fhpipe->close() or die "Unable to close pipe from $ccdlist.\n";

# fix images
$|=1;		#OUTPUT_AUTOFLUSH ON
foreach $line (@ccdlines) {
  $line =~ /(^.+?)\[.+?\]\[\w+?\]\[(\w+)\]/;
  $type = $2;
  $oldName = $1;
  $newName = $oldName;
  $newName =~ s/^(.+)\.(\w+)$/$1$types{$type}.$2/;
  if ($moreParam{'test'}) { print "$newName\n"; }
  else {
    if ( copy($oldName,$newName) != $SUCCESS) {	#if copy failed
      warn "Unable to write '$newName'. '$oldName' not deleted.\n";
      next;
    }
    if ( (unlink $oldName) != $SUCCESS ) {	#if delete failed
      warn "Unable to delete '$oldName'\n";
      next;
    }
  }
}
$|=0;		#OUTPUT_AUTOFLUSH OFF

#all done
exit(0);
