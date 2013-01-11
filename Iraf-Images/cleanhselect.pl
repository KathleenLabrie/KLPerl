#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imcombine
#Version: 1.0.0
#  Clean files created by hselect
#
#Usage: cleanhselect filename

use FileHandle;

$filename = $ARGV[0];
$fhrd = new FileHandle "<$filename" or
		die "Unable to open '$filename' for reading.\n";
@lines = <$fhrd>;
$fhrd->close();

$fhwr = new FileHandle ">$filename" or
		die "Unable to open '$filename' for writing.\n";
foreach $_ (@lines) {
  s/^(> > (\w|\s|\:)+\: )//;
  next if (/^>\s*\n?$/);
  print $fhwr $_;
}
$fhwr->close();

exit(0);
