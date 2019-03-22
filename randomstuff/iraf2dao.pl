#!/usr/local/bin/perl -w
#
# Take IRAF's DAOfind output and create a properly formatted input file
# for Fortran DAOMATCH.

use FileHandle;

#Constants
@acceptedOptions = ('overwrite');

#Defaults
$fhwr = 'STDOUT';
$moreParam{'overwrite'} = 0;	#FALSE
$cX = 1;
$cY = 2;
$cID = 7;
$cMAG = 3;

while ($a = shift @ARGV) {
  SWITCH: {
  # Options
    if ( $a =~ /^--/ ) {
      $a =~ s/^--//;
      if ( $a =~ /=/ ) { ($key, $value) = split /=/, $a; }
      else             { $key = $a; $value = 1; }
      if ( grep { /$key/ } @acceptedOptions ) {
        $moreParam{$key} = $value;
	last SWITCH;
      }
      else { die "ERROR: Input error. Unknown option, ($key)\n"; }
    }
  # Tags
    if ( $a =~ /^-o$/ ) { $ofile = shift @ARGV; last SWITCH; }
  # Others
    push @others, $a;
  }
}
$ifile = shift @others;
$NX = shift @others;
$NY = shift @others;

$fhrd = new FileHandle "< $ifile";
@lines = <$fhrd>;
$fhrd->close();

@line=();
@line = grep { /DATAMIN/ } @lines;
$line[0] =~ /DATAMIN\s*=\s*([\d\.]+)/;
$LOWBAD = $1;
@line=();
@line = grep { /DATAMAX/ } @lines;
$line[0] =~ /DATAMAX\s*=\s*([\d\.]+)/;
$HIGHBAD = $1;
@line=();
@line = grep { /THRESHOLD/ } @lines;
$line[0] =~ /THRESHOLD\s*=\s*([\d\.]+)/;
$THRESH = $1;


if ( $moreParam{'overwrite'} ) { $fhwr = new FileHandle ">$ifile"; }
if ( defined $ofile ) { $fhwr = new FileHandle ">$ofile"; }
print $fhwr "NL   NX   NY  LOWBAD HIGHBAD  THRESH\n";
printf $fhwr " 2%5d%5d%8.1f%8.1f%8.1f\n",$NX,$NY,$LOWBAD,$HIGHBAD,$THRESH;
print $fhwr "\n";
foreach $line ( @lines ) {
  next if ( $line =~ /^#/ );
  @columns = split /\s+/, $line;
  if ($columns[0] eq '') { shift @columns; }
  printf $fhwr " %5d%9.3f%9.3f%9.3f\n", $columns[$cID-1], $columns[$cX-1], 
  				$columns[$cY-1], $columns[$cMAG-1];
}
if ( $moreParam{'overwrite'} or defined $ofile) { $fhwr->close(); }

exit(0);
