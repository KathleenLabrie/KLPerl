#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: darkcombine
#Version: 2.0.1
#
#Command-line : (images/-l list) --ccdtype=type --inst=instrument
#
# Needs:
#   %%%libKLimgutil%%%

use FileHandle;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);	#preprend dir to @INC
use Iraf::CCDred;

#Set defaults
$imtype=$CCDred::imtype;
$getkeyval = $CCDred::getkeyval;
$setFile="$HOME/iraf/privuparm/setinst.par";
$moreParam{'process'}='no';

#Defaults for combine
$moreParam{'plfile'}='';
$moreParam{'sigma'}='';
$moreParam{'subsets'}='no';
$moreParam{'project'}='no';
$moreParam{'outtype'}='real';
$moreParam{'offsets'}='none';
$moreParam{'masktype'}='none';
$moreParam{'maskvalue'}='0';
$moreParam{'zero'}='none';
$moreParam{'weight'}='no';
$moreParam{'lthreshold'}='INDEF';
$moreParam{'hthreshold'}='INDEF';
$moreParam{'sigscale'}='0.1';
$moreParam{'grow'}='0';


#Initialise variables
@listOfImages = ();
$moreParam{'ccdtype'}='dark';

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ )  {
      s/--//;
      if (/=/) { ($key,$value) = split /=/; }
      else     { $key = $_; $value = 1; }
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if ($list) {
  open(LIST,"<$list") or die "Can't open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
  close(LIST);
}

#Check for imtype extension and put the right one
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

#Read setinst.par
if (defined $moreParam{'inst'}) { $setFile .= ".$moreParam{'inst'}"; }
$paramFile = Iraf::whereParam($setFile);

#Read project's .cl file
%allParam = Iraf::getParam($paramFile,'=');
foreach $key (keys %moreParam) { $allParam{$key} = $moreParam{$key}; }

#Read project's .dat file for exptime keyword ( if no scaling)
if ($allParam{'darkcombine.scale'} eq 'none') {
  $paramFile =~ s/\.cl$/B\.dat/;
  $etime_key = Iraf::getTrans($paramFile,'exptime',2);
}

#Check some parameters
die ("Unacceptable parameter : 'darkcombine.process' must be "."$allParam{'process'}\n") 
     if ($allParam{'darkcombine.process'} ne $allParam{'process'});

#Get exposure time of each dark (if no scaling)
if ($allParam{'darkcombine.scale'} eq 'none') {
  $pipe = "$getkeyval @listOfImages -k $etime_key -d float";
  $fhPipeOut = new FileHandle "$pipe |";
  @values = <$fhPipeOut>;
  $fhPipeOut->close();
  for ($i=0; $i<=$#listOfImages; $i++) {
    $values[$i] =~ s/\n//;
    push @{ $etime_img{$values[$i]} }, $listOfImages[$i];
  }
  undef @values;
  undef @listOfImages;
}

#Combine dark frames
$| = 1;		#OUTPUT_AUTOFLUSH ON

sub numerically { $a <=> $b;}

if ($allParam{'darkcombine.scale'} eq 'none') {
  foreach $etime (sort numerically keys %etime_img) {
    $etime =~ /(\d+)\.(\d*?)0*$/;
    $time = $1.'.'.$2;
    print "\nCombining $time sec darks ... \n";
    $time =~ s/\.//;
    $allParam{'output'} = $allParam{'darkcombine.output'}.$time.'.'.$imtype;
    CCDred::darkcombine(\%allParam, @{ $etime_img{$etime} });
    print " done\n";
  }
}
else {
  CCDred::darkcombine(\%allParam, @listOfImages);
}
$| = 0;		#OUTPUT_AUTOFLUSH OFF

exit(0);
