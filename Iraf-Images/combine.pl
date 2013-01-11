#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imcombine
#Version: 1.0.2
#	Combine selected images
#
#Usage: combine images/-l list -o output --select='expr1,expr2..exprN'
#		--scale=type --log=logfile
#
#	images		: Full set of images
#	-l list	: File with full set of images
#	-o output	: name of output file
#	--select	: selection boolean expressions
#	--scale=type  : type of scaling (none if absent, median,mean)
#	--log=logfile : name of log file
#
#Needs:
# %%%/astro/labrie/progp/iraf/images/hselect.pl%%%
# %%%/astro/labrie/progp/iraf/images/imcombine.pl%%%

use File::Basename;	#for dirname()
use FileHandle;
use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#Set defaults
$hselect= $Images::hselect;
$imcombine= $Images::imcombine;
$moreParam{'log'}='STDOUT';
$moreParam{'combine'}='median';
$moreParam{'reject'}='sigclip';
$moreParam{'nlow'}=0;
$moreParam{'nhigh'}=1;
$moreParam{'lsigma'}=0;
$moreParam{'hsigma'}=3;
$fields='$I';

#Initialise variables
@listOfImages=();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /-l\b/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /-o\b/ ) {$output = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      ($key,$value) = split /=/, $_, 2;
      $moreParam{$key} = $value;
      last SWITCH;
    }
    s/\.fits$|\.imh$//;	# img.fits -> img
    push @listOfImages, $_;
  }
}

#Read the file with the list of images
if (defined $list) {
  open(LIST,"<$list") or die "Unable to open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;	#img.fits -> img
    push @listOfImages, $_;
  }
  close(LIST);
}

#Parse 'select'
@exprs = split /,/, $moreParam{'select'};

#Select
foreach $expr (@exprs) {
  print "Select: $expr\n";
  @selected=();
  $command = "$hselect @listOfImages --fields='$fields' --expr='$expr'";
  #system ("$command");
  $fhPipeOut = new FileHandle "$command |";
  while (<$fhPipeOut>) {
    s/(^\s|\n)//g;
    s/> > images: fields: expr: //;
    next if />/;
    push @selected, $_;
  }
  $fhPipeOut->close;
  @listOfImages=();
  @listOfImages=@selected;
}

#Combine
$options = "--log=$moreParam{'log'} --combine=$moreParam{'combine'} ".
           "--reject=$moreParam{'reject'} ";
if (defined $moreParam{'scale'}) { 
  if (not defined $moreParam{'statsec'}) {
    print "Please define 'statsec' ( [x1:x2,y1:y2] ): ";
    $moreParam{'statsec'} = <STDIN>;
    $moreParam{'statsec'} =~ s/\n//;
  }
  $options .= "--scale=$moreParam{'scale'} --statsec='$moreParam{'statsec'}' ";    
}
SWITCH: {
  if ($moreParam{'reject'} eq 'sigclip') {
    $options .= "--lsigma=$moreParam{'lsigma'} --hsigma=$moreParam{'hsigma'}";
    last SWITCH;
  }
  if ($moreParam{'reject'} eq 'minmax') {
    $options .= "--nlow=$moreParam{'nlow'} --nhigh=$moreParam{'nhigh'}";
    last SWITCH;
  }
  die "ERROR: Unknown rejection algorithm.\n";
}

system ("$imcombine @selected -o $output $options");

exit(0);
