#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imreplace
#Version: 1.0.0
#  Replace the value of a sample of pixels having values between 'lower' and 
#  'upper'.
#
#Command-line : images/-l list --value=# (--imaginary=# --lower=# --upper=# 
#		--radius=# -log logfile)
#
#	images		: Images to fix
#	-l list	: Name of the file containing the list of images
#	-log logfile	: Name of the logfile
#	--value	: New value of the pixels in the window
#	--imaginary	: Fouille-moe (Default = 0.)
#	--lower	: Lower boundary of the window (Default = INDEF)
#	--upper	: Upper boundary of the window (Default = INDEF)
#	--radius	: Radius around pixel (Default = 0.)

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#**** WARNING ****
$"=',';
#**** WARNING ****

#Set defaults
$imtype=$Images::imtype;
$moreParam{'imaginary'}=0.;
$moreParam{'lower'}='INDEF';
$moreParam{'upper'}='INDEF';
$moreParam{'radius'}=0.;

#Initialise variables
@listOfImages=();

$|=1;			#OUTPUT_AUTOFLUSH ON
print "Replace low values.\n";

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-log/) {$logfile = shift @ARGV; last SWITCH;}
    if ( /-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      ($key,$value) = split /=/;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;	# img.fits -> img
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if (defined $list) {
  open(LIST,"<$list") or die "Cannot open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;	# img.fits -> img
    push @listOfImages, $_;
  }
  close(LIST);
}

#Insert the right image type extension
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

#Replace pixel values
if (defined $logfile) {
  open(LOG, ">>$logfile") or die "Cannot open $logfile.";
  foreach $image (@listOfImages) {
    print LOG "$image: Replaced pixel values between $moreParam{'lower'} and".
    		" $moreParam{'upper'} with $moreParam{'value'}.\n";
  }
  close(LOG);
}
Images::imreplace(\%moreParam,@listOfImages);
$|=0;		#OUTPUT_AUTOFLUSH OFF

exit(0);
