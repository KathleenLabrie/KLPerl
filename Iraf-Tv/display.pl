#!/usr/local/bin/perl -w
#
#Package: Iraf::Tv
#Name: display
#Version: 1.1.0
#
#Command-line : image -stdimage=imt???

use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::Tv;

#Set defaults
$imtype=$Tv::imtype;
#$moreParam{'stdimage'}=$Tv::stdimage;
$graphcap=$Tv::graphcap;

#Defaults for display
%defParam = (
	frame => '1',
	erase => 'yes',
	select_frame => 'yes',
	overlay => '',
	ocolor => 'green',
	bpmask => 'BPM',
	bpdisplay => 'none',
	bpcolor => 'red',
	xcenter => '0.5',
	ycenter => '0.5',
	xsize => '1.',
	ysize => '1.',
	fill => 'no',
	xmag => '1.',
	ymag => '1.',
	order => '0',
	ztrans => 'linear',
	zscale => 'yes',
	zmask => '',
	nsample => '1000',
	contrast => '0.25',
);

#Read command-line arguments
if (!(defined @ARGV)) {
  print "Image: ";
  $image=<STDIN>;
  $image =~ s/\n//;
  SWITCH: {
    if ($image =~ /\.fits$/) { $imtype = 'fits'; last SWITCH;}
    if ($image =~ /\.imh$/)  { $imtype = 'imh'; last SWITCH;}
  }
  $image =~ s/\.fits$|\.imh$//;
  $image .= '.'.$imtype;
  print "Stdimage: ";
  $moreParam{'stdimage'}=<STDIN>;
  $moreParam{'stdimage'} =~ s/\n//;
}
else {
  while ($_ = shift @ARGV) {
    SWITCH: {
      if ( /--/ ) {
        s/--//;
	 if (/=/) { ($key,$value) = split /=/; }
	 else     { $key = $_; $value = 1;     }
	 $moreParam{$key} = $value;
	 last SWITCH;
      }
      s/\.fits$|\.imh$//;		#img.fits -> img
      if (!defined $image) { $image = $_; }
      else {die "Only one image can be displayed at a time.\n";}
    }
  }
  $image .= '.'.$imtype;
}

#elsif ($#ARGV+1 > 1) {
#  die "No options are yet implemented.  Provide only the name of one image.\n";
#}
#else {
#  while ($_ = shift @ARGV) {
#    $image = $_;
#  }
#}

foreach $key (keys %defParam) { $allParam{$key} = $defParam{$key}; }
foreach $key (keys %moreParam) { $allParam{$key} = $defParam{$key}; }

#Display image
Tv::display(\%allParam,$graphcap,$image);

exit(0);

#-------------------------

