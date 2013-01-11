#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: mkfringe
#Version: 1.0.1
#
#MkFringe.  Compute fringe correction images from combined blank sky images.
#	    First, it computes an illumination image (if none exist) but do not 
#           normalize it. Then the illumination image is subtracted from the 
#	    original sky image.  The result is the fringe image.
#
#Usage: (image|--in=root) (output|--out=root) (illumimage|--illum=root)
#		--log=logfile (--param=paramfile|--inst=instrument)
#
#	image:		Name of input image
#	output:		Name of output image
#	illumimage:	Name of illumination image
#	--in:		Image type, root.  Will go through all RootSubset images
#			  in current directory.
#	--out:		Root of output images
#	--illum:	Root of illumination images
#	--param:	Full name of the param file.
#	--inst:		Name of the instrument for retrieval of param file
#	--log:		Name of the logfile
#
#Needs:
#   %%%Iraf::Images%%%
#   %%%KLimgutil%%%
# %%%/astro/labrie/progp/iraf/images/mkillum.pl%%%
# %%%/astro/labrie/progp/iraf/images/imstatistics.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdhedit.pl%%%
# %%%/astro/labrie/progc/img/fits/getkeyval%%%
# %%%/astro/labrie/progc/img/util/imarith%%%

use FileHandle;		# $fh files
use Time::Local;	# timegm()
use Cwd;
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use Iraf::Images;

$|=1;	#OUTPUT_AUTOFLUSH ON

#Define
$TFLOAT = 'float';

#Set defaults
$mkillum="nice -19 $CCDred::ccdlist";
$ccdhedit="nice -19 $CCDred::ccdhedit";
$getkeyval="nice -19 $CCDred::getkeyval";
$imarith="nice -19 $CCDred::imarith";
$imstat="nice -19 $Images::imstatsel";
$extension=$CCDred::imtype;
$setFile="$HOME/iraf/privuparm/setinst.par";
$illumSCRATCH='illumSCRATCH.'.$extension;
$skySCRATCH='skySCRATCH.'.$extension;
$status=0;
@subsets=();
%IRAFbasetime = %Iraf::IRAFbasetime;

$i=0;
#Read command line
while ($_ = shift @ARGV) {
  if ( /--/ ) {
    s/--//;
    SWITCH: {
      if ( /^illum=/ or
           /^param=/ or
           /^inst=/ or
	    /^out=/ or
	    /^in=/ or
	    /^log=/ )	{ ($key,$value) = split /=/;
	   		  $commandLine{"$key"} = $value;
			  last SWITCH;
      }
      # default: Error
      die "ERROR: Unknown command line argument ($_)\n";
    }
  }
  else {
    $ioimages[$i++]=$_;
  }
}

#Get instrument's name
if (not defined $commandLine{'inst'}) {
  if (defined $commandLine{'param'}) {
    $commandLine{'param'} =~ /\/(\w+)\.illum$/;
    $instrument = $1;
  } else {
    die "--inst or --param must be specified.\n";
  }
}
else {
  $instrument = $commandLine{'inst'};
}

#Get some param (instrument.param)
$setFile .= ".$instrument";
%inst = Iraf::getParam($setFile,':');
%param = Iraf::getParam("$inst{'directory'}/$inst{'site'}/$inst{'instrument'}.param",'=');

#Check which image can be found
@inFiles=();
@outFiles=();
@illumFiles=();
if ( defined $commandLine{'in'} and defined $commandLine{'out'} and
     defined $commandLine{'illum'} ) {
  if (defined @ioimages) {
  	die "ERROR: Input error. No image name allowed when --in/--out are used.\n";
  }
  @inFiles = glob("$commandLine{'in'}*.$extension");
  if ($#inFiles < 0) {
    die "ERROR: No input $commandLine{'in'} files found.\n";
  }
  foreach $inFile (@inFiles) {
    $inFile =~ /$commandLine{'in'}(\w+)\.$extension/;
    push @subsets, $1;
    push @outFiles, "$commandLine{'out'}$1.$extension";
    push @illumFiles, "$commandLine{'illum'}$1.$extension";
  }
}
elsif (defined @ioimages) {
  unless ($#ioimages + 1 == 3) {  	# 3 images: input + output + illum
  	die "ERROR: Input error. Missing input, output and/or illum images.\n";
  }
  if (defined $commandLine{'in'} or defined $commandLine{'out'}) {
  	die "ERROR: Input error. Use i/o images OR --in/--out format.\n";
  }
  push @inFiles, $ioimages[0];
  push @outFiles, $ioimages[1];
  push @illumFiles, $ioimages[2];
  if (defined $commandLine{'subset'}) { push @subsets, $commandLine{'subset'}; }
  else { push @subsets, ''; }
}
else {
	die "ERROR: Input error. Both --in, --out AND --illum must be defined.\n";
}

for ($i=0; $i<=$#inFiles; $i++) {
  #Check if illum image exists. If not, create them with mkillum.pl
  unless (-e $illumFiles[$i]) {
    print "WARNING: Illumination image for $inFiles[$i] does not exist.\n";
    print "         Will attempt to create it now.\n";
    if (defined $commandLine{'log'}) {
      Iraf::printlog($commandLine{'log'},
      		"WARNING: Illumination image for $inFiles[$i] not found.\n");
    }
    if (not defined $commandLine{'param'}) {	#goes in there only once
	$commandLine{'param'}="$inst{'directory'}/$inst{'site'}/$inst{'instrument'}".
	                      ".illum";
    }
    $command="$mkillum $inFiles[$i] $illumFiles[$i] --param=$commandLine{'param'}";
    if (defined $commandLine{'log'}) {
      $command .= " $commandLine{'log'}";
    }
    if ((system("$command")) != 0) {
      die "ERROR: Exiting 'mkfringe'\n";
    }
  }
}

for ($i=0; $i<=$#inFiles; $i++) {
  print "\nMake fringe image for $inFiles[$i] ... \n";
  $command = "$imarith '$inFiles[$i]' '-' '$illumFiles[$i]' '$outFiles[$i]'";
  if ((system("$command")) != 0) {
    if (defined $commandLine{'log'}) {
      Iraf::printlog($commandLine{'log'},
      	  "\tERROR: Error while computing fringe pattern on $inFiles[$i]\n");
    }
    print "*** ERROR: Error while computing fringe pattern on $inFiles[$i]\n";
    exit($status = 1);
  }
  
  # Calculate mean illumination corrected 'Sky' image
  #	The fringe pattern depends on the incoming flux.  The mean target flux
  #	will be calculated from the illumination corrected image.  We're doing
  #	here an extra step (correct 'Sky' for illumination), but doing it now 
  #	ensure that the numbers needed will be calculated only once for each 
  #	filter.
  @cannot=();
  @goners=($illumSCRATCH,$skySCRATCH);
  $pipe = "$getkeyval $illumFiles[$i] -k CCDMEAN -d $TFLOAT";
  $fhPipeOut = new FileHandle "$pipe |";
  $illumMean=<$fhPipeOut>;
  $fhPipeOut->close();
  $illumMean =~ s/\n//;
  system("$imarith $illumFiles[$i] '/' $illumMean $illumSCRATCH");
  system("$imarith $inFiles[$i] '/' $illumSCRATCH $skySCRATCH");
  &ImMean($skySCRATCH,$outFiles[$i]);	#Add keyword FLUXMEAN
  @cannot = grep { not unlink } @goners;
  die "$0: could not unlink @cannot\n" if @cannot;

  # Calculate time for MKFRINGE
  ($date,$time) = Util::datenTime(time);
  $mkFringeValue = 
  		"$date $time Fringe correction created from $inFiles[$i]";
  $ccdmeant = time - timegm($IRAFbasetime{'sec'}, $IRAFbasetime{'min'},
                            $IRAFbasetime{'hours'}, $IRAFbasetime{'mday'},
                            $IRAFbasetime{'mon'}, $IRAFbasetime{'year'});

  # Calculate average flux (CCDMEAN) of the 'Fringe' image
  $pipe="$imstat $outFiles[$i] --fields='mean'";
  foreach $statparam (grep /^mkfringe.stat/, keys %param) {
    $statparam =~ /^mkfringe.stat(.*?)$/;
    $pipe .= " --$1=$param{$statparam}";
  }
  $fhpipe = new FileHandle "$pipe|";
  @lines=();
  while (<$fhpipe>) {
    next if (/^(>|$outFiles[$i]|-)/);
    s/\s|\n//g;
    push @lines, $_;
  }
  if ($#lines == 0) {	#Only one element as it should be
    $ccdmean = $lines[0];
  }
  else {                #Some serious error
    die "ERROR: Error while calculating CCDMEAN for $outFiles[$i]\n";
  }


  #Change title and edit header
  $newTitle="Fringe - $subsets[$i]-band";
  system("$ccdhedit $outFiles[$i] 'OBJECT' '$newTitle' 'string' --inst=$instrument");
  system("$ccdhedit $outFiles[$i] 'MKFRINGE' '$mkFringeValue' 'string' --inst=$instrument");
  system("$ccdhedit $outFiles[$i] 'CCDMEAN' '$ccdmean' 'real' --inst=$instrument");
  system("$ccdhedit $outFiles[$i] 'CCDMEANT' '$ccdmeant' 'integer' --inst=$instrument");
  if (defined $commandLine{'log'}) {
    Iraf::printlog($commandLine{'log'},"$outFiles[$i]: $mkFringeValue\n");
  }
  print "done\n";
}

$|=0;
exit($status);

#-------------------------

#-------------------------\
#         ImMean           \
#---------------------------\
sub ImMean {
 my ($input,$output) = @_;
 my ($imstat) = "nice -19 $Images::imstatsel";
 my (@lines) = ();
 my ($pipe,$fhpipe,$fluxmean);

 $pipe = "$imstat $input --fields='mean'";
 foreach $statparam (grep /^mkfringe.stat/, keys %param) {
   $statparam =~ /^mkfringe.stat(.*?)$/;
   $pipe .= " --$1=$param{$statparam}";
 }
 $fhpipe = new FileHandle "$pipe|";
 while (<$fhpipe>) {
   next if (/^(>|$input|-)/);
   s/\s|\n//g;
   push @lines, $_;
 }
 if ($#lines == 0) {	#Only one element as it should be
   $fluxmean = $lines[0];
 }
 else {		#Some serious error
   die "ERROR: Error while calculating FLUXMEAN for $output\n";
 }

 system("$ccdhedit $output 'FLUXMEAN' '$fluxmean' 'real' --inst=$instrument");

 return();
}
