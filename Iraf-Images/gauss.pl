#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: gauss
#Version: 1.0.0
#
# Usage: gauss.pl (images/-l list) [-v] (-o root/--output=output) --sigma=sigma
#			[--log=logfile]

use FileHandle;
use File::Basename;	#for fileparse()
use lib qw(/home/labrie/prgp/include);
use Iraf::Images;

#Set default
$imtype=$Image::imtype;
$root='conv';
$param{'ratio'}=1.;
$param{'theta'}=0.;
$param{'nsigma'}=4.;
$param{'bilinear'}='yes';
$param{'boundary'}="nearest";
$param{'constant'}=0.;
$VERBOSE=0;

#Initialise variables
@listOfImages = ();
@outputImages = ();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^-l/ ) 	{$list = shift @ARGV; last SWITCH;}
    if ( /^-o/ )	{$root = shift @ARGV; last SWITCH;}
    if ( /^-v/ )	{$VERBOSE = 1; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      ($key,$value) = split /=/;
      $param{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if (defined $list) {
  $fhrd = new FileHandle "< $list" or die "Unable to open $list for reading.\n";
  while (<$fhrd>) {
    s/\n//;
    s/\.fits$|\.imh$//;
    push @listOfImages, $_;
  }
  $fhrd->close;
}

#Append the image type extension
foreach $_ (@listOfImages) { $_ .= '.'.$imtype; }

#Get list of output images
if (defined $param{'output'}) {
   @outputImages = split /,/, $param{'output'};
} else {
   foreach $input (@listOfImages) {
     ($name,$path,$suffix) = fileparse($input,$imtype);
     $output = $path.'/'.$root.$name.$suffix;
     $output =~ tr/\///s;
     push @outputImages, $output;
   }
}
if ($#outputImages != $#listOfImages) {
    die "ERROR: Number of output image not equal to number of inputs (gauss.pl)\n";
}

foreach $key (keys %param) { $allParam{$key} = $param{$key}; }

#Convolve
Image::gauss(\%allParam,\@listOfImages,\@outputImages);

exit(0);
