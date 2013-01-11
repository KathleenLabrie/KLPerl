#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: ccdproc	(IRAF 2.11.3)
#Version: 1.3.1
#
#Command-line : (images/-l list) --ccdtype=type [--overscan --trim --zero --dark 
#			--flat --skyflat --domeflat] --inst=instrument
#
#Needs:
#   %%%Cccdred%%%
# %%%/iraf/irafbin/noao.bin.sparc/x_ccdred.e%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdlist.pl%%%
# %%%/astro/labrie/progc/img/ccdred/fringecor%%%
# %%%/astro/labrie/progc/img/ccdred/dccor%%%

use FileHandle;
use Cwd;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

#Set defaults
$imtype=$CCDred::imtype;
$setFile="$HOME/iraf/privuparm/setinst.par";

#Initialise variables
@listOfImages = ();
$moreParam{'ccdtype'}='';
$moreParam{'extraObstype'}='';

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      if ( /=/ ) {
        ($key,$value) = split /=/;
	 $moreParam{$key}=$value;
      }
      else {
        die "Just one option can be selected at a time.\n" if (defined $option);
	 $option = $_;
      }
      last SWITCH;
    }
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
}

if (($option eq 'skyflat') or ($option eq 'domeflat')) {
  $option =~ s/(\w*)[F|f]lat/flat/;
  $moreParam{'extraObstype'} = ucfirst($1);
}
  

#Read the file with the list of images
if ($list) {
  open(LIST,"<$list") or die "Can't open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    push @listOfImages, $_;
  }
  close(LIST);
}

#Check for imtype extension and put the right one
for ($i=0;$i<=$#listOfImages;$i++) {
  $listOfImages[$i] .= '.'.$imtype;
}

#Read setinst.par
if (defined $moreParam{'inst'}) {
  $setFile .= ".$moreParam{'inst'}";
}
$paramFile = Iraf::whereParam($setFile);

#Read project's .cl file
%allParam = Iraf::getParam($paramFile,'=');
$allParam{'paramFile'} = $paramFile;
foreach $key (keys %moreParam) { $allParam{$key} = $moreParam{$key}; }

#Overwrite param specifically defined by the user
#foreach $moreKey (keys %moreParam) {
#  if (grep /$moreKey/, keys %param) {
#    $param{$moreKey} = $moreParam{$moreKey};
#  }
#}

SWITCH: {
  if ($option eq 'overscan') {CCDred::ccdOverscan(\%allParam,@listOfImages);}
  if ($option eq 'trim') {CCDred::ccdTrim(\%allParam,@listOfImages);}
  if ($option eq 'zero') {CCDred::ccdZero(\%allParam,@listOfImages);}
  if ($option eq 'dark') {CCDred::ccdDark(\%allParam,@listOfImages);}
  if ($option eq 'flat') {CCDred::ccdFlat(\%allParam,@listOfImages);}
  if ($option eq 'illum'){CCDred::ccdIllum(\%allParam,@listOfImages);}
  if ($option eq 'fringe') {CCDred::ccdFringe(\%allParam,@listOfImages);}
  if ($option eq 'dc')   {CCDred::ccdDC(\%allParam,@listOfImages);}
}


exit(0);
