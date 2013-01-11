#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imcombine
#Version: 1.0.2
#  Combine images using various algorithms
#
#Usage: imcombine images/-l list -o output --log=logfile --combine=(average|median)
#		--reject=type --scale=type --nlow=# --nhigh=#
#
#	images			: images to combine
#	-o output		: name of the output image
#	--log=logfile		: name of the log file (default: no logs)
#	--combine		: Type of combining operation
#	--reject		: type of rejection operation
#	--scale		: type of scaling operation
#	--nlow,--nhigh	: number of low or high pixel to reject (minmax)

use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#Set defaults
$imtype=$Images::imtype;
$moreParam{'output'} = 'default.fits';
$moreParam{'rejmask'} = '';
$moreParam{'plfile'} = '';
$moreParam{'sigma'} = '';
$moreParam{'logfile'} = 'STDOUT';
$moreParam{'combine'} = 'average';
$moreParam{'reject'} = 'none';
$moreParam{'project'} = 'no';
$moreParam{'outtype'} = 'real';
$moreParam{'offsets'} = 'none';
$moreParam{'masktype'} = 'none';
$moreParam{'maskvalue'} = 0;
$moreParam{'blank'} = 0.;
$moreParam{'scale'} = 'none';
$moreParam{'zero'} = 'none';
$moreParam{'weight'} = 'none';
$moreParam{'statsec'} = '';
$moreParam{'expname'} = '';
$moreParam{'lthreshold'} = 'INDEF';
$moreParam{'hthreshold'} = 'INDEF';
$moreParam{'nlow'} = 1;
$moreParam{'nhigh'} = 1;
$moreParam{'nkeep'} = 1;
$moreParam{'mclip'} = 'yes';
$moreParam{'lsigma'} = 3.;
$moreParam{'hsigma'} = 3.;
$moreParam{'rdnoise'} = 0.;
$moreParam{'gain'} = 1.;
$moreParam{'snoise'} = 0.;
$moreParam{'sigscale'} = 0.1;
$moreParam{'pclip'} = -0.5;
$moreParam{'grow'} = 0.;

#Initialise variables
@listOfImages=();

print "Combining images.\n";

#Read command line
while ($_ = shift @ARGV) {
 SWITCH: {
   if ( /-o\b/ ) {$moreParam{'output'} = shift @ARGV; last SWITCH;}
   if ( /-l\b/ ) {$list = shift @ARGV; last SWITCH;}
   if ( /--/ ) {
   	s/--//;
	($key, $value) = split /=/, $_, 2;
	$moreParam{$key} = $value;
	last SWITCH;
   }
   s/\.fits$|\.imh$//;	# img.fits -> img
   push @listOfImages, $_;
 }
}

#Read the file with the list of images
if (defined $list) {
  open (LIST, "<$list") or die "Unable to open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh//;	# img.fits -> img
    push @listOfImages, $_;
  }
  close(LIST);
}

#Insert the right image type extension
foreach $image (@listOfImages) {
  $image .= '.'.$imtype;
}

if (defined $moreParam{'log'}) {
  $moreParam{'logfile'} = $moreParam{'log'};
}

if ((length (join ',', @listOfImages)) > 511) {
  print "WARNING: Input line too long for IRAF (",
  	length (join ',',@listOfImages)," ch). Writing to a scratch file ... ";
  open(SCRATCH,">scratch") or die "Unable to open a scratch file.\n";
  foreach $_ (@listOfImages) {
    print SCRATCH "$_\n";
  }
  close(SCRATCH);
  print "done\n";
}

Images::imcombine(\%moreParam,@listOfImages);

if (-e 'scratch') {unlink 'scratch';}

exit(0);

