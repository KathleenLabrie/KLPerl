package Util;
use Cwd;	# cwd()

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = (
	tf_h => [qw($FALSE $TRUE)],
	errmsg_h => [qw($ERROR $MSG_FILE_NOT_FOUND $MSG_FILE_OPEN_ERROR
			$MSG_FILE_CLOSE_ERROR $MSG_FILE_READ_ERROR
			$MSG_FILE_WRITE_ERROR $MSG_FILE_EMPTY
			$MSG_INPUT_ERROR)],
	errno_h => [qw($FILE_ACCESS_ERROR $FILE_NOT_FOUND $FILE_OPEN_ERROR
			$FILE_CLOSE_ERROR $FILE_READ_ERROR $FILE_WRITE_ERROR
			$FILE_EMPTY_ERROR $INPUT_ERROR)]
);
Exporter::export_tags('tf_h','errmsg_h','errno_h');

$EPREFIX = '/home/labrie/prgp/util';

$FALSE = 0;
$TRUE = 1;

#Error messages
$ERROR = 'ERROR:';
$MSG_FILE_NOT_FOUND = "$ERROR File not found.";
$MSG_FILE_OPEN_ERROR = "$ERROR Unable to open file.";
$MSG_FILE_CLOSE_ERROR = "$ERROR Unable to close file.";
$MSG_FILE_READ_ERROR = "$ERROR File read error.";
$MSG_FILE_WRITE_ERROR = "$ERROR File write error.";
$MSG_FILE_EMPTY = "$ERROR File is empty.";
$MSG_INPUT_ERROR = "$ERROR Input error.";

#Error codes
$FILE_ACCESS_ERROR = 100;
$FILE_NOT_FOUND = $FILE_ACCESS_ERROR + 1;
$FILE_OPEN_ERROR = $FILE_ACCESS_ERROR + 2;
$FILE_CLOSE_ERROR = $FILE_ACCESS_ERROR + 3;
$FILE_READ_ERROR = $FILE_ACCESS_ERROR + 4;
$FILE_WRITE_ERROR = $FILE_ACCESS_ERROR + 5;
$FILE_EMPTY_ERROR = $FILE_ACCESS_ERROR + 6;
$INPUT_ERROR = 200;

#-------------------------\
#        datenTime         \
#---------------------------\
sub datenTime {
  my ($seconds) = @_;
  my ($date,$time);
  my (@now);
  my (@months) = (Jan,Feb,Mar,Apr,May,Jun,Jul,Aug,Sep,Oct,Nov,Dec);

  (@now) = localtime($seconds);
  $now[5] += 1900;
  if ($now[1] < 10) {$now[1] = '0'.$now[1];}
  $date = $months[$now[4]].' '.$now[3].', '.$now[5];
  $time = $now[2].':'.$now[1];

  return($date,$time);
}

#-------------------------\
#         getLines         \
#---------------------------\
sub getLines {
 my (@files) = @_;
 my (@lines) = ();

 foreach $file (@files) {
   unless (-e $file) {
   	print "ERROR: File not found ($file)\n";
	print "Exit status ($FILE_NOT_FOUND)\n";
	exit($FILE_NOT_FOUND);
   }
   $fhrd = new FileHandle "< $file" or 
   			die "ERROR: Unable to open $file for reading.\n";
   $line = <$fhrd>;
   $line =~ s/\n//;
   push @lines, $line;
   $fhrd->close;
 }

 return(@lines);
}


#-------------------------\
#        getListOf         \
#---------------------------\
sub getListOf {
  my ($searchFor,$searchType,$pattern,$root) = @_;
  my ($element, $originalDir);
  my (@list) = ();
  my (@lines) = ();
  my @junk;

  $originalDir = cwd().'/';
  chdir ($root);
  SWITCH: {
    if ($searchType eq '-l') {
      if (not -e $originalDir.$pattern) {	# not in current directory
        open(INPUT,"<$root$pattern") 
	 		or die "Cannot open $root$pattern for reading.\n";
      } else {			# in current directory
        open(INPUT,"<$originalDir$pattern") 
      			or die "Cannot open $originalDir$pattern for reading.\n";
      }
      @lines=<INPUT>;
      close(INPUT);
      foreach $_ (@lines) {
                s/\n//;
                ($first,@junk) = split;
                push @list, $first;
      }
      last SWITCH;
    }
    if ($searchType eq '-p') {
      $pattern = &parsePattern($pattern);
      opendir (DIR,"$root");
      @tmp = map "$root/$_", grep /^\b($pattern)\b$/, readdir DIR;
      closedir (DIR);
      foreach $element (@tmp) {
        $element =~ s/\/\//\//;
        $test = $searchFor.' '.$element;
        push @list, $element if (eval {$test});
      }
    }
  }

  chdir ($originalDir);
  return(@list);
}

#-------------------------\
#         indexOf          \
#---------------------------\
sub indexOf {
 my ($value,@array) = @_;
 my ($i);

 for ($i=0; $i<$#array; $i++) {
   last if ($value eq $array[$i]);
 }

 return($i);
}

#-------------------------\
#         median           \
#---------------------------\
sub median {
 my (@values) = @_;
 my ($median,$n,@sortedValues);

 sub numerically { $a <=> $b; }

 @sortedValues = sort numerically @values;
 $n = $#sortedValues + 1;
 $median = ($n%2) ? $sortedValues[int($n/2)] :
  		     ($sortedValues[int($n/2)] + $sortedValues[int($n/2)-1])/2.;
 return($median);
}


#-------------------------\
#      parsePattern        \
#---------------------------\

sub parsePattern {
  my ($pattern) = @_;

  $dot = '\.';
  $star = '.*';
  $question = '.';
  $pattern =~ s/\./$dot/g;
  $pattern =~ s/\*/$star/g;
  $pattern =~ s/\?/$question/g;
  
  return ($pattern);
}

#-------------------------\
#          round           \
#---------------------------\
sub round {
 my ($value) = @_;

 if ($value>=0) {
    return ( (abs($value-int($value)) < 0.5) ? int($value) : int($value)+1 );
 } else {
    return ( (abs($value-int($value)) < 0.5) ? int($value) : int($value)-1 );
 }
}

#-------------------------\
#         stddev           \
#---------------------------\
sub stddev {
 my (@values) = @_;
 my ($stddev,$val,$avg);
 my ($sum) = 0;
 my ($numerator) = 0;

 if ($#values == 0) { return(0); }
 foreach $val (@values) { $sum += $val;}
 $avg = $sum / ($#values + 1);
 foreach $val (@values) { $numerator += ($val - $avg) ** 2; }
 $stddev = sqrt( $numerator / ($#values) );

 return($stddev);
}

1;
