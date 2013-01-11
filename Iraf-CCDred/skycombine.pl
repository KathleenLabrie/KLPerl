#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: skycombine
#Version: 1.0.0
#
#Usage: skycombine (images/-l list) --ccdtype=type --inst=instrument
#		
#

use FileHandle;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::Images;
use Iraf::CCDred;

#Set defaults
$imcombine=$Images::imcombine;
$imtype=$CCDred::imtype;
$setFile="$HOME/iraf/privuparm/setinst.par";
$ccdlist=$CCDred::ccdlist;

#Initialize
@listOfImages = ();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if (/^-l$/) {$list = shift @ARGV; last SWITCH;}
    if (/--/) {
      s/--//;
      ($key,$value) = split /=/;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits|\.imh$//;
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if (defined $list) {
  $fhrd = new FileHandle "<$list" or die "Unable to open $list for reading.\n";
  while (<$fhrd>) {
    s/\n//;
    s/\.fits|\.imh//;
    push @listOfImages, $_;
  }
  $fhrd->close();
}

#Check for imtype extension and put the right one
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

#Read setinst.par
if (defined $moreParam{'inst'}) { $setFile .= ".$moreParam{'inst'}"; }
$paramFileCl = Iraf::whereParam($setFile);
$paramFileMy = $paramFileCl;
$paramFileMy =~ s/\.cl/\.param/;

#Read project's .cl and .param files
%allParam = Iraf::getParam($paramFileCl,'=');
%tmpParam = Iraf::getParam($paramFileMy,'=');
foreach $key (keys %tmpParam) { $allParam{$key} = $tmpParam{$key}; }
foreach $key (keys %moreParam) { $allParam{$key} = $moreParam{$key}; }

#Sort images by subsets
$command = "$ccdlist @listOfImages --ccdtype=other --quiet";
if (defined $allParam{'inst'}) {$command .= " --inst=$allParam{'inst'}"; }
$fhpipe = new FileHandle "$command|" or die "Cannot pipe from $ccdlist.\n";
@ccdlines = <$fhpipe>;
$fhpipe->close() or die "Unable to close the pipe from $ccdlist.\n";
foreach $line (@ccdlines) {
  next if (not ($line =~ 
    /^((\w|\.|-|\/)+)\[.+?\[$allParam{'skycombine.ccdtype'}\]\[(\w+)\]\[\w+\]\:.*?$/ ));
  $imageName = $1;
  $subset = $3;
  push @{ $images{$subset} }, $imageName;
}

#Combine
$options = "--log=$allParam{'ccdred.logfile'} ".
           "--combine=$allParam{'skycombine.combine'} ".
	   "--reject=$allParam{'skycombine.reject'}";
if ($allParam{'skycombine.scale'} ne 'none') {
  if ( not ($allParam{'skycombine.statsec'} =~ /\[\d+\:\d+,\d+\:\d+\]/) ) {
     die "Skycombine: 'statsec' not defined.\n";
  }
  $options .= " --scale=$allParam{'skycombine.scale'}".
              " --statsec=$allParam{'skycombine.statsec'}";
}
SWITCH: {
  if ($allParam{'skycombine.reject'} eq 'sigclip') {
    $options .= " --lsigma=$allParam{'skycombine.lsigma'}".
                " --hsigma=$allParam{'skycombine.hsigma'}";
    last SWITCH;
  }
  if ($allParam{'skycombine.reject'} eq 'minmax') {
    $options .= " --nlow=$allParam{'skycombine.nlow'}".
                " --nhigh=$allParam{'skycombine.nhigh'}";
    last SWITCH;
  }
  die "ERROR: Skycombine: Unknown rejection algorithm.\n";
}

$fhlog = new FileHandle ">>$allParam{'ccdred.logfile'}";
foreach $subset (keys %images) {
  $output = $allParam{'skycombine.output'}.$subset.'.'.$imtype;
  system ("$imcombine @{$images{$subset}} -o $output $options");
}
$fhlog->close();

exit(0);
