#!/usr/local/bin/perl -w
#
#Package: Util::File
#Name: nmbrline
#Version: 1.0.0
$prog = 'nmbrline';
$version = '1.0.0';
#	Add an ID number to lines in a file.  Can select output column number,
#	starting ID number and increment.
#
# Usage: nmbrline [-c #] [-i #] [-t string] [-#] file1,file2,fileN [--overwrite]
#	 nmbrline -v
#	 nmbrline -h
#
#	file:		filename
#	-c #:		specify output column number of the ID numbers
#	-h:		print help
#	-i #:		specify increment
#	-t string:	specify column separator
#	-v:		print version information
#	-#:		specify starting ID number
#	--overwrite:	overwrite the input file [Default: send to STDOUT]

use lib qw(/home/labrie/prgp/include);
use Util::File;
use FileHandle;

#Definitions
$USAGE = "Usage: nmbrline [-c #] [-#] [-i #] [-t 'string'] file1,file2,fileN [--overwrite]\n".
	 "       nmbrline -v\n".
	 "       nmbrline -h\n";
$HELP =	 "$USAGE\n".
	 "\tfile:\t\tfilename\n".
	 "\t-c #:\t\tspecify output column number of the ID numbers\n".
	 "\t-h:\t\tprint this help\n".
	 "\t-i #:\t\tspecify increment\n".
	 "\t-t 'string':\t\tspecify column separator [Default: spaces]\n".
	 "\t-v:\t\tprint version information\n".
	 "\t-#:\t\tspecify starting ID number\n".
	 "\t--overwrite:\toverwrite the input file [Default: send to STDOUT]\n";
$MSG_INPUT_ERROR_COLUMN = "$ERROR Input error. Column number not numerical.";
$MSG_INPUT_ERROR_INCREMENT = "$ERROR Input error. Increment not numerical.";
$MSG_INPUT_ERROR_START = "$ERROR Input error. Starting number not numerical.";
$MSG_COLUMN_ID_TOO_LARGE = "$ERROR Column for ID too large.";

#Defaults
$param{'column'} = 1;
$param{'help'} = $FALSE;
$param{'increment'} = 1;
$param{'overwrite'} = $FALSE;
$param{'start'} = 1;
$param{'token'} = '\s+';
$param{'tokenout'} = '    ';
$param{'version'} = $FALSE;

#Initialize
@lines=();

#Parse command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^--/ ) {
      s/^--//;
      if (/=/) { ($key,$value) = split /=/; }
      else     { $key = $_; $value = $TRUE; }
      $param{$key} = $value;
      last SWITCH;
    }
    if ( /^-/ ) {
      if ( /^-c$/ )     { $param{'column'} = shift @ARGV; last SWITCH;    }
      if ( /^-h$/ )	{ $param{'help'} = $TRUE; last SWITCH;            }
      if ( /^-i$/ )     { $param{'increment'} = shift @ARGV; last SWITCH; }
      if ( /^-v$/ )	{ $param{'version'} = $TRUE; last SWITCH;         }
      if ( /^-(\d+)$/ ) { $param{'start'} = $1; last SWITCH;              }
      die "$MSG_INPUT_ERROR ($_)\n$USAGE";
    }
    push @files, $_;
  }
}

if ($param{'help'})    { print "$HELP"; }
if ($param{'version'}) { print "$prog $version\n"; exit(0); }

#Check inputs
($! = $INPUT_ERROR and die "$MSG_INPUT_ERROR_COLUMN\n") if (not $param{'column'} =~ /^\d+$/);
($! = $INPUT_ERROR and die "$MSG_INPUT_ERROR_INCREMENT\n") if (not $param{'increment'} =~ /^\d+$/);
($! = $INPUT_ERROR and die "$MSG_INPUT_ERROR_START\n") if (not $param{'start'} =~ /^\d+$/);
foreach $file (@files) {
  ($! = $FILE_NOT_FOUND and die "$MSG_FILE_NOT_FOUND ($file)\n") 
  							if (not -e $file);
}

#Go through the files and add ID number column
foreach $file (@files) {
  @columns=();
  @newcolumns=();
  #Open, read the file and close
   $fhrd = new FileHandle "< $file" 
   		or 
	($! = $FILE_OPEN_ERROR and 
	die "$MSG_FILE_OPEN_ERROR ($file)\n$MSG_FILE_READ_ERROR\n");
   unless (@lines = <$fhrd>) { 
  	$fhrd->close() or 
		($! = $FILE_CLOSE_ERROR and die "$MSG_FILE_CLOSE_ERROR ($file)\n");
	if ($#lines < 0) { 
	  $! = $FILE_EMPTY_ERROR;
	  die "$MSG_FILE_EMPTY ($file)\n";
	}
	$! = $FILE_READ_ERROR;
  	die "$MSG_FILE_READ_ERROR ($file)\n";
   }
   $fhrd->close() 
   		or 
   	($! = $FILE_CLOSE_ERROR and 
	 die "$MSG_FILE_CLOSE_ERROR ($file)\n$MSG_FILE_READ_ERROR\n");
   
  #For each line split into columns, reorganize and write to @newlines
   $id = $param{'start'};
   @newlines = ();
   foreach $line (@lines) {
     @columns = split /$param{'token'}/, $line;
     if ($param{'column'} > $#columns+2) {
     		$! = $INPUT_ERROR;
     		die "$MSG_COLUMN_ID_TOO_LARGE ($file)\n";
     }
     for ($i=0, $j=0; $i<$#columns+2; $i++) {
       if ($i == $param{'column'}-1) { $newcolumns[$i] = $id;          }
       else			      {$newcolumns[$i] = $columns[$j++]; }
     }
     $id = $id+$param{'increment'};
     push @newlines, join $param{'tokenout'}, @newcolumns;
   }
   
  #Write to STDOUT or overwrite file
   if ($param{'overwrite'}) {
      $fhwr = new FileHandle ">$file" 
     		or 
	 ($! = $FILE_OPEN_ERROR and die "$MSG_FILE_OPEN_ERROR ($file)\n$MSG_FILE_WRITE_ERROR\n");
   } else {
      $fhwr = 'STDOUT';
   }
   foreach $line (@newlines) { print $fhwr "$line\n"; }
   if ($param{'overwrite'}) {
     $fhwr->close() 
     		or 
	 ($! = $FILE_CLOSE_ERROR and die "$MSG_FILE_CLOSE_ERROR ($file)\n$MSG_FILE_WRITE_ERROR\n");
   }
}

exit(0);
