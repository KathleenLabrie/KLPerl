#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imstatsel
#Version: 2.2.4
#
#Command-line : (images[x1:x2,y1:y2]/-l list) [--section=[x1:x2,y1:y2] 
#			--fields='field1,field2..' --keyword=keyword
#			--select=criterium --stype=selkeytype --translate --output=root --multiple
#			--sort=type --keytype=keytype] 
#			[--lower=llimit --upper=ulimit]
#	images[x1:x2,y1:y2]	   : Images names flanked by a section definition if
#				     required.
#	-l list		   : Name of the file containing the list of images.
#	--section=[x1:x2,y1:y2] : Define a section that will be applied to all
#				     images without a section specified.
#	--keyword=keyword	   : Keyword used for first level selection.
#	--translate		   : Translate the keyword using an instrument .dat
#	--select=criterium	   : Selection (2nd level) criterium. If not defined -> all
#	--stype=selkeytype	   : Type of the value of the 2nd level selection
#	--sort=type		   : Sort the images with value. (1st level sel.)
#				     Types: num:	numerically
#					     des:	numerically, descending
#	--multiple		   : Multiple output files?  One file per value.
#	--output=root		   : Root/name of the output file. Value is 
#				     appended when 'multiple'.
#	--keytype=keytype	   : Type of the value.  eg. float
#	--lower=llimit	   : Lower pixel value
#	--upper=ulimit	   : Upper pixel value
#
# Examples:
#	imstat *d.fits --section='[380:400,630:650]' --fields='midpt' 
#		--keyword=exptime --keytype=float --translate --sort=num 
#		--multiple --output=darklevel
#
#	=> For each exptime, one file 'darklevel#.dat', containing the median
#	   of each image with that exptime, will be created.
#
#	imstat *.fits[40:60,40:60] --keyword=imagetyp --select=dark --translate
#
#	=> Default fields will be written to stdout for dark images.  Adding
#	   --output=somename.dat would have written the data to that file.

use FileHandle;
use File::Basename;	#for dirname
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#Define
$getkeyval = $Images::getkeyval;
$imstatistics = dirname($0).'/imstatistics.pl';
$setFile="$HOME/iraf/privuparm/setinst.par";

#Set defaults
$imtype=$Images::imtype;
$moreParam{'fields'}='image,npix,mean,midpt,stddev,min,max';
$moreParam{'translate'} = 0;
$moreParam{'multiple'} = 0;
$moreParam{'keytype'} = 'float';
$outputtype = 'dat';
$moreParam{'output'} = 'STDOUT';
$SELSUBSET=0;		# true when selection in on subset and translate is true

#Initialise variables
@listOfImages = ();
@namesOnly = ();

#Read in command-line arguments
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^-l$/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
      s/--//;
      if (/=/) { 
        @more=();
        ($key,$value,@more) = split /=/;
	 $value = join '=', $value, @more;
      }
      else     { $key = $_; $value = 1;    }      
      $moreParam{$key} = $value;
      last SWITCH;
    }
    (/\[/) ? s/\.fits\[|\.imh\[/\[/ : 		# img.fits[...] -> img[...]
    			  s/\.fits$|\.imh$//;	# img.fits      -> img
    push @listOfImages, $_;
  }
}

#Translate $moreParam{'sort'}
SWITCH: {
  if (!defined $moreParam{'sort'}) {last SWITCH;}
  if ($moreParam{'sort'} =~ /^num/) {
  	$moreParam{'sort'} = 'numerically';
	last SWITCH;
  }
  if ($moreParam{'sort'} =~ /^rev/) {
  	$moreParam{'sort'} = 'decreasing';
	last SWITCH;
  }
  die "ERROR: No such type of sorting.\n";
}

#Translate $moreParam{'keytype'}, and $moreParam{'stype'}
@typelist = ();
push @typelist, 'keytype' if (defined $moreParam{'keyword'});
push @typelist, 'stype'   if (defined $moreParam{'select'});

#Parse second level criterium
if (defined $moreParam{'select'}) {
  $moreParam{'select'} =~ s/\s*//g;
  $moreParam{'select'} =~ /(\w*)(\W*)(\w*)/;
  $moreParam{'keyselect'} = $1;
  $moreParam{'opselect'} = $2;
  $moreParam{'limitselect'} = $3;
  $moreParam{'opselect'} =~ s/^=$/==/;
  if ($moreParam{'stype'} eq 'string') {
    SWITCH: {
      if ($moreParam{'opselect'} eq '==') {
      		$moreParam{'opselect'} = 'eq';
		last SWITCH;
      }
      die "ERROR: No such operator in select.\n";
    }
  }
}

#Read the file with the list of images
if (defined $list) {
  open(LIST,"<$list") or die "Cannot open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    (/\[/)   ?   s/\.fits\[|\.imh\[/\[/ :  # img.fits[...] -> img[...]
    		   s/\.fits$|\.imh$//;	 # img.fits      -> img
    push @listOfImages, $_;
  }
  close(LIST);
}

#Insert the right image type extension, and append the section if necessary
foreach $image (@listOfImages) {
  if ($image =~ /\[/) {
    $image =~ s/\[/\.$imtype\[/;
  }
  elsif (defined $moreParam{'section'}) {
    $image .= '.'.$imtype.$moreParam{'section'};
  }
  else {
    $image .= '.'.$imtype;
  }
  $image =~ /(.+)\[?/;
  push @namesOnly, $1;
}

#Read setinst.par, if 'translate' true
if ($moreParam{'translate'}) { $paramFile = Iraf::whereParam($setFile); }

#Read project's .dat file, if 'translate' true, and translate keyword
if ($moreParam{'translate'}) {
  $paramFile =~ s/\.cl$/B\.dat/;
  $subsetFile = dirname($paramFile).'/subsets';
  @selkeys=();
  if (defined $moreParam{'keyword'}) { push @selkeys, 'keyword'; }
  if (defined $moreParam{'keyselect'}) {
    push @selkeys, 'keyselect';
    if ($moreParam{'keyselect'} eq 'subset') { $SELSUBSET=1; }
  }
  foreach $key (@selkeys) {
    $moreParam{$key} = Iraf::getTrans($paramFile,$moreParam{$key},2);
  }
}
  
#Get 'value' for each image
if (defined $moreParam{'keyword'}) {
  $pipe = "$getkeyval @namesOnly -k $moreParam{'keyword'} -d $moreParam{'keytype'}";
  $fhPipeOut = new FileHandle "$pipe |";
  @values = <$fhPipeOut>;
  $fhPipeOut->close();
  if (defined $moreParam{'select'}) {
    $pipe = "$getkeyval @namesOnly -k $moreParam{'keyselect'} -d $moreParam{'stype'}";
    $fhPipeOut = new FileHandle "$pipe |";
    @selvalues = <$fhPipeOut>;
    $fhPipeOut->close();
  }
  for ($i=0; $i<=$#listOfImages; $i++) {
    $values[$i] =~ s/(^\s+|\n)//g;
    if (defined $moreParam{'select'}) {
      $selvalues[$i] =~ s/(^\s+|\n)//g;
      $selvalues[$i] =~ s/((\w|\s)*?)\s*\#\d*$/$1/;
      if ($SELSUBSET) { $selvalue=Iraf::getTrans($subsetFile,$selvalues[$i],2);}
      else { $selvalue = $selvalues[$i]; }
      #Apply 2nd level selection
      if ($moreParam{'stype'} eq 'string') {
        $test = "lc(\"$selvalue\") $moreParam{'opselect'} lc(\"$moreParam{'limitselect'}\")";
      }
      else {
        $test = "$selvalue $moreParam{'opselect'} $moreParam{'limitselect'}";
      }
      next unless (eval $test);  #... is true.
    }
    push @{ $value_img{$values[$i]} }, $listOfImages[$i];
  }
  undef @values;
  undef @listOfImages;
  undef @namesOnly;
}

sub numerically { $a <=> $b;}
sub decreasing { $b <=> $a;}

#Calculate statistics
if (defined $moreParam{'keyword'}) {
  if (defined $moreParam{'sort'}) {
    $toEval = "sort $moreParam{'sort'} keys %value_img";
    foreach $value (eval $toEval) {
	print "\nStatistics on $moreParam{'keyword'} = $value ...\n";
	if ($moreParam{'multiple'}) {
		$value =~ /(\d+)\.(\d*?)0*$/;
		unless ($moreParam{'output'} eq 'STDOUT') {
		  $output = $moreParam{'output'}.$1.$2.'.'.$outputtype;
		}
		&imstat($output, @{ $value_img{$value} });
		&clean($output);
	}
	else {
		&imstat($moreParam{'output'}, @{ $value_img{$value} });
		unless ($moreParam{'output'} eq 'STDOUT') {
		   &clean($moreParam{'output'});
		}
	}
	print " done\n";
    }
  }
  else {
    foreach $value (keys %value_img) {
       print "\nStatistics on $moreParam{'keyword'} = $value ...\n";
	if ($moreParam{'multiple'}) {
		$value =~ /(\d+)\.(\d*?)0*$/;
		unless ($moreParam{'output'} eq 'STDOUT') {
		  $output = $moreParam{'output'}.$1.$2.'.'.$outputtype;
		}
		&imstat($output, @{ $value_img{$value} });
		&clean($output);
	}
	else {
		&imstat($moreParam{'output'}, @{ $value_img{$value} });
		unless ($moreParam{'output'} eq 'STDOUT') {
		  &clean($moreParam{'output'});
		}
	}
	print " done\n";
    }
  }
}
else {
  &imstat($moreParam{'output'},@listOfImages);
  unless ($moreParam{'output'} eq 'STDOUT') {
     &clean($moreParam{'output'});
  }
}

exit(0);

#-------------------------

#-------------------------\
#      imstatistics        \
#---------------------------\
sub imstat {
  my ($output,@images) = @_;
  my ($totalLength);
  my ($MAXLENGTH) = $Iraf::MAXLENGTH;
  my (@imgs);

  $|=1;		#OUTPUT_AUTOFLUSH ON

  while ( defined $images[0] ) {
    @imgs = ();
    $totalLength = 0;
    while ( ( defined $images[0] ) and 
    		( ($totalLength + length ($images[0])) <= $MAXLENGTH ) )  {
      print $images[0],"\n";
      $totalLength += length ($images[0]) + 1;	# +1 for comma
      push @imgs, shift @images;
    }
    $command = "$imstatistics @imgs --fields=$moreParam{'fields'}";
    if (defined $moreParam{'lower'}) { $command .= " --lower=$moreParam{'lower'}";}
    if (defined $moreParam{'upper'}) { $command .= " --upper=$moreParam{'upper'}";}
    print "---\n";
    if ($output eq 'STDOUT') {
      system ("$command");
    }
    else {
      if (-e $output) {
	 system ("$command >> $output");
      }
      else {
	 system("$command > $output");
      }
    }
  }
  
  $|=0;	#OUTPUT_AUTOFLUSH OFF

  return();
}


#-------------------------\
#         clean            \
#---------------------------\

sub clean {
  my ($file) = @_;
  my (@lines,$line);

  open (INPUT, "<$file") or die "Unable to open $file for reading.\n";
  @lines = <INPUT>;
  close (INPUT);
  open (OUTPUT, ">$file") or die "Unable to open $file for writting.\n";
  foreach $line (@lines) {
    next if ($line =~ /^>/);
    $line =~ s/^\s+//;
    print OUTPUT $line;
  }
  close (OUTPUT);

  return();
}
