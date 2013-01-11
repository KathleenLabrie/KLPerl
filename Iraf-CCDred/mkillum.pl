#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: mkillum
#Version: 1.0.1
#
#MkIllum.  Compute illumination correction images from combined blank sky
#	   images.
#
#Usage: (image|--in=root) (output|--out=root) --log=logfile
#		(--param=paramfile|--inst=instrument)
#
#	image:		Name of input image
#	output:		Name of output image
#	--subset:	Subset of the input image
#	--in:		Image type, root.  Will go through all RootSubset images
#			  in current directory.
#	--out:		Root of output images
#	--param:	Full name of the param file.
#	--inst:		Name of the instrument for retrieval of param file
#	--log:		Name of the logfile
#
#Needs:
#   %%%Iraf::Images%%%
#   %%%KLimgutil%%%
# %%%/astro/labrie/progc/img/util/filter%%%
# %%%/astro/labrie/progp/iraf/images/imreplace.pl%%%
# %%%/astro/labrie/progp/iraf/images/imstatistics.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdhedit.pl%%%

use FileHandle; 	# $fh files
use Time::Local;	# timegm()
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use Iraf::Images;

$|=1;		#OUTPUT_AUTOFLUSH ON

#Set defaults
$filterType = 'boxcar';
$filter = "nice -19 $CCDred::filter";
$imreplace = "nice -19 $Images::imreplace";
$imstat = "nice -19 $Images::imstatsel";
$ccdhedit = "nice -19 $CCDred::ccdhedit";
$extension = $CCDred::imtype;
$setFile = "$HOME/iraf/privuparm/setints.par";
$status=0;
%IRAFbasetime = %Iraf::IRAFbasetime;

$i=0;
#Read command line
while ($_ = shift @ARGV) {
  if ( /--/ ) {
    s/--//;
    SWITCH: {
      if ( /^param/ or 
           /^inst/ or
           /^out/ or
	   /^in/ or
	   /^log/ )	{ ($key,$value) = split /=/;
                          $commandLine{"$key"} = $value;
			  last SWITCH;
      }
      #Default: Error
      die "ERROR: Unknown command line argument ($_)\n";
    }
  }
  else {
    $ioimages[$i++]=$_;
  }
}

#Get location and name of 'instrument.illum' file
unless (defined $commandLine{'param'}) {
 if (defined $commandLine{'inst'}) {
   $setFile .= ".$commandLine{'inst'}";
   %inst = Iraf::getParam($setFile,':');
   $commandLine{'param'}="$inst{'directory'}/$inst{'site'}/$inst{'instrument'}".
   			 ".illum";
 }
 else {
   die "ERROR: Specify --param or --inst.\n";
 }
}

#If 'in' and 'out' defined, get list of subsets to complete names of 
#input/outputs
@inFiles = ();
@outFiles = ();
if (defined $commandLine{'in'} and defined $commandLine{'out'}) {
  if (defined @ioimages) { 
  	die "ERROR: Input error. No image name allowed when --in/--out is used.\n";
  }
  @inFiles = glob("$commandLine{'in'}*.$extension");
  @subsets = ();
  foreach $inFile (@inFiles) {
    $inFile =~ /$commandLine{'in'}(\w*)\.$extension/;
    push @subsets, $1;
    push @outFiles, "$commandLine{'out'}$1.$extension";
  }
}
elsif (defined @ioimages) {
  unless ($#ioimages + 1 == 2) {	#2 images: input + output
  	die "ERROR: Input error.  Missing input or output images.\n";
  }
  if (defined $commandLine{'in'} or defined $commandLine{'out'}) {
  	die "ERROR: Input error. Use i/o images OR --in/--out format.\n";
  }
  push @inFiles, $ioimages[0];
  push @outFiles, $ioimages[1];
  if (defined $commandLine{'subset'}) { push @subsets, $commandLine{'subset'}; }
  else { push @subsets, ''; }
}
else {
  die "ERROR: Input error.  Both --in and --out must be defined.\n";
}

for ($i=0; $i<=$#inFiles; $i++) {
  print "\nMake illumination for $inFiles[$i] ...\n";
  $command="$filter $inFiles[$i] -o $outFiles[$i] --type=$filterType".
  	   " --param=$commandLine{'param'}";
  if (defined $commandLine{'log'}) {
    $command .= " --log=$commandLine{'log'}";
  }
  if (system ("$command") != 0) {
    print "\n*** Error while computing illumination on $inFiles[$i]\n";
    if (defined $commandLine{'log'}) {
      Iraf::printlog($commandLine{'log'},
      	    "\tERROR: Error while computing illumination on $inFiles[$i]\n");
    }
    exit($status=1);
  }

  # Replace low pixel values by 1.
  $command="$imreplace $outFiles[$i] --value=1 --upper=0.8";
  if (defined $commandLine{'log'}) { $command .= " --log=$commandLine{'log'}"; }
  system "$command";

  # Calculate average flux (CCDMEAN)
  $pipe="$imstat $outFiles[$i] --fields='mean'";
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
  else {		#Some serious error
    die "ERROR: Error while calculating CCDMEAN for $outFiles[$i]\n";
  }

  # Normalize  ** as long as CCDMEAN is there ccdproc will normalize
  #$command="$normalize $input --stat=average";
  #if (defined $commandLine{'log'}) { $command .= " $commandLine{'log'}"; }
  #system "$command";

  # Calculate time for CCDMEANT and MKILLUM
  ($date,$time) = Util::datenTime(time);
  $mkIllumValue = "$date $time Illumination correction created from $inFiles[$i]";
  $ccdmeant = time - timegm($IRAFbasetime{'sec'}, $IRAFbasetime{'min'},
  			    $IRAFbasetime{'hours'}, $IRAFbasetime{'mday'},
			    $IRAFbasetime{'mon'}, $IRAFbasetime{'year'});
  
  # Change title and edit header. (mkillum processing flag, include mean in header)
  # CCDMEAN =             99.76889
  # CCDMEANT =  nb seconds since 00:00:00 1-Jan-80 UTC
  # MKILLUM = 'Apr 12 16:22 Illumination correction created from SkyPabet.fits'

  $commandLine{'param'} =~ /\/(\w+)\.illum$/;
  $instrument = $1;
  $newTitle="Illumination - $subsets[$i]-band";
  system ("$ccdhedit $outFiles[$i] 'OBJECT' '$newTitle' 'string' --inst=$instrument");
  system ("$ccdhedit $outFiles[$i] 'CCDMEAN' '$ccdmean' 'real' --inst=$instrument");
  system ("$ccdhedit $outFiles[$i] 'CCDMEANT' '$ccdmeant' 'integer' --inst=$instrument");
  system ("$ccdhedit $outFiles[$i] 'MKILLUM' '$mkIllumValue' 'string' --inst=$instrument");
  if (defined $commandLine{'log'}) {
    Iraf::printlog($commandLine{'log'},"$outFiles[$i]: $mkIllumValue\n");
  }
  print "done\n";
}

$|=0;		#OUTPUT_AUTOFLUSH OFF

exit($status);
