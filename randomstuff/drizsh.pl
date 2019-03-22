#!/usr/local/bin/perl -w
#
# Calculate drizzle shifts
#
# Usage: drizsh input factor [-o output]
#
#	input: 		imalign logfile
#	factor:		drizzle factor (eg. 2 for blkrep x 2)
#	-o output:	output file name. x-shift, y-shift in col 1 and 2.
#

use FileHandle;
use lib qw(/home/labrie/prgp/include);
use Util;		#for round()

#Defaults
$fhwr = STDOUT;

#Read command line
$input = shift @ARGV;
$factor = shift @ARGV;
while ($_ = shift @ARGV) {
 SWITCH: {
 	if ( /^-o$/ ) { $output = shift @ARGV; last SWITCH; }
 }
}

$fhrd = new FileHandle "<$input" or die "Unable to open file, $input.\n";
@inlines = <$fhrd>;
$fhrd->close() or die "Unable to close file, $input.\n";

$notthere = 1;
@xshifts = ();
@yshifts = ();
@imnames = ();
foreach $_ (@inlines) {
  if ( /^#Shifts/ ) { $notthere = 0; next; }
  next if ( $notthere );
  last if ( /^\s*\n/ );
  @cols = split;
  push @xshifts, Util::round($cols[1]*$factor);
  push @yshifts, Util::round($cols[3]*$factor);
  push @imnames, $cols[0];
}

if (defined $output) { $fhwr = new FileHandle ">$output" or 
				die "Unable to open file, $output.\n"; }
for ($i=0; $i<=$#xshifts; $i++) {
  print $fhwr "$xshifts[$i]\t$yshifts[$i]\t$imnames[$i]\n";
}
if (defined $output) { $fhwr->close() or die "Unable to close file, $output.\n";}

exit(0);
