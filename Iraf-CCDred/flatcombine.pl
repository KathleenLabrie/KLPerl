#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: flatcombine
#Version: 1.1.2
#
#Command-line : (images/-l list) --ccdtype=type --inst=instrument 
#			--oprefix=extraObstype

use FileHandle;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);	#prepend dir to @INC
use Iraf::CCDred;

#Set defaults
$imtype=$CCDred::imtype;
$setFile="$HOME/iraf/privuparm/setinst.par";
$moreParam{'process'}='no';
$ccdlist=$CCDred::ccdlist;

#Defaults for combine
$moreParam{'plfile'}='';
$moreParam{'sigma'}='';
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
$moreParam{'ccdtype'}='flat';

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
die ("Unacceptable parameter : 'flatcombine.process' must be "."$allParam{'process'}\n") 
     if ($allParam{'flatcombine.process'} ne $allParam{'process'});

#Get list of subsets
@subsets=();
$command = "$ccdlist @listOfImages --ccdtype=flat --quiet";
if (defined $allParam{'inst'}) { $command .= " --inst=$allParam{'inst'}"; }
$fhpipe = new FileHandle "$command|" or die "Cannot pipe from $ccdlist.\n";
@ccdlines = <$fhpipe>;
$fhpipe->close() or die "Unable to close the pipe from $ccdlist.\n";
foreach $line (@ccdlines) {
  $line =~ /\[(\w+)\]\[\w+\]\:.*?$/;
  $subset = $1;
  next if ( grep /$subset/, @subsets);
  push @subsets, $subset;
}

#For each subset combine the flats
$|=1;		#OUTPUT_AUTOFLUSH ON
foreach $subset (@subsets) {
  @list = ();
  foreach $line (@ccdlines) {
    $line =~ /\[(\w+)\]\[\w+\]\:.*?$/;
    next if ($1 ne $subset);
    $line =~ /^((\w|\.|-|\/)+)\[/;
    push @list, $1;
  }

  #Combine flat frames
  print "Combining $subset flats -> $moreParam{'oprefix'}Flat${subset}.fits\n";
  if ((length (join ',',@list)) > 511 ) {
    print "WARNING: Input line too long for IRAF (",
    	length (join ',',@list)," ch).  Writing to a scratch file ... ";
    open(SCRATCH,">scratchList") or die "Unable to open a scratch file.\n";
    foreach $_ (@list) {
      print SCRATCH "$_\n";
    }
    close(SCRATCH);
    print "done\n";
  }
  CCDred::flatcombine(\%allParam,$moreParam{'oprefix'},@list);
  if (-e 'scratchList') {unlink 'scratchList';}
}
$|=0;		#OUTPUT_AUTOFLUSH OFF
exit(0);
