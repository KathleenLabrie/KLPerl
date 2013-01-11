#!/usr/local/bin/perl
#
#Package: Util::File
#Name: checkrd
#Version: 0.1.0
$prog = 'checkrd';
$version = '0.1.0';
#	Find files with read error.
#
# Usage: checkrd [-o output] files
#	 checkrd [-o output] -l fileList
#	 checkrd -h
#	 checkrd --version
#
#	files:		List of files
#	-h, --help:	Print help to STDOUT
#	-l fileList:	Specify file with list of files
#	-o output:	Output file that will receive the list of faulty files.
#			[default: STDOUT]
#	--version:	Print version
#
# Needs:
#

use lib qw(/home/labrie/prgp/include);
use Util::File;
use FileHandle;

#Definitions
@recognizedOptions = ( 'help', 'verbose', 'version' );
$USAGE = "Usage: checkrd [-o output] files\n".
	 "       checkrd [-o output] -l fileList\n".
	 "       checkrd -h\n".
	 "       checkrd --version\n";
$HELP = "$USAGE\n".
	"\tfiles:         List of files\n".
	"\t-h, --help:    Print this help\n".
	"\t-l fileList:   Specify file with list of files\n".
	"\t-o output:     Output file that will receive the list of \n".
	"\t               faulty files.  [default: STDOUT]\n".
	"\t-v, --verbose: Turn on verbose\n".
	"\t--version:     Print version\n";

#Defaults
$param{'help'} = $FALSE;
$param{'output'} = 'STDOUT';
$param{'version'} = $FALSE;
$param{'verbose'} = $FALSE;

#Initialize
@files = ();

#Parse command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^--/ ) {
      s/^--//;
      if ( /=/ )	{ ($key,$value) = split /=/; }
      else		{ $key = $_; $value = $TRUE; }
      if ( grep { /^$key$/ } @recognizedOptions ) {
        $param{$key} = $value;
	last SWITCH;
      }
      else { die "ERROR: Unrecognized options, '$key'\n"; }
    }
    if ( /^-/ ) {
      if ( /^-h$/ ) { $param{'help'} = $TRUE; last SWITCH;           }
      if ( /^-l$/ ) { $param{'fileList'} = shift @ARGV; last SWITCH; }
      if ( /^-o$/ ) { $param{'output'} = shift @ARGV; last SWITCH;   }
      if ( /^-v$/ ) { $param{'verbose'} = $TRUE; last SWITCH;        }
      die "$MSG_INPUT_ERROR ($_)\n$USAGE";
    }
    push @files, $_;
  }
}

if ($param{'help'})	{ print "$HELP"; exit(0); }
if ($param{'version'})	{ print "$prog $version\n"; exit(0); }

#Check inputs
foreach $file (@files) {
  ($! = $FILE_NOT_FOUND and die "$MSG_FILE_NOT_FOUND ($file)\n") 
  	if (not -e $file);
}

#Check for read error
if ( $param{'output'} ne 'STDOUT' ) {
   $fhwr = new FileHandle ">$param{'output'}" or 
   		($! = $FILE_OPEN_ERROR and
		die "$MSG_FILE_OPEN_ERROR ($param{'output'})\n".
		    "$MSG_FILE_WRITE_ERROR\n");
} else { $fhwr = $param{'output'}; }

$line='';
foreach $file (@files) {
  $failure = $FALSE;
  if ( $param{'verbose'} ) { print "$file ... "; }
  $fhrd = new FileHandle "<$file" or 
  		($! = $FILE_OPEN_ERROR and
		die "$MSG_FILE_OPEN_ERROR ($param{'output'})\n".
		    "$MSG_FILE_READ_ERROR\n");
  $line = <$fhrd> or  $failure = $TRUE;
  $fhrd->close() or
  		($! = $FILE_CLOSE_ERROR and
		die "$MSG_FILE_CLOSE_ERROR ($file)\n".
		    "$MSG_FILE_WRITE_ERROR\n");
  if ($failure) {
  	if ($param{'verbose'}) { 
	  print "read error ";
	  if ($param{'output'} eq 'STDOUT') { print "on "; }
	  else { print "\n";}
	}
  	print $fhwr "$file\n";
  } else {
    if ( $param{'verbose'} ) { print "ok\n"; }
  }
}

if ( $param{'output'} ne 'STDOUT' ) {
   $fhwr->close() or
   		($! = $FILE_CLOSE_ERROR and
		die "$MSG_FILE_CLOSE_ERROR ($param{'output'})\n".
		    "$MSG_FILE_WRITE_ERROR\n");
}

exit(0);
