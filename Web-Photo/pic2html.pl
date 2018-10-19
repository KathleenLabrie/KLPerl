#!/usr/bin/perl
#
#Package: Web:Photo
#Name: pic2html
#Version: 0.1.0
$prog = 'pic2html';
$version = '0.1.0';
#       Take a list of pictures and create an HTML page displaying them.
#
# Usage: pic2html [-o output] [-a archive] [--geometry=ncol,width] 
#                   [-t|--title=title] [-v|--verbose] files
#        pic2html [-o output] [-a archive] [--geometry=ncol,width]
#                   [-t|--title=title] [-v|--verbose] -l fileList
#        pic2html -h|--help
#        pic2html --version
#
#       files:          List of files
#       -a archive:     Root name of the output compressed archive with HTML 
#                       file and images.
#       -h, --help:     Print help to STDOUT
#       -l fileList:    Specify file with list of files
#       -o output:      Output html file. [default: STDOUT, or based on name of
#                       the archive if -a is used]
#       -v, --version:  Verbose on
#       --version:      Print version
#
# Needs:
#   Util.pm
#   HTML::Stream
#

use lib qw(/Users/klabrie/prgp/include);
use Util;
use Web;
use FileHandle;
use HTML::Stream;

# Definitions
@recognizedOptions = ( 'geometry', 'help', 'title', 'verbose', 'version' );
$USAGE = "Usage: pic2html [-o output] [-a archive] [--geometry=ncol,width]\n".
         "             [-t|--title=title] [-v|--verbose] files\n".
         "       pic2html [-o output] [-a archive] [--geometry=ncol,width]\n".
         "             [-t|--title=title] [-v|--verbose] -l fileList\n".
         "       pic2html -h|--help\n".
         "       pic2html --version\n";
$HELP = "$USAGE\n".
        "\tfiles:           List of files.\n".
        "\t-a archive:      Root name of the output compressed archive with\n".
        "\t                 HTML file and images.\n".
        "\t--geometry=ncol,width\n".
        "\t                 Number of columns and display width of the pics\n".
        "\t                 [default: 5 columns, width=150pix]\n".
        "\t-h, --help:      Print help to STDOUT\n".
        "\t-l fileList:     Specify file with list of input files.\n".
        "\t-o output:       Output HTML file. [default: STDOUT, or based on\n".
        "\t                 name of the archive if -a is used]\n".
        "\t-t title, --title=title\n".
        "\t                 Page's title. [default: 'Photo Album'\n".
        "\t-v, --verbose:   Verbose on\n".
        "\t--version:       Print version\n";
       
# Defaults
$param{'geometry'} = '5,150';
$param{'help'} = $FALSE;
$param{'output'} = 'STDOUT';
$param{'title'} = 'Photo Album';
$param{'version'} = $FALSE;
$param{'verbose'} = $FALSE;
$bgcolor = '#000000';
$fgcolor = '#C0C0C0';

# Initialize
@files = ();
$ncols = 0;
$width = 0;

# Parse command line
while ($_ = shift @ARGV) {
   SWITCH: {
      if ( /^--/ ) {
         s/^--//;
         if ( /=/ )            { ($key,$value) = split /=/; }
         else                  { $key = $_; $value = $TRUE; }
         if ( grep { /^$key$/ } @recognizedOptions ) {
            $param{$key} = $value;
            last SWITCH;
         }
         else { die "ERROR: Unrecognized options, '$key'\n"; }
      }
      if ( /^-/ ) {
         if ( /^-a$/ ) { $param{'archive'} = shift @ARGV; last SWITCH;  }
         if ( /^-h$/ ) { $param{'help'} = $TRUE; last SWITCH;           }
         if ( /^-l$/ ) { $param{'fileList'} = shift @ARGV; last SWITCH; }
         if ( /^-o$/ ) { $param{'output'} = shift @ARGV; last SWITCH;   }
         if ( /^-t$/ ) { $param{'title'} = shift @ARGV; last SWITCH;    }
         if ( /^-v$/ ) { $param{'verbose'} = $TRUE; last SWITCH;        }
         die "$MSG_INPUT_ERROR ($_)\n$USAGE";
      }
      push @files, $_;
   }
}

if ($param{'help'})     { print "$HELP"; exit(0); }
if ($param{'version'})  { print "$prog v$version\n"; exit(0); }

# Parse and check 'geometry'
#  !!!! check if ncols and width are integers !!!!
($ncols,$width) = split /,/, $param{'geometry'};
($! = $INPUT_ERROR and die "$MSG_INPUT_ERROR (--geometry=$param{'geometry'})\n")
    if ( ($ncols == 0) || ($width == 0) );

# Read the file with the list of pictures
if (defined $param{'fileList'}) {
   $fhrd = new FileHandle "<$param{'fileList'}" or ($! = $FILE_READ_ERROR
        and die "$MSG_FILE_READ_ERROR ($param{'fileList'})\n");
        
   while (<$fhrd>) {
      s/\n//;
      push @files, $_;
   }
  
   $fhrd->close() or ($! = $FILE_CLOSE_ERROR and 
        die "$MSG_FILE_CLOSE_ERROR ($param{'fileList'})\n");
}

# Check input pics
foreach $file (@files) {
   ($! = $FILE_NOT_FOUND and die "$MSG_FILE_NOT_FOUND ($file)\n")
        if (not -e $file);
}

if ((defined $param{'archive'} ) && ($param{'output'} == 'STDOUT')) {
   $param{'output'} = $param{'archive'}.'.html';
}

# Open an HTML stream
if ($param{'output'} ne 'STDOUT') {
   $fhwr = new FileHandle ">$param{'output'}" or
                ($! = $FILE_OPEN_ERROR and
                die "$MSG_FILE_OPEN_ERROR ($param{'output'})\n".
                    "$MSG_FILE_WRITE_ERROR\n");
} else { $fhwr = $param{'output'}; }
$HTML = new HTML::Stream $fhwr;

# Write up the header for the HTML page
Web::htmlhead($HTML, $param{'title'}, $bgcolor, $fgcolor);

# Write the body
$HTML   -> H1 -> t($param{'title'}) -> _H1
        -> BR;

$HTML   -> TABLE -> TR;
$column = 1;
foreach $file (@files) {
   $HTML   -> TD
           -> A(HREF=>"$file") -> IMG(SRC=>$file, WIDTH=>$width) -> _A
           -> _TD;
   $HTML   -> nl;
   $column += 1;
   if ($column > $ncols) {
      $HTML   -> _TR
              -> TR;
      $column = 1;
   }
}
$HTML   -> _TR -> _TABLE;

# Write up the footer for the HTML page
Web::htmlfoot($HTML);

# Close the HTML stream
#    closed upon exit.  There does not seem to be a 'close' function.
if ($param{'output'} ne 'STDOUT') {
   $fhwr->close();
}

if (defined $param{'archive'}) {
   $cmd = "tar cvzf $param{'archive'}.tar.gz $param{'output'} @files";
   system ("$cmd");
}

exit(0);
