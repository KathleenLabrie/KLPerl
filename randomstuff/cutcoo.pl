#!/usr/local/bin/perl -w
#
# Remove points within the box defined by x1,x2,y1,y2.
#
# coordinates are in column 'X 'and 'Y' of 'file'
#
# cutcoo.pl file x1 x2 y1 y2 [-c X,Y] [--overwrite]

use FileHandle;

#Constants
@acceptedOptions = ('overwrite');

#Defaults
$X = 1;
$Y = 2;
$fhwr = 'STDOUT';

$file = shift @ARGV;
$x1 = shift @ARGV;
$x2 = shift @ARGV;
$y1 = shift @ARGV;
$y2 = shift @ARGV;

while ($argv = shift @ARGV) {
  SWITCH: {
    if ( $argv =~ /^--/ ) {
      $argv =~ s/^--//;
      if ( $argv =~ /=/ ) { ($key, $value) = split /=/, $argv; }
      else       { $key = $argv; $value = 1; }
      if ( grep { /$key/ } @acceptedOptions ) {
        $moreParam{$key} = $value;
        last SWITCH;
      }
      else { die "ERROR: Input error. Unknown option, ($key)\n"; }
    }
    if ( $argv =~ /^-c$/ ) { ($X,$Y) = split /,/, shift @ARGV; } 
  }
}

$fhrd = new FileHandle "< $file";
@lines = <$fhrd>;
$fhrd->close();

$X = $X-1;
$Y = $Y-1;
if ( $moreParam{'overwrite'} ) { $fhwr = new FileHandle ">$file"; }
foreach $line ( @lines ) {
  if ( $line =~ /^#/ ) { print $fhwr "$line"; next; }
  @columns = split /\s+/, $line;
  if ($columns[0] eq '') { shift @columns; }
  next if ( ($columns[$X] >= $x1) and ($columns[$X] <= $x2) and
            ($columns[$Y] >= $y1) and ($columns[$Y] <= $y2) );
  print $fhwr "$line";
}
if ( $moreParam{'overwrite'} ) { $fhwr->close(); }

exit(0);
