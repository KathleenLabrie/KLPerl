#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: zerocombine
#Version: 1.0.2
#
#Command-line : (images/-l list) --ccdtype=type --inst=instrument

use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

#**** WARNING ****
$"=',';
#**** WARNING ****

#Set defaults
$pkg='/iraf/irafbin/noao.bin.sparc/x_ccdred.e';
$task='combine';
$imtype=$CCDred::imtype;
$setFile="$HOME/iraf/privuparm/setinst.par";
$moreParam{'process'}='no';

#Defaults for zerocombine
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
$moreParam{'ccdtype'}='zero';

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ )  {
      s/--//;
      ($key,$value) = split /=/;
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

#Check some parameters
die ("Unacceptable parameter : 'zerocombine.process' must be "."$allParam{'process'}\n") 
     if ($allParam{'zerocombine.process'} ne $allParam{'process'});

#Combine bias frames
CCDred::zerocombine(\%allParam,@listOfImages);

exit(0);
