package CCDred;
use Iraf;
use Iraf::Images;
use Util;

use Cwd;		# cwd()
use File::Basename;	#for fileparse(), dirname(), basename()
use File::Copy;		#for copy()
use FileHandle;
use Exporter qw();
@ISA = qw(Exporter);
@EXPORT_OK = qw();

$EPREFIX = '/home/labrie/prgp/iraf/ccdred';

$pkg=$Iraf::pkg_ccdred;
$imtype=$Iraf::imtype;

$align="$EPREFIX/align.pl";
$ccdhedit="$EPREFIX/ccdhedit.pl";
$ccdlist="$EPREFIX/ccdlist.pl";
$ccdlist_sub="$EPREFIX/ccdlist-sub.pl";
$ccdproc="$EPREFIX/ccdproc.pl";
$cr="$EPREFIX/cr.pl";
$darkcombine="$EPREFIX/darkcombine.pl";
$dcsel="$EPREFIX/dcsel.pl";
$flatcombine="$EPREFIX/flatcombine.pl";
$mkfringe="$EPREFIX/mkfringe.pl";
$mkillum="$EPREFIX/mkillum.pl";
$reduc="$EPREFIX/reduc.pl";
$skycombine="$EPREFIX/skycombine.pl";
$zerocombine="$EPREFIX/zerocombine.pl";
$verifyimg="$EPREFIX/verifyimg.pl";

#Error codes
$FILE_NOT_FOUND = 101;
$NO_CONVERGENCE = 501;

$DEBUG = 0;
$VERBOSE = 1;
$INSTRUMENT = 2;
$LOGFILE = 3;
$CHECKCAM = 4;

$VERIFICATION = 1;		#1 << 0
$COPYOVER = 2;			#1 << 1
$OVERSCAN = 4;			#1 << 2
$TRIM = 8;			#1 << 3
$ZEROCOMB = 16;			#1 << 4
$ZERO = 32;			#1 << 5
$DARKCOMB = 64;			#1 << 6
$DARK = 128;			#1 << 7
$FLATCOMB = 256;		#1 << 8
$FLAT = 512;			#1 << 9
$FIXPIX = 1024;			#1 << 10
$MOVFIXPIX = 2048;		#1 << 11
$SLICE = 4096;			#1 << 12
$SKYCOMB = 8192;		#1 << 13
$MKILLUM = 16384;		#1 << 14
$ILLUM = 32768;			#1 << 15
$MKFRINGE = 65536;		#1 << 16
$FRINGE = 131072;		#1 << 17
$DCSEL = 262144;		#1 << 18
$DC = 524288;			#1 << 19

$CONVOLVE = 1;			#1 << 0
$REGISTER = 2;			#1 << 1
$FINDSHIFT = 4;			#1 << 2
$SHIFT = 8;			#1 << 3
$CLEAN = 16;			#1 << 4

#Oke's Data
$camBoundary000000 = 000000;  #epoch of the change
$camBoundary831000 = 831000;
$camBoundary831012 = 831012;
$camBoundary831013 = 831013;
$camBoundary840524 = 840524;
$camBoundary840927 = 840927;
$camBoundary840928 = 840928;
$camBoundary840930 = 840930;
$camBoundary850323 = 850323;
$camBoundary850324 = 850324;
$camBoundary870926 = 870926;
$camBoundary890409 = 890409;
$camBoundary890831 = 890831;
$camBoundary901000 = 901000;

$DEFAULT_PARAM_FILE = 'align.param';
$SIGN_RA = -1;
$SIGN_DEC = 1;
$GUESS_SUFFIX = 'fcoo';		#when first guess comes from file
$CONV_PREFIX = 'conv';
$CONV_SIGMA = 2;
$REG_CUT = 0.;
$REG_PREFIX = '';
$REG_SUFFIX = 'reg';	#don't change this. hard-coded in easyreg
$REG_BOX = 51;
$REG_SECTION = '[301:700,301:700]';
$FIT_EXT = 'fit';
$CR_PREFIX = 'cr';


# C routines
$C_PREFIX = '/home/labrie/prgc';

#%%%Begin KLimgutil%%%
$C_IMGUTIL = '/home/labrie/prgc/img/util';
#%%%End KLimgutil%%%
$getkeyval=$Iraf::getkeyval;
$findkey="$C_IMGUTIL/findkey";
$imarith = "$C_IMGUTIL/imarith";
$shimg = "$C_IMGUTIL/shimg";

#%%%Begin imfilter%%%
$C_IMFILTER = '/home/labrie/prgc/img/imfilter';
#%%%End imfilter%%%
$filter = "$C_IMFILTER/filter";

#%%%Begin Cccdred%%%
$C_CCDRED = '/home/labrie/prgc/img/ccdred';
#%%%End Cccdred%%%
$findbadpixR="$C_CCDRED/findbadpixR";
$fixbadpix="$C_CCDRED/fixbadpix";
$fringecor="$C_CCDRED/fringecor";
$dccor="$C_CCDRED/dccor";

#%%%Begin immatch%%%
$C_IMMATCH = '/home/labrie/prgc/img/immatch';
#%%%End immatch%%%
$easyreg = "$C_IMMATCH/easyreg";

#%%%Begin fit%%%
$C_FIT = '/home/labrie/prgc/fit';
#%%%End fit%%%
$fitgsurf = "$C_FIT/fitgsurf";

#-------------------------\
#        ccdhedit          \
#---------------------------\
sub ccdhedit {
  my ($allParamRef,@images) = @_;
  my $task='ccdhedit';
  my ($image);

  #### WARNING ####
  $"=',';
  #### WARNING ####

  foreach $image (@images) {
    open(TMP,"|$pkg") or die "Unable to pipe to $pkg.\n";
    print TMP "set imtype = \"$imtype\"\n";
    print TMP "$task\n";
    print TMP "$image\n$$allParamRef{'keyword'}\n";
    print TMP "$$allParamRef{'paramType'}\n$$allParamRef{'value'}\n";
    print TMP "$$allParamRef{'ccdred.instrumentB'}\n";
    close(TMP);
  }

  #### WARNING ####
  $"=' ';
  #### WARNING ####

  return();
}

#-------------------------\
#         ccdlist          \
#---------------------------\
sub ccdlist {
  my ($allParamRef,@images) = @_;
  my $task='ccdlist';

  #### WARNING ####
  $" = ',';
  #################

  $fhTMP = new FileHandle "|$pkg" or die "Cannot pipe to $pkg.\n";
  $fhTMP->print ("set imtype = \"$imtype\"\n");
  foreach $image (@images) {
    $fhTMP->print ("$task\n");
    $fhTMP->print ("$image\n$$allParamRef{'names'}\n$$allParamRef{'long'}\n");
    $fhTMP->print ("$$allParamRef{'ccdred.instrumentB'}\n");
    $fhTMP->print ("$$allParamRef{'ccdtype'}\n");
    $fhTMP->print ("$$allParamRef{'ccdred.ssfile'}\n");
  }
  $fhTMP->close();

  $"=' ';
  return();
}

#-------------------------\
#       darkcombine        \
#---------------------------\

sub darkcombine {
  my ($allParamRef,@images) = @_;
  my $task='combine';
  my $totalLength=0;
  my $USE_FILE = 0;

  foreach $_ (@images) {
    $totalLength += length ($_) + 1;
  }
  if ($totalLength > $Iraf::MAXLENGTH) {
     $USE_FILE = 1;
     warn "WARNING: Too many files for IRAF.  Sending list to file.\n";
     open(SCRATCH,">scratch") or die "Unable to create a scratch file.\n";
     foreach $_ (@images) { print SCRATCH "$_\n"; }
     close(SCRATCH);
  }

  #### WARNING ####
  $"=',';
  #### WARNING ####

  open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$$allParamRef{'ccdred.instrumentB'}\n";
  if ($USE_FILE) { print TMP "\@scratch\n"; }
  else           { print TMP "@images\n"; }
  print TMP "$$allParamRef{'subsets'}\n$$allParamRef{'ccdtype'}\n";
  print TMP "$$allParamRef{'output'}\n$$allParamRef{'plfile'}\n";
  print TMP "$$allParamRef{'sigma'}\n$$allParamRef{'ccdred.logfile'}\n";
  print TMP "$$allParamRef{'project'}\n$$allParamRef{'darkcombine.combine'}\n";
  print TMP "$$allParamRef{'darkcombine.reject'}\n$$allParamRef{'darkcombine.blank'}\n";
  print TMP "$$allParamRef{'darkcombine.gain'}\n$$allParamRef{'darkcombine.rdnoise'}\n";
  print TMP "$$allParamRef{'darkcombine.snoise'}\n$$allParamRef{'lthreshold'}\n";
  print TMP "$$allParamRef{'hthreshold'}\n$$allParamRef{'darkcombine.lsigma'}\n";
  print TMP "$$allParamRef{'darkcombine.hsigma'}\n$$allParamRef{'grow'}\n";
  print TMP "$$allParamRef{'darkcombine.mclip'}\n$$allParamRef{'sigscale'}\n";
  print TMP "$$allParamRef{'darkcombine.delete'}\n$$allParamRef{'darkcombine.clobber'}\n";
  print TMP "$$allParamRef{'darkcombine.nkeep'}\n$$allParamRef{'offsets'}\n";
  print TMP "$$allParamRef{'outtype'}\n$$allParamRef{'masktype'}\n";
  print TMP "$$allParamRef{'maskvalue'}\n$$allParamRef{'darkcombine.scale'}\n";
  print TMP "$$allParamRef{'zero'}\n$$allParamRef{'weight'}\n";
  print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'darkcombine.statsec'}\n";
  close(TMP);

  #### WARNING ####
  $"=' ';
  #### WARNING ####
  
  if ($USE_FILE) { 
  	unlink 'scratch' or  warn "Unable to delete 'scratch'\n";
  }

  return();
}

#-------------------------\
#       flatcombine        \
#---------------------------\

sub flatcombine {
  my ($allParamRef,$extraObstype,@images) = @_;
  my $task='combine';
  my ($i,$nImgOfCCDType,$nSubsets,$outputRoot);

  $outputRoot = $extraObstype.$$allParamRef{'flatcombine.output'};
  if ($$allParamRef{'flatcombine.subsets'} eq 'yes') {
    ($nImgOfCCDType,$nSubsets) = &getNbCCDType($$allParamRef{'ccdtype'},@images);
  }

  #### WARNING ####
  $" = ',';

  open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$$allParamRef{'ccdred.instrumentB'}\n";

  if (-e 'scratchList') { print TMP "\@scratchList\n"; }
  else { print TMP "@images\n"; }

  print TMP "$$allParamRef{'flatcombine.subsets'}\n$$allParamRef{'ccdtype'}\n";
  if ($$allParamRef{'flatcombine.subsets'} eq 'yes') {
    for ($i=0;$i<$nImgOfCCDType;$i++) {
      print TMP "$$allParamRef{'ccdred.ssfile'}\n";
    }
  }
  print TMP "$outputRoot\n$$allParamRef{'plfile'}\n";
  print TMP "$$allParamRef{'sigma'}\n$$allParamRef{'ccdred.logfile'}\n";
  print TMP "$$allParamRef{'project'}\n$$allParamRef{'flatcombine.combine'}\n";
  print TMP "$$allParamRef{'flatcombine.reject'}\n$$allParamRef{'flatcombine.blank'}\n";
  print TMP "$$allParamRef{'flatcombine.gain'}\n$$allParamRef{'flatcombine.rdnoise'}\n";
  print TMP "$$allParamRef{'flatcombine.snoise'}\n$$allParamRef{'lthreshold'}\n";
  print TMP "$$allParamRef{'hthreshold'}\n$$allParamRef{'flatcombine.lsigma'}\n";
  print TMP "$$allParamRef{'flatcombine.hsigma'}\n$$allParamRef{'grow'}\n";
  print TMP "$$allParamRef{'flatcombine.mclip'}\n$$allParamRef{'sigscale'}\n";
  print TMP "$$allParamRef{'flatcombine.delete'}\n$$allParamRef{'flatcombine.clobber'}\n";
  for ($i=0;$i<$nSubsets;$i++) {
    print TMP "$$allParamRef{'flatcombine.nkeep'}\n$$allParamRef{'offsets'}\n";
    print TMP "$$allParamRef{'outtype'}\n$$allParamRef{'masktype'}\n";
    print TMP "$$allParamRef{'maskvalue'}\n$$allParamRef{'flatcombine.scale'}\n";
    print TMP "$$allParamRef{'zero'}\n$$allParamRef{'weight'}\n";
    print TMP "$$allParamRef{'flatcombine.statsec'}\n$$allParamRef{'ccdred.verbose'}\n";
    print TMP "$$allParamRef{'flatcombine.statsec'}\n";
  }
  close(TMP);
  $" = ' ';

  return();
}

#-------------------------\
#       findBadPix         \
#---------------------------\
sub findBadPix {
 my ($paramRef,@images) = @_;
 my ($options,$crc,$image);

 $options = "-mbox $$paramRef{'medX'} $$paramRef{'medY'}";
 $options .= " --sbox='$$paramRef{'sbox'}'";
 $options .= " --lsigma='$$paramRef{'lsigma'}' --hsigma='$$paramRef{'hsigma'}'";
 $options .= " --tclip='$$paramRef{'tclip'}' -niter $$paramRef{'niter'}";
 if (defined $$paramRef{'log'}) { $options .= " --log=$$paramRef{'log'}"; }
 foreach $image (@images) {
   $crc = $image;
   $crc =~ s/\.$imtype$/.$suffix/;
   if ($CLOBBER) { unlink "$crc"; }
   #print "$findbadpix $image -o $outList $options\n";
   system ("$findbadpix $image -o $crc $options");
   unlink 'median.fits'
 }

 return;
}


#-------------------------\
#        fixBadPix         \
#---------------------------\
sub fixBadPix {
 my ($paramRef,@images) = @_;
 my ($options) = "";
 my ($editOptions) = "";
 my ($image,$crc,$newImage);
 my ($name,$path,$suf);
 my ($ccdhedit) = "$CCDred::ccdhedit";

 if (defined $$paramRef{'inst'}) {$editOptions .= " --inst=$$paramRef{'inst'}"; }

 if (defined $$paramRef{'log'}) { 
   $options .= " --log=$$paramRef{'log'}";
   $fhlog = new FileHandle ">> $$paramRef{'log'}" or
	   	die "ERROR: Unable to open $$paramRef{'log'} for writing.\n";
   print $fhlog "COSMIC RAY REMOVAL:\n";
   $fhlog->close;
 }
 foreach $image (@images) {
   $crc = $image;
   $crc =~ s/\.$imtype$/.$suffix/;
   if (defined $$paramRef{'output'}) {
      ($name,$path,$suf) = fileparse($image,$imtype);
      $newImage = $path.'/'.$$paramRef{'output'}.(($#images == 0) ? "" : "$name$suf");
      $newImage =~ tr/\///s;
   } else {
      $newImage = "$image";
   }
   if ($CLOBBER) { 
     @goners = ('mask.fits');
     if ($newImage ne $image) {
       push @goners, $newImage;
     }
     unlink @goners; 
   }

   if (defined $$paramRef{'log'}) {
     $fhlog = new FileHandle ">> $$paramRef{'log'}" or
	   	  die "ERROR: Unable to open $$paramRef{'log'} for writing.\n";
     print $fhlog "$newImage: ";
     $fhlog->close;
   }

   $status = system ("$fixbadpix $image -o $newImage -bad $crc $options");
   $status >>= 8;
   ($date,$time) = Util::DatenTime(time);
   ($name,$path,$suf) = fileparse($crc,$suffix);
   $comment = "$date $time With $name$suffix";

   #Edit header of new image
   if ($status == 0) {
     system ("$ccdhedit $newImage 'CRFIX' '$comment' 'string' $editOptions");
   }

   #Write to logfile
   if (defined $$paramRef{'log'}) {
     $fhlog = new FileHandle ">> $$paramRef{'log'}" or
	   	  die "ERROR: Unable to open $$paramRef{'log'} for writing.\n";
     if ($status == 0) {print $fhlog "$comment\n";}
     else              {print $fhlog "ERROR: Error while removing CRs.\n";}
     $fhlog->close;
   }
  
   unlink 'mask.fits';
 } 

 return;
}


#-------------------------\
#      getNbCCDType        \
#---------------------------\

sub getNbCCDType {
  my ($ccdtype,@img) = @_;
  my ($nbImg) = 0;
  my ($substr,$scratch);
  my (@subsets);
  $" = ' ';

#  $substr = $Util::substr;
  $scratch = 'scratch';
  @subsets = ();

  if (defined $allParam{'inst'}) {
    system ("$ccdlist @img --quiet --inst=$$allParamRef{'inst'} > $scratch");
  } else {
    system ("$ccdlist @img --quiet > $scratch");
  }
#  system ("$substr $scratch '> \n' ''");
  open (SCRATCH,"<$scratch");
  while (<SCRATCH>) {
    next if ( /> \n/ );
    if (/\[$ccdtype\]/) {
      s/\n//;
      $nbImg++;
      /\[(\w+)\]\[\w+\]:.*?$/;
      next if (grep /^$1$/, @subsets);
      push @subsets, $1;
    }
  }
  close(SCRATCH);
  system ("rm $scratch");

  $" = ',';
  return($nbImg,$#subsets + 1);
}

#-------------------------\
#     getNumberOfCalib     \
#---------------------------\

sub getNumberOfCalib {
  my ($files2Find) = @_;
  my (@allFileNames,$nCalib);

  @allFileNames = glob("$files2Find");
  
  $nCalib=$#allFileNames + 1;

  return($nCalib);
}

#-------------------------\
#       zerocombine        \
#---------------------------\

sub zerocombine {
  my ($allParamRef,@images) = @_;
  my $task='combine';

  open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$$allParamRef{'ccdred.instrumentB'}\n@images\n";
  print TMP "$$allParamRef{'subsets'}\n$$allParamRef{'ccdtype'}\n";
  print TMP "$$allParamRef{'zerocombine.output'}\n$$allParamRef{'plfile'}\n";
  print TMP "$$allParamRef{'sigma'}\n$$allParamRef{'ccdred.logfile'}\n";
  print TMP "$$allParamRef{'project'}\n$$allParamRef{'zerocombine.combine'}\n";
  print TMP "$$allParamRef{'zerocombine.reject'}\n";
  print TMP "$$allParamRef{'zerocombine.blank'}\n";
  print TMP "$$allParamRef{'zerocombine.gain'}\n";
  print TMP "$$allParamRef{'zerocombine.rdnoise'}\n";
  print TMP "$$allParamRef{'zerocombine.snoise'}\n$$allParamRef{'lthreshold'}\n";
  print TMP "$$allParamRef{'hthreshold'}\n$$allParamRef{'zerocombine.lsigma'}\n";
  print TMP "$$allParamRef{'zerocombine.hsigma'}\n$$allParamRef{'grow'}\n";
  print TMP "$$allParamRef{'zerocombine.mclip'}\n$$allParamRef{'sigscale'}\n";
  print TMP "$$allParamRef{'zerocombine.delete'}\n";
  print TMP "$$allParamRef{'zerocombine.clobber'}\n";
  print TMP "$$allParamRef{'zerocombine.nkeep'}\n$$allParamRef{'offsets'}\n";
  print TMP "$$allParamRef{'outtype'}\n$$allParamRef{'masktype'}\n";
  print TMP "$$allParamRef{'maskvalue'}\n$$allParamRef{'zerocombine.scale'}\n";
  print TMP "$$allParamRef{'zero'}\n$$allParamRef{'weight'}\n";
  print TMP "$$allParamRef{'ccdred.verbose'}\n";
  print TMP "$$allParamRef{'zerocombine.statsec'}\n";
  close(TMP);

  return();
}

########### Routines called by ccdproc ##################

#-------------------------\
#      ccdOverscan         \
#---------------------------\

sub ccdOverscan {
  my ($allParamRef,@images) = @_;
  my (@statsBefore,@statsAfter);
  my ($image);
  my $task='ccdproc';

  $|=1;		#AUTOFLUSH ON
  $$allParamRef{'ccdproc.overscan'}='yes';

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;	# if set, problems below.
    }
    print "\nOverscan on $image, output is $$allParamRef{'ccdproc.output'}\n";
    open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
    print TMP "set imtype = \"$imtype\"\n";
    print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
    print TMP "$$allParamRef{'ccdred.instrumentA'}\n$$allParamRef{'ccdproc.interactive'}\n";
    print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
    print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
    print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
    print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
    print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
    print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
    print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
    print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
    print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.noproc'}\n";
    print TMP "$$allParamRef{'ccdproc.function'}\n$$allParamRef{'ccdproc.function'}\n";
    print TMP "$$allParamRef{'ccdproc.order'}\n$$allParamRef{'ccdproc.sample'}\n";
    print TMP "$$allParamRef{'ccdproc.naverage'}\n$$allParamRef{'ccdproc.niterate'}\n";
    print TMP "$$allParamRef{'ccdproc.low_reject'}\n$$allParamRef{'ccdproc.high_reject'}\n";
    print TMP "$$allParamRef{'ccdproc.grow'}\n$$allParamRef{'ccdred.plotfile'}\n";
    print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
    print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
    print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.illumcor'}\n";
    print TMP "$$allParamRef{'ccdproc.fringecor'}\n$$allParamRef{'ccdred.backup'}\n";
    close(TMP);

    @statsAfter=();
    @statsAfter = stat $image;
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      if (-e 'no') {unlink 'no';}
      print "\nFirst try failed.  Trying a second method.\n";
      open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
      print TMP "set imtype = \"$imtype\"\n";
      print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
      print TMP "$$allParamRef{'ccdred.instrumentA'}\n$$allParamRef{'ccdproc.interactive'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
      print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
      print TMP "$$allParamRef{'ccdred.ssfile'}\n";
      #$origCcdtype=$$allParamRef{'ccdtype'};
      #$$allParamRef{'ccdtype'}='flat';
      print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
      print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
      print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
      print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
      print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
      print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdproc.function'}\n$$allParamRef{'ccdproc.function'}\n";
      print TMP "$$allParamRef{'ccdproc.order'}\n$$allParamRef{'ccdproc.sample'}\n";
      print TMP "$$allParamRef{'ccdproc.naverage'}\n$$allParamRef{'ccdproc.niterate'}\n";
      print TMP "$$allParamRef{'ccdproc.low_reject'}\n$$allParamRef{'ccdproc.high_reject'}\n";
      print TMP "$$allParamRef{'ccdproc.grow'}\n$$allParamRef{'ccdred.plotfile'}\n";
      print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
      print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
      print TMP "$$allParamRef{'ccdred.backup'}\n";
      close(TMP);
      #$$allParamRef{'ccdtype'}=$origCcdtype;
    }
    @statsAfter=();
    @statsAfter = stat $image;
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      die "Error in overscan.\n";
    }
  }
  
  $$allParamRef{'ccdproc.overscan'}='no';
  if (@tmpfiles = glob ("tmp*")) {unlink @tmpfiles;}
  $|=0;		#AUTOFLUSH OFF

  return();
}

#-------------------------\
#        ccdTrim           \
#---------------------------\

sub ccdTrim {
  my ($allParamRef,@images) = @_;
  my (@statsBefore,@statsAfter);
  my ($image);
  my $task='ccdproc';

  $|=1;		#AUTOFLUSH ON
  $$allParamRef{'ccdproc.trim'}='yes';

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;		# if set, problems below.
    }
    print "\nTrimming $image\n";
    open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
    print TMP "set imtype = \"$imtype\"\n";
    print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
    print TMP "$$allParamRef{'ccdred.instrumentA'}\n$$allParamRef{'ccdproc.interactive'}\n";
    print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
    print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
    print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
    print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
    print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
    print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
    print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
    print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.noproc'}\n";
    print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
    print TMP "$$allParamRef{'ccdproc.fixpix'}\n$$allParamRef{'ccdproc.overscan'}\n";
    print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
    print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.illumcor'}\n";
    print TMP "$$allParamRef{'ccdproc.fringecor'}\n$$allParamRef{'ccdred.backup'}\n";
    close(TMP);

    @statsAfter=();
    @statsAfter = stat $image;
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      if (-e 'no') {unlink 'no';}
      print "\nFirst try failed.  Trying a second method.\n";
      open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
      print TMP "set imtype = \"$imtype\"\n";
      print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
      print TMP "$$allParamRef{'ccdred.instrumentA'}\n$$allParamRef{'ccdproc.interactive'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
      print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
      print TMP "$$allParamRef{'ccdred.ssfile'}\n";
      #$origCcdtype=$$allParamRef{'ccdtype'};
      #$$allParamRef{'ccdtype'}='flat';
      print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
      print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
      print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
      print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
      print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
      print TMP "$$allParamRef{'ccdproc.fixpix'}\n$$allParamRef{'ccdproc.overscan'}\n";
      print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
      print TMP "$$allParamRef{'ccdred.backup'}\n";
      close(TMP);
      #$$allParamRef{'ccdtype'}=$origCcdtype;
    }
    @statsAfter=();
    @statsAfter = stat $image;
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      die "Error in trim.\n";
    }
  }

  $$allParamRef{'ccdproc.trim'}='no';
  if (@tmpfiles = glob ("tmp*")) {unlink @tmpfiles;}
  $|=0;		#AUTOFLUSH OFF

  return();
}

#-------------------------\
#        ccdZero           \
#---------------------------\

sub ccdZero {
  my ($allParamRef,@images) = @_;
  my ($nZero, $image);
  my (@statsBefore,@statsAfter);
  my $task='ccdproc';

  $|=1;		#AUTOFLUSH ON
  $$allParamRef{'ccdproc.zerocor'} = 'yes';

  $nZero = &getNumberOfCalib($$allParamRef{'ccdproc.zero'});

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;		# if set, problems below.
    }
    print "\nZero correction on $image\n";
    open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
    print TMP "set imtype = \"$imtype\"\n";
    print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
    print TMP "$$allParamRef{'ccdred.instrumentB'}\n$$allParamRef{'ccdproc.interactive'}\n";
    print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
    print TMP "$$allParamRef{'ccdproc.zero'}\n";
    for ($i=0;$i<$nZero;$i++) {
      print TMP "$$allParamRef{'ccdred.ssfile'}\n";
    }
    print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
    print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
    print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
    print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
    print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
    print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
    print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
    print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.zerocor'}\n";
    print TMP "$$allParamRef{'ccdproc.scancor'}\n$$allParamRef{'ccdproc.noproc'}\n";
    print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
    print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.readcor'}\n";
    print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
    print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
    print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
    print TMP "$$allParamRef{'ccdred.backup'}\n";
    close(TMP);
    @statsAfter=();
    @statsAfter = stat $image;
    unless ($statsAfter[9] - $statsBefore[9]) {
      die "Error in bias correction\n";
    }
  }

  $$allParamRef{'ccdproc.zerocor'} = 'no';
  if (@tmpfiles = glob ("tmp*")) {unlink @tmpfiles;}
  $|=0;		#AUTOFLUSH OFF

  return();
}

#-------------------------\
#         ccdDark          \
#---------------------------\

sub ccdDark {
  my ($allParamRef,@images) = @_;
  my ($nDark, $image);
  my $task='ccdproc';

  $|=1;		#AUTOFLUSH ON
  $$allParamRef{'ccdproc.darkcor'} = 'yes';

  $nDark = &getNumberOfCalib($$allParamRef{'ccdproc.dark'});

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;    
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;		# if set, problems below.
    }
    $TRY=1;
    while ($TRY <= 2) {
      if ($TRY == 1) {print "\nDark correction on $image\n";}
      else { if (-e 'no') {unlink 'no';}
             print "Failed.  Trying another input sequence.\n";
	    }
      open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
      print TMP "set imtype = \"$imtype\"\n";
      print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
      print TMP "$$allParamRef{'ccdred.instrumentB'}\n$$allParamRef{'ccdproc.interactive'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.dark'}\n";
      for ($i=0;$i<$nDark;$i++) {
	 print TMP "$$allParamRef{'ccdred.ssfile'}\n";
      }
      print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.illumcor'}\n";
      print TMP "$$allParamRef{'ccdproc.fringecor'}\n";

      if ($TRY == 2) {
  #    for ($i=0;$i<$nDark;$i++) {
	 print TMP "$$allParamRef{'ccdred.ssfile'}\n";
  #    }
      }

      print TMP "$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdred.pixeltype'}\n";
      print TMP "$$allParamRef{'ccdproc.readaxis'}\n$$allParamRef{'ccdproc.minreplace'}\n";
      print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.trimsec'}\n";
      print TMP "$$allParamRef{'ccdproc.biassec'}\n$$allParamRef{'ccdproc.trim'}\n";
      print TMP "$$allParamRef{'ccdproc.fixpix'}\n$$allParamRef{'ccdproc.overscan'}\n";
      print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
      print TMP "$$allParamRef{'ccdproc.scancor'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
      print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
      if ($TRY == 1) {
        print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.illumcor'}\n";
        print TMP "$$allParamRef{'ccdproc.fringecor'}\n";
      }
      if ($$allParamRef{'ccdproc.output'} eq '') {
	 print TMP "$$allParamRef{'ccdred.backup'}\n";
      }    
      close(TMP);
      @statsAfter=();
      @statsAfter = stat $image;
      if (not ($statsAfter[9] - $statsBefore[9] > 0)) { $TRY++; }
      else { last; }
    }
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
	 die "Error in dark correction\n";
    }
  }

  $$allParamRef{'ccdproc.darkcor'} = 'no';
  if (@tmpfiles = glob ("tmp*")) {unlink @tmpfiles;}
  $|=0;		#AUTOFLUSH OFF

  return();
}

#-------------------------\
#         ccdFlat          \
#---------------------------\

sub ccdFlat {
  my ($allParamRef,@images) = @_;
  my ($nFlat, $image);
  my (@statsBefore,@statsAfter);
  my $task='ccdproc';

  $|=1;		#AUTOFLUSH ON
  $$allParamRef{'ccdproc.flatcor'} = 'yes';

  $nFlat =
    &getNumberOfCalib("$$allParamRef{'extraObstype'}$$allParamRef{'ccdproc.flat'}");

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;		# if set, problems below.
    }
    $TRY=1;
    while ($TRY <= 2) {
      if ($TRY == 1) {print "Flat correction on $image\n";}
      else { if (-e 'no') {unlink 'no';}
             print "Failed.  Trying another method.\n";
	    }
      open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
      print TMP "set imtype = \"$imtype\"\n";
      print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
      print TMP "$$allParamRef{'ccdred.instrumentB'}\n$$allParamRef{'ccdproc.interactive'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
      print TMP "$$allParamRef{'extraObstype'}$$allParamRef{'ccdproc.flat'}\n";
      for ($i=0;$i<$nFlat;$i++) {
	 print TMP "$$allParamRef{'ccdred.ssfile'}\n";
      }
      print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
      print TMP "$$allParamRef{'ccdproc.noproc'}\n$$allParamRef{'ccdtype'}\n";
      print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
      print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
      print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
      print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
      print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n";
      print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.scancor'}\n";
      print TMP "$$allParamRef{'ccdred.ssfile'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
      print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.scancor'}\n";

      if ($TRY == 2) {
	print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.readaxis'}\n";
	print TMP "$$allParamRef{'ccdproc.minreplace'}\n$$allParamRef{'ccdred.pixeltype'}\n";
	print TMP "$$allParamRef{'ccdproc.trimsec'}\n$$allParamRef{'ccdproc.biassec'}\n";
	print TMP "$$allParamRef{'ccdproc.trim'}\n$$allParamRef{'ccdproc.fixpix'}\n";
	print TMP "$$allParamRef{'ccdproc.overscan'}\n$$allParamRef{'ccdproc.zerocor'}\n";
	print TMP "$$allParamRef{'ccdproc.darkcor'}\n";
	print TMP "$$allParamRef{'ccdproc.noproc'}\n";
      }

      print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
      print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.fringecor'}\n";
      print TMP "$$allParamRef{'ccdred.backup'}\n";
      close(TMP);
      @statsAfter=();
      @statsAfter = stat $image;
      if (not ($statsAfter[9] - $statsBefore[9] > 0)) { $TRY++; }
      else { last;}
    }
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      die "Error in flat field correction\n";
    }
  }

  $$allParamRef{'ccdproc.flatcor'} = 'no';
  if (@tmpfiles = glob ("tmp*")) {unlink @tmpfiles;}
  $|=0;		#AUTOFLUSH OFF
  return();
}

#-------------------------\
#       ccdIllum           \
#---------------------------\
sub ccdIllum {
  my ($allParamRef,@images) = @_;
  my ($nIllum, $image);
  my (@statsBefore, @statsAfter);
  my $task='ccdproc';

  $|=1;		#OUTPUT_AUTOFLUSH ON
  $$allParamRef{'ccdproc.illumcor'} = 'yes';

  $nIllum = &getNumberOfCalib($$allParamRef{'ccdproc.illum'});

  foreach $image (@images) {
    @statsBefore=();
    @statsBefore = stat $image;
    unless ($$allParamRef{'ccdproc.output'} eq '') {
      $$allParamRef{'ccdproc.output'} .= $image;		#if set, problems below.
    }
    $TRY=1;
    while ($TRY <= 1) {
      if ($TRY == 1) {print "Illumination correction on $image\n";}
      else { if (-e 'no') {unlink 'no';}
      		print "Failed. Trying another sequence of inputs.\n";
	    }
      open(TMP, "|$pkg") or die "Unable to pipe to $pkg.\n";
      print TMP "set imtype = \"$imtype\"\n";
      print TMP "$task\n$image\n$$allParamRef{'ccdproc.output'}\n";
      print TMP "$$allParamRef{'ccdred.instrumentB'}\n$$allParamRef{'ccdproc.interactive'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdproc.zerocor'}\n";
      print TMP "$$allParamRef{'ccdproc.darkcor'}\n$$allParamRef{'ccdproc.flatcor'}\n";
      print TMP "$$allParamRef{'ccdproc.illumcor'}\n$$allParamRef{'ccdproc.illum'}\n";
      for ($i=0;$i<$nIllum;$i++) {
        print TMP "$$allParamRef{'ccdred.ssfile'}\n";
      }
      print TMP "$$allParamRef{'ccdproc.fringecor'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdtype'}\n$$allParamRef{'ccdred.pixeltype'}\n";
      print TMP "$$allParamRef{'ccdproc.readaxis'}\n$$allParamRef{'ccdproc.minreplace'}\n";
      print TMP "$$allParamRef{'ccdred.pixeltype'}\n$$allParamRef{'ccdproc.trimsec'}\n";
      print TMP "$$allParamRef{'ccdproc.biassec'}\n$$allParamRef{'ccdproc.trim'}\n";
      print TMP "$$allParamRef{'ccdproc.fixpix'}\n$$allParamRef{'ccdproc.overscan'}\n";
      print TMP "$$allParamRef{'ccdproc.zerocor'}\n$$allParamRef{'ccdproc.darkcor'}\n";
      print TMP "$$allParamRef{'ccdproc.flatcor'}\n$$allParamRef{'ccdproc.illumcor'}\n";
      print TMP "$$allParamRef{'ccdred.ssfile'}\n$$allParamRef{'ccdproc.noproc'}\n";
      print TMP "$$allParamRef{'ccdred.verbose'}\n$$allParamRef{'ccdred.logfile'}\n";
      print TMP "$$allParamRef{'ccdproc.fringecor'}\n$$allParamRef{'ccdred.backup'}\n";
      close(TMP);
      @statsAfter=();
      @statsAfter = stat $image;
      if (not ($statsAfter[9] - $statsBefore[9] > 0)) { $TRY++; }
      else { last; }
    }
    unless ($statsAfter[9] - $statsBefore[9] > 0) {
      die "ERROR:  Error in illumination correction\n";
    }
  }

  $$allParamRef{'ccdproc.illumcor'} = 'no';
  if (@tmpfiles = glob ("tmp*")) { unlink @tmpfiles; }
  $|=0;		#OUTPUT_AUTOFLUSH OFF

  return();
}

#-------------------------\
#       ccdFringe          \
#---------------------------\
sub ccdFringe {
  my ($allParamRef,@images) = @_;
  my ($image);
  my $task='ccdproc';

  # divide images into subsets  (ccdlist.pl)
  #	hash of arrays (%img, keys=subset, values=list of images)
  %img=();
  $command = "$ccdlist @images --ccdtype=$$allParamRef{'ccdtype'} --quiet";
  if (defined $$allParamRef{'inst'}) {
    $command .= " --inst=$$allParamRef{'inst'}";
  }
  $fhpipe = new FileHandle "$command|" or die "Unable to pipe from $ccdlist.\n";
  while (<$fhpipe>) {
    /^(.*?)\[.*?\[(\w+)\]\[\w+\]\:.*?$/;
    $imname=$1;
    $subset=$2;
    push @{ $img{"$subset"} }, $imname;
  }
  $fhpipe->close;

  # Get fringe images
  @fringes = glob ("$$allParamRef{'ccdproc.fringe'}");
  $command = "$ccdlist @fringes --ccdtype=$$allParamRef{'ccdtype'} --quiet";
  if (defined $$allParamRef{'inst'}) {
    $command .= " --inst=$$allParamRef{'inst'}";
  }
  $fhpipe = new FileHandle "$command|" or die "Unable to pipe from $ccdlist.\n";
  while (<$fhpipe>) {
    /^(.*?)\[.*?\[(\w+)\]\[\w+\]\:.*?$/;
    $imname=$1;
    $subset=$2;
    $frng{"$subset"} = $imname;
  }
  $fhpipe->close;

  # Get lower and upper limits on statistics from inst.param
  $newParamFile=$$allParamRef{'paramFile'};
  $newParamFile =~ s/\.cl$/\.param/;
  %newParam = Iraf::getParam("$newParamFile",'=');
  if (grep /mkfringe.statlower/, keys %newParam) {
    $lower=$newParam{'mkfringe.statlower'};
  }
  if (grep /mkfringe.statupper/, keys %newParam) {
    $upper=$newParam{'mkfringe.statupper'};
  }
  undef %newParam;

  # Apply fringe correction
  foreach $subset (keys %img) {
    $command = "$fringecor @{ $img{$subset} } --fringe=$frng{$subset}";
    if (defined $lower) {
      $command .= " --lower=$lower";
    }
    if (defined $upper) {
      $command .= " --upper=$upper";
    }
    system("$command --log=$$allParamRef{'ccdred.logfile'}");
  }

  return;
}

#-------------------------\
#         ccdDC            \
#---------------------------\
sub ccdDC {
  my ($allParamRef,@images) = @_;
  my ($command,$image,$newParamFile,$skydb,%list);
  my ($options) = "";
  my $task='ccdproc';

  $newParamFile = $$allParamRef{'paramFile'};
  $newParamFile =~ s/\.cl$/\.param/;
  %newParam = Iraf::getParam("$newParamFile",'=');
  if (defined $newParam{'dccor.output'}) {
    $options .= " -o $newParam{'dccor.output'}";
  }
  $options .= " --$newParam{'dccor.stats'} --log=$$allParamRef{'ccdred.logfile'}";
  if (defined $newParam{'dccor.mask'}) {
    $options .= " --mask=$newParam{'dccor.mask'}";
  }
  if ((defined $newParam{'dccor.nsig'}) && ($newParam{'dccor.nsig'} > 0)) {
    $options .= " --nsig=$newParam{'dccor.nsig'}";
    if (defined $newParam{'dccor.lsigma'}) {
      $options .= " --lsigma=$newParam{'dccor.lsigma'}";
    }
    if (defined $newParam{'dccor.hsigma'}) {
      $options .= " --hsigma=$newParam{'dccor.hsigma'}";
    }
    if (defined $newParam{'dccor.sbox'}) {
      $options .= " --sbox=$newParam{'dccor.sbox'}";
    }
  }
  if (defined $$allParamRef{'inst'}) {
    $options .= " --inst=$$allParamRef{'inst'}";
  }
  $skydb = $newParam{'dccor.skydb'};
  undef %newParam;
  
  %list = Iraf::getParam("$skydb",'::');

  foreach $image (@images) {
    $command = "$dccor $image -s $list{$image} $options";
    system($command);
  }

  return;
}


########## Routines called by 'reduc' ###########

#-------------------------\
#        CleanDir          \
#---------------------------\
sub cleanDir {
  my ($isDef,$logfile,$calibType,$calibDir,@epochs) = @_;
  my ($file,$suffix,$junk,$goner,@goners,$fhlog,$epochOnly,$cnt,$i);
  my ($FALSE) = 0;
  my ($TRUE) = 1;
  my ($DELETENOW) = $TRUE;

  if (lc($calibType) eq 'sky') {
    @goners = glob("${calibType}*.fits");
    $DELETENOW = $FALSE;
  }
  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    Iraf::printlog($logfile,
              "\nCopy new '${calibType}' images to calibration directory:\n");
  }
  
  for ($i=0; $i<=$#epochs; $i++) {
    $epoch = $epochs[$i];
    
    if ($i == $#epochs) {	# last time around, copy one last time and delete.
      $DELETENOW = $TRUE;
    }
    unless (lc($calibType) eq 'sky') {
      @goners = glob ("${epoch}${calibType}*");
    }

    #Check if the goners exits in the calibration directory.
    #If not, then they were just created.  Copy them in the appropriate
    #calibration directory.  Create the directory if necessary.
    if ((lc($calibType) eq 'zero') || (lc($calibType) eq 'dark') || 
      				      (lc($calibType) eq 'flat') ||
				      (lc($calibType) eq 'skyflat') ||
				      (lc($calibType) eq 'domeflat') ||
				      (lc($calibType) eq 'sky')  ||
				      (lc($calibType) eq 'illum')||
				      (lc($calibType) eq 'fringe')) {
      $epoch =~ /(e\d+)\/$/;
      $epochOnly = $1;
      # if working in calibDir don't delete anything
      next if ($epoch eq "${calibDir}$epochOnly/");
      
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
	 $fhlog = new FileHandle ">>$logfile";
      }
      foreach $goner (@goners) {
	 ($file, $junk, $suffix) = fileparse("$goner",'\.fits');
	 $file .= $suffix;
	 unless (-e "${calibDir}$epochOnly/$file") {	#Do nothing if file exist
	   unless (-e "${calibDir}$epochOnly") {	#If the dir doesn't exist, create it
	     print ("Creating ${calibDir}$epochOnly ... ");
	     if (mkdir ("${calibDir}$epochOnly", 0755) == 0) {
		if (defined $fhlog) { close($fhlog); }
		die "$!: Unable to create ${calibDir}$epochOnly\n";
	     }
	     print "done\n";
	     if (defined $fhlog) {
		print $fhlog "Create new calibration directory : ${calibDir}$epochOnly/\n";
	     }
	   }
	   print ("$goner -> ${calibDir}$epochOnly/$file ... ");
	   if (copy("$goner","${calibDir}$epochOnly/$file") == 0) {
	      if (defined $fhlog) { close($fhlog); }
	      die "$!: Unable to copy $goner to ${calibDir}$epochOnly/";
	   }
	   print ("done\n");
	   if (defined $fhlog) {
	     print $fhlog "\t$goner -> ${calibDir}$epochOnly\n";
	   }
	 }
      }
      if (defined $fhlog) {
	 close($fhlog);
      }
    }

    if ($DELETENOW) {
      print "Deleting\n";
      foreach $goner (@goners) { print "\t$goner\n";}
      print "\tdone\n";
      $cnt = unlink @goners;
      if ($cnt != $#goners + 1) {
	 warn "Unable to delete all the $calibType files in $epoch.\n";
	 if ($isDef & 1 << $LOGFILE) {		#if defined logfile
	   Iraf::printlog($logfile,
	          "Unable to delete all the $calibType files in $epoch.\n");
	 }
      }
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
         $message = "Deleted:\n";
	 foreach $goner (@goners) { $message .= "\t$goner\n"; }
	 $message .= "\n";
	 Iraf::printlog($logfile,$message);
      }
    }
  }
  return;
}

#-------------------------\
#       CombCalib          \
#---------------------------\
sub combCalib {
  my ($isDef,$logfile,$instRef,$calibType,$imgList,$rec,$epochRef) = @_;
  my ($fhPipeOut, $pipe);
  my ($pattern,$combine,$toEval);
  my (@recImages,@tmpImages,@images,@calibInfo);
  my (@calibs) = ();
  my ($imName,$img,$epoch);
 #Definitions
  my ($zerocombine) = $CCDred::zerocombine;
  my ($darkcombine) = $CCDred::darkcombine;
  my ($flatcombine) = $CCDred::flatcombine;
  my ($skycombine) = $CCDred::skycombine;
  my ($ccdlist) = $CCDred::ccdlist;
  my ($extraObstype) = "";

  if ((lc($calibType) eq 'skyflat') or (lc($calibType) eq 'domeflat')) {
    $calibType =~ s/(\w*)[F|f]lat/Flat/;
    $extraObstype = $1;
  }

 #With 'ccdlist' find calibration images and check if they have been 
 # pre-processed
 #Pre-processing required :
 #	For "zero" : (fixpix,) overscan, trimming
 #	For "dark" : (fixpix,) overscan, trimming, zero correction
 #	For "flat" : (fixpix,) overscan, trimming, zero correction (, dark corr)
 #Eg. of ccdlist output :
 #   fspix.005.fits[784,785][real][zero][][BOT]:zero
 #   fspix.005.fits[784,785][real][zero][][OT]:zero
 #   fspix.005.fits[784,785][real][dark][][OTZ]:dark
 #   fspix.005.fits[784,785][real][flat][][OTZ]:flat
 #  (fspix.005.fits[784,785][real][flat][][OTZD]:flat)
  SWITCH: {
    if (lc($calibType) eq 'zero') {
      #$pattern = '\[B?OT\]:(\w|\s)+$';
      $combine = "$zerocombine";		#default ccdtype is 'zero'
      if ($isDef & 1 << $INSTRUMENT) { $combine .= " --inst=$$instRef{'instrument'}"; }
      $toEval = 'if (($rec->{$imName} & (1 << 0)) and
      				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some biases have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some biases have not been trimmed.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(B|Z|D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some biases have been wrongfully processed.\n";
		   }';
      last SWITCH;
    }
    if (lc($calibType) eq 'dark') {
      #$pattern = '\[B?OTZ?\]:(\w|\s)+$';
      $combine = "$darkcombine";		#default ccdtype is 'dark'
      if ($isDef & 1 << $INSTRUMENT) { $combine .= " --inst=$$instRef{'instrument'}"; }
      $toEval = 'my (@files);
                 if (($rec->{$imName} & (1 << 0)) and
				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some darks have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some darks have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some darks have not been bias corrected.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some darks have been wrongfully processed.\n";
		   }';
      last SWITCH;
    }
    if (lc($calibType) eq 'flat') {
      #$pattern = '\[B?OTZ?D?\]:(\w|\s)+$';
      $combine = "$flatcombine";                #default ccdtype is 'flat'
      if ($isDef & 1 << $INSTRUMENT) { $combine .= " --inst=$$instRef{'instrument'}"; }
      $toEval = 'my (@files);
                 if (($rec->{$imName} & (1 << 0)) and
				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some flats have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some flats have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some flats have not been bias corrected.\n";
		   }
		   @files = ();
		   (@files) = <Dark*.fits>;
		   if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some flats have not been dark corrected.\n";
		   }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some flats have not been corrected for bad pixels.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(F|I|Q)\w*?\]:.*?$/) {
		   	die "Some flats have been wrongfully processed.\n";
		   }';
      last SWITCH;
    }
    if (lc($calibType) eq 'sky') {
      #$pattern = '\[B?O?T?Z?D?\]:(\w|\s)+$';
      $combine="$skycombine";		#default ccdtype is 'other'
      if ($isDef & 1 << $INSTRUMENT) { $combine .= " --inst=$$instRef{'instrument'}"; }
      $truecalibType = $calibType;
      $calibType = 'other';
      $toEval = 'my (@files);
      		 if (($rec->{$imName} & (1 << 0)) and
		 		!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some sky images have not been corrected for overscan.\n";
		 }
		 if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some sky images have not been trimmed.\n";
		 }
		 @files = ();
		 (@files) = <Zero*.fits>;
		 if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some sky images have not been bias corrected.\n";
		 }
		 @files = ();
		 (@files) = <Dark*.fits>;
		 if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some sky images have not been dark corrected.\n";
		 }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some sky images have not been corrected for bad pixels.\n";
		 }
		 @files = ();
		 (@files) = <Flat*.fits>;
		 if (($rec->{$imName} & (1 << 4)) and ($#files >= 0) and
		 		!($_ =~ /(\[.+?\]){4}\[\w*?F\w*?\]:.*?$/)) {
			die "Some sky images have not been flat fielded.\n";
		 }
		 if ($_ =~ /(\[.+?\]){4}\[\w*?(I|Q)\w*?\]:.*?$/) {
		   	die "Some sky images have been wrongfully processed.\n";
		 }';
      last SWITCH;
    }
    die "No valid calibration type provided.\n";
  }

 #get the image list
  @recImages = keys % { $rec };
  @images = ();
  if ($imgList ne "") {
     if (lc($calibType) eq 'sky') {
        foreach $epoch (@{ $epochRef }) {
	  @tmpImages = ();
	  @tmpImages = Util::getListOf('-f','-l',$imgList,$epoch);
	  foreach $img (@tmpImages) {
	    die "ERROR: '$epoch$img' has not been verified.\n" if (not grep /^$img$/, @recImages);
	  }
	  push @images, @tmpImages;
	}
     } else {
        @images = Util::getListOf('-f','-l',$imgList,$$epochRef);
	foreach $img (@images) {
	  die "ERROR: '$$epochRef$img' has not been verified.\n" if (not grep /^$img$/, @recImages);
	}
     }
  } else {
     @images = @recImages
  }


  if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
    $pipe = "$ccdlist @images --ccdtype=".lc($calibType)." --quiet --inst=$$instRef{'instrument'}";
  } else {
    $pipe = "$ccdlist @images --ccdtype=".lc($calibType)." --quiet";
  }
  $fhPipeOut = new FileHandle "$pipe |";
  @calibInfo = <$fhPipeOut>;
  $fhPipeOut->close();
  @images = ();

  @tmpcalibs = ();
  foreach $_ (@calibInfo) {
      /^((\w|\.|-|\/)+)\[/;
      $imName=$1;
      if (!defined (eval "$toEval")) {
        die "$@";
      }
      
      push @tmpcalibs,$imName;
  }
  if ($extraObstype ne "") {
    $i=0;
    $pipeCommand = "$getkeyval @tmpcalibs -k OBSTYPE -d string |";
    $fhPipeOut = new FileHandle "$pipeCommand";
    while (<$fhPipeOut>) {
      chop $_;
      if (lc($_) eq lc("${extraObstype}${calibType}")) {
      		push @calibs, $tmpcalibs[$i];
      }
      $i++;
    }
    $fhPipeOut->close();
  }
  else { push @calibs, @tmpcalibs; }

 #Combine
  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $fhlog = new FileHandle ">>$logfile";
    if (defined $truecalibType) { $calibType = $truecalibType; }
    if (lc($calibType) eq 'sky') {
      print $fhlog "Combine ".lc($calibType)." images found in:\n";
      foreach $_ (@{ $epochRef }) { print $fhlog "\t$_\n"; }
    }
    else {
      print $fhlog "$$epochRef: Combine \L${extraObstype}$calibType\E calibration images.\n";
    }
    $fhlog->close;
  }
  system "$combine @calibs --oprefix=$extraObstype";

  return();
}

#-------------------------\
#        CopyOver          \
#---------------------------\
sub copyOver {
  my ($isDef,$logfile,$file,$newRoot,@images) = @_;
  my ($imType) = $CCDred::imtype;
  #### WARNING ####
  $" = " \t";
  #################

  $fhrd = new FileHandle "$file", "<";
  @rdLines = <$fhrd>;
  $fhrd->close;

  $fhwr = new FileHandle "$file", ">";
  if ($isDef & 1 << $LOGFILE) {$fhlog = new FileHandle ">> $logfile";}
  while ($_ = shift @rdLines) {
    s/\n//;
    (@columnElements) = split /\s+/, $_;
    $imgCol = $#columnElements - 1;
    if ((($#columnElements == 1) or ($#columnElements == 2)) and 
    				(grep /$columnElements[$imgCol]/, @images)) {
      $imgCpy = $columnElements[$imgCol];
      $oldRoot = dirname($columnElements[$imgCol]);
      $oldRoot =~ s/^\.//;
      $imgCpy =~ s/^$oldRoot/$newRoot/;
      $imgCpy =~ s/\/\//\//g;
      $columnElements[$imgCol] =~ s/(\.fits|\.imh)$//;
      $imgCpy =~ s/(\.fits|\.imh)$//;
    # check if that file number has already been used
      if (-e "$imgCpy.$imType") {
        $imgCpy =~ /(\d\d\d)$/;
	 $newID = $1 + 100;
	 for (;;) {
	   $imgCpy =~ s/\d\d\d$/$newID/;
	   last if !(-e "$imgCpy.$imType");
	   $newID += 100;
	 }
      }
    # done
      print "$columnElements[$imgCol].$imType -> $imgCpy.$imType ... ";
      if (defined $fhlog) {print $fhlog "    $columnElements[$imgCol].$imType -> ";}
      if (copy((join '', $columnElements[$imgCol],'.',$imType), 
      	        (join '',$imgCpy,'.',$imType))) {
        if ($#columnElements == 1) {
	 	unshift @columnElements, join '',$imgCpy,'.',$imType;
	 }
	 print " done\n";
	 if (defined $fhlog) {print $fhlog "$imgCpy.$imType\n";}
      }
      else {
        print "*** WARNING!!! Could not copy.\n";
	 if (defined $fhlog) {print $fhlog "*** WARNING!!! Could not copy.\n";}
      }
    }
    $fhwr-> print ("@columnElements\n");
  }
  $fhwr->close;
  if (defined $fhlog) {$fhlog->close;}

  $" = ' ';
  return();
}

#-------------------------\
#    DataSecAfterTrim      \
#---------------------------\
sub dataSecAfterTrim {
  my ($ccdsec,$trimsec) = @_;
  my ($datasec);
  my ($cx2,$cy2);
  my ($tx1,$ty1);

  $ccdsec =~ /\[\d+:(\d+),\d+:(\d+)\]/;
  $cx2=$1;
  $cy2=$2;
  $trimsec =~ /\[(\d+):\d+,(\d+):\d+\]/;
  $tx1=$1;
  $ty1=$2;
  $datasec = join '','[1:',$cx2-$tx1+1,',1:',$cy2-$ty1+1,']';
  
  return($datasec);
}



#-------------------------\
#          dcsel           \
#---------------------------\
sub dcsel {
 my ($reducRoot,$instRef,$rec) = @_;
 my (@img,$image,$selDbase,$options);
 my ($dcsel) = $CCDred::dcsel;
 my ($dccorBit) = 7;

 #Read extraParamFile
 $extraParamFile = 
    "$$instRef{'directory'}/$$instRef{'site'}/$$instRef{'instrument'}.param";
 %extraParam = Iraf::getParam("$extraParamFile",'=');
 $selDbase = $extraParam{'dccor.skydb'};
 undef %extraParam;

 foreach $image (sort keys %{ $rec }) {	#list of image with dccor flag
   if ($rec->{$image} & (1 << $dccorBit)) { push @img, $image; } 
 }
 $options = "--inst=$$instRef{'instrument'} --datadir=$reducRoot";
 system ("$dcsel @img -o $selDbase $options");

 return;
}

#-------------------------\
#   EditAlreadyCorrected   \
#---------------------------\
sub editAlreadyCorrected {
  my ($isDef,$logfile,$instRef,$correctionType,$rec,$epoch) = @_;
  my (@images) = ();
  my (@toEdit) = ();
  my ($bit,@goodLines,$fhPipeOut);
  my ($pattern,$date,$time);
  #Definitions
  my ($ccdlist) = $CCDred::ccdlist;
  my ($ccdhedit) = $CCDred::ccdhedit;

  SWITCH: {
    if (lc($correctionType) eq 'zero') {
      $bit =2;
      $pattern='dark|flat|object|other';
      last SWITCH;
    }
    if (lc($correctionType) eq 'dark') {
      $bit = 3;
      $pattern='flat|object|other';
      last SWITCH;
    }
    if (lc($correctionType) eq 'flat') {
      $bit = 4;
      $pattern='object|other';
      last SWITCH;
    }
    die "Error : No valid calibration type.\n";
  }

 #Find non-flagged images
  foreach $_ (keys % { $rec } ) {
    unless ($rec->{$_} & (1 << $bit)) {
      push @images, $_;
    }
  }

  if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
    $fhPipeOut = new FileHandle "$ccdlist @images --ccdtype='' --quiet --inst=$$instRef{'instrument'}|";
  } else {
    $fhPipeOut = new FileHandle "$ccdlist @images --ccdtype='' --quiet|";
  }
  @goodLines = grep /$pattern/, <$fhPipeOut>;
  $fhPipeOut->close();
  foreach $_ (@goodLines) {
    next if (/GRIZ/);
    /((\w|\.)+)/;
    push @toEdit, $1;
  }

  if ($#toEdit >= 0) {
    if ($isDef & 1 << $LOGFILE) {		#if defined logfile
      $fhlog = new FileHandle ">>$logfile";
      print $fhlog "\n$epoch: ",uc($correctionType)," CORRECTED AT TELESCOPE\n";
    }
    ($date,$time) = Util::datenTime(time);
    SWITCH: {
      if (lc($correctionType) eq 'zero') {
        $message = "$date $time Zero corrected at the telescope";
	 if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
	   system ("$ccdhedit @toEdit 'ZEROCOR' '$message' 'string' --inst=$$instRef{'instrument'}");
	 } else {
	   system ("$ccdhedit @toEdit 'ZEROCOR' '$message' 'string'");
	 }
	 if (defined $fhlog) {
	   foreach $_ (@toEdit) {print $fhlog "$_: $message\n";}
	 }
	 last SWITCH;
      }
      if (lc($correctionType) eq 'dark') {
        $message = "$date $time Dark corrected at the telescope";
	 if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
	   system ("$ccdhedit @toEdit 'DARKCOR' '$message' 'string' --inst=$i$instRef{'instrument'}");
	 } else {
	   system ("$ccdhedit @toEdit 'DARKCOR' '$message' 'string'");
	 }
	 if (defined $fhlog) {
	   foreach $_ (@toEdit) {print $fhlog "$_: $message\n";}
	 }
	 last SWITCH;
      }
      if (lc($correctionType) eq 'flat') {
        $message = "$date $time Flat corrected at the telescope";
	 if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
	   system ("$ccdhedit @toEdit 'FLATCOR' '$message' 'string' --inst=$$instRef{'instrument'}");
	 } else {
	   system ("$ccdhedit @toEdit 'FLATCOR' '$message' 'string'");
	 }
	 if (defined $fhlog) {
	   foreach $_ (@toEdit) {print $fhlog "$_: $message\n";}
	 }
	 last SWITCH;
      }
    }
  }
  return();
}


#-------------------------\
#       GetSection         \
#---------------------------\
sub getSection {
  my ($setFile) = @_;
  my ($fhrd,$junk,$instrument,$paramFile);
  my ($foundAll) = 0;
  my ($ccdsec,$trimsec);

  $paramFile = Iraf::whereParam($setFile);
  $fhrd = new FileHandle "$paramFile" or die "Cannot open $paramFile for reading.\n";
  while ( (<$fhrd>) ) {
    last if (/ccdred\.instrumentA/);
    next;
  }
  die "Cannot find instrument file information in $paramFile.\n" if (!defined $_);
  $fhrd->close();
  ($junk,$instrument) = split /=/;
  $instrument =~ s/\"|\s|\n//g;
  $fhrd = new FileHandle "$instrument" or die "Cannot open $instrument for reading.\n";
  $foundAll = 0;
  while (<$fhrd>) {
    if (/DATASEC/) {
      ($junk,$junk,$ccdsec) = split /\s+/;
      $ccdsec =~ s/\n//;
      $foundAll++;
    }
    if (/trimsec/) {
      ($junk,$junk,$trimsec) = split /\s+/;
      $trimsec =~ s/\n//;
      $foundAll++;
    }
    if ($foundAll == 2) {return ($ccdsec,$trimsec);}
  }
  $fhrd->close();

  die "Error:  Could not find 'DATASEC' and/or 'trimsec' in $instrument\n";
  return(0,0);
}



#-------------------------\
#      GoCorrection        \
#---------------------------\
sub goCorrection {
  my ($isDef,$logfile,$instRef,$setFile,$correctionType,$imgList,$rec,$epoch,$datasec,
  	$ccdsec) = @_;
  my (@images) = ();
  my (@dontimages) = ();
  my (@alreadyCorrected) = ();
  my ($bit,$command,$date,$time,$message);
  my (@recImages,@selImages,$img);
 #Definitions
  my ($ccdproc) = "nice -19 $CCDred::ccdproc";
  my ($ccdhedit) = "nice -19 $CCDred::ccdhedit";
  my ($ccdlist) = "nice -19 $CCDred::ccdlist";
  my ($imreplace) = "nice -19 $Images::imreplace";
  my ($findkey) = "nice -19 $CCDred::findkey";
  my ($pattern,$toEval);
  my ($darkCalib,$etime,@etimes,$etime_key,$datFile,$i);
  my (%etime_img) = ();
  my ($getkeyval) = $CCDred::getkeyval;
  my ($extraObstype) = "";

  unless ((lc($correctionType) eq 'overscan') or 
  					(lc($correctionType) eq 'trim') or
					(lc($correctionType) eq 'dc')) {
      my @imgs = ();
      @imgs = glob("$correctionType*.fits");
      die "Error : $correctionType images do not exist in ",cwd(),".\n" 
      					if ($#imgs < 0);
  }
  if ((lc($correctionType) eq 'skyflat') or 
  		(lc($correctionType) eq 'domeflat')) {
    $correctionType =~ s/(\w*)[F|f]lat/Flat/;
    $extraObstype = $1;
  }

  SWITCH: {
    if (lc($correctionType) eq 'overscan') {
      $bit=0;
      #$pattern = ':(\w|\s)+$';
      #$patternTRY = '.';
      $toEval = 'if ($_ =~ /(\[.+?\]){4}\[\w*?(B|O|T|Z|D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'trim') {
      $bit=1;
      #$pattern = '\[O\]:(\w|\s)+$';
      #$patternTRY = '.';
      $toEval = 'if (($rec->{$imName} & (1 << 0)) and
      				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(B|T|Z|D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'zero') {
      $bit = 2;
      #$pattern = '\[B?OT\]:(\w|\s)+$';
      $toEval = 'if (($rec->{$imName} & (1 << 0)) and
      				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(B|Z|D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'dark') {
      $bit = 3;
      $datFile=Iraf::whereParam($setFile);
      $datFile =~ s/\.cl/B\.dat/;
      #$pattern = '\[B?OTZ?\]:(\w|\s)+$';
      #$patternTRY = '.';
      $toEval = 'my (@files);
                 if (($rec->{$imName} & (1 << 0)) and
				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some images have not been bias corrected.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(D|F|I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'flat') {
      $bit = 4;
      #$pattern = '\[B?OTZ?D?\]:(\w|\s)+$';
      #$patternTRY = '\[\w*F\w*\]:(\w|\s)+$';
      $toEval = 'my (@files);
                 if (($rec->{$imName} & (1 << 0)) and
				!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some images have not been bias corrected.\n";
		   }
		   @files = ();
		   (@files) = <Dark*.fits>;
		   if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some images have not been dark corrected.\n";
		   }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some images have not been corrected for bad pixels.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(F|I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'illum') {
      $bit = 8;
      $toEval = 'my (@files);
      		   if (($rec->{$imName} & (1 << 0)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some images have not been bias corrected.\n";
		   }
		   @files = ();
		   (@files) = <Dark*.fits>;
		   if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some images have not been dark corrected.\n";
		   }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some images have not been corrected for bad pixels.\n";
		   }
		   @files = ();
		   (@files) = <Flat*.fits>;
		   if (($rec->{$imName} & (1 << 4)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?F\w*?\]:.*?$/)) {
			die "Some images have not been flat-fielded.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(I|Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'fringe') {
      $bit = 9;
      $toEval = 'my (@files);
      		   if (($rec->{$imName} & (1 << 0)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some images have not been bias corrected.\n";
		   }
		   @files = ();
		   (@files) = <Dark*.fits>;
		   if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some images have not been dark corrected.\n";
		   }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some images have not been corrected for bad pixels.\n";
		   }
		   @files = ();
		   (@files) = <Flat*.fits>;
		   if (($rec->{$imName} & (1 << 4)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?F\w*?\]:.*?$/)) {
			die "Some images have not been flat-fielded.\n";
		   }
		   @files = ();
		   (@files) = <Illum*.fits>;
		   if (($rec->{$imName} & (1 << 8)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?I\w*?\]:.*?$/)) {
			die "Some images have not been corrected for illumination.\n";
		   }
		   if ($_ =~ /(\[.+?\]){4}\[\w*?(Q)\w*?\]:.*?$/) {
		   	die "Some images have not been processed correctly.\n";
		   }';
      last SWITCH;
    }
    if (lc($correctionType) eq 'dc') {
      $bit = 7;
      $toEval = 'my (@files);
                 if (($rec->{$imName} & (1 << 0)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
			die "Some images have not been corrected for overscan.\n";
		   }
		   if (($rec->{$imName} & (1 << 1)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
			die "Some images have not been trimmed.\n";
		   }
		   @files = ();
		   (@files) = <Zero*.fits>;
		   if (($rec->{$imName} & (1 << 2)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
			die "Some images have not been bias corrected.\n";
		   }
		   @files = ();
		   (@files) = <Dark*.fits>;
		   if (($rec->{$imName} & (1 << 3)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
			die "Some images have not been dark corrected.\n";
		   }
                 if (($rec->{$imName} & (1 << 5)) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?B\w*?\]:.*?$/)) {
			die "Some images have not been corrected for bad pixels.\n";
		   }
		   @files = ();
		   (@files) = <Flat*.fits>;
		   if (($rec->{$imName} & (1 << 4)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?F\w*?\]:.*?$/)) {
			die "Some images have not been flat-fielded.\n";
		   }
		   @files = ();
		   (@files) = <Illum*.fits>;
		   if (($rec->{$imName} & (1 << 8)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?I\w*?\]:.*?$/)) {
			die "Some images have not been corrected for illumination.\n";
		   }
		   @file = ();
		   (@files) = <Fringe*.fits>;
		   if (($rec->{$imName} & (1 << 9)) and ($#files >= 0) and
		   		!($_ =~ /(\[.+?\]){4}\[\w*?Q\w*?\]:.*?$/)) {
		    	die "Some images have not been correction for fringing.\n";
		   }
		   if ( $status = system("$findkey $imName \'DCCOR\'") ) {
		       $status >>= 8;
			# Ok if status = 202
			if ($status == 0) {
		   	  die "Some images ($imName) have already been corrected for DC.\n";
			} elsif ($status != 202) {
			  die "Unknown error ($status) while searching for DCCOR keyword.\n";
			}
		   }';
       last SWITCH;
    }
    die "Error : No valid calibration type.\n";
  }

 #get the image list
  @recImages = keys % { $rec };
  if ($imgList ne "") {
     @selImages = Util::getListOf('-f','-l',$imgList,$epoch);
     foreach $img (@selImages) {
       die "ERROR: '$epoch$img' has not been verified.\n" if (not grep /^$img$/, @recImages);
     }
  } else {
     @selImages = @recImages
  }

 #Find images that were flaged
  foreach $_ ( @selImages ) {
    ($rec->{$_} & (1 << $bit)) ? push @images, $_ :
    				     push @dontimages, $_ ;
  }

  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $fhlog = new FileHandle ">> $logfile";
    print $fhlog "\n$epoch: \U$extraObstype$correctionType\E\n";
  }
 #For overscan and trim, edit header of @dontimages
  if (lc($correctionType) eq 'overscan') {
    if ($#dontimages >= 0) {
      foreach $_ (@dontimages) {
        #Get current date and time
         ($date,$time) = Util::datenTime(time);
        #Change header
         print ("Edit header of $_\n");
	  $message = "$date $time Overscan corrected at the telescope";
	  if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
	    system ("$ccdhedit $_ 'OVERSCAN' '$message' 'string'  -inst=$$instRef{'instrument'}");
	    system ("$ccdhedit $_ 'DATASEC' '$ccdsec' 'string' --inst=$$instRef{'instrument'}");
	  } else {
	    system ("$ccdhedit $_ 'OVERSCAN' '$message' 'string'");
	    system ("$ccdhedit $_ 'DATASEC' '$ccdsec' 'string'");
	  }
	  if (defined $fhlog) {
	    print $fhlog "$epoch/$_: $message\n";
	    print $fhlog "$epoch/$_: DATASEC set to $ccdsec\n";
	  }
	  $message = "$date $time No CCD processing done yet";
	  if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
	    system ("$ccdhedit $_ 'CCDPROC' '$message' 'string' --inst=$$instRef{'instrument'}");
	  } else {
	    system ("$ccdhedit $_ 'CCDPROC' '$message' 'string'");
	  }
	  if (defined $fhlog) {print $fhlog "$epoch/$_: $message\n";}
      }
    }
  }
  if (lc($correctionType) eq 'trim') {
    if ($#dontimages >= 0) {
      foreach $_ (@dontimages) {
        #Get current date and time
	  ($date,$time) = Util::datenTime(time);
	 #Change header
	  print("Edit header of $_\n");
	  $message = "$date $time Trimmed at the telescope";
	  if (defined $instrument) {
	    system ("$ccdhedit $_ 'TRIM '$message' 'string' --inst=$$instRef{'instrument'}");
	    system ("$ccdhedit $_ 'DATASEC' '$ccdsec' 'string' --inst=$$instRef{'instrument'}");
	  } else {
	    system ("$ccdhedit $_ 'TRIM '$message' 'string'");
	    system ("$ccdhedit $_ 'DATASEC' '$ccdsec' 'string'");
	  }
	  if (defined $fhlog) {
	    print $fhlog "$epoch/$_: $message\n";
	    print $fhlog "$epoch/$_: DATASEC set to $ccdsec\n";
	  }
	  $message = "$date $time No CCD processing done yet";
	  if ($isDef & $INSTRUMENT) {		#if defined instrument
	    system ("$ccdhedit $_ 'CCDPROC' '$message' 'string' --inst=$$instRef{'instrument'}");
	  } else {
	    system ("$ccdhedit $_ 'CCDPROC' '$message' 'string'");
	  }
	  if (defined $fhlog) {print $fhlog "$epoch/$_: $message\n";}
      }
    }
  }

 #If no flagged image, return
  unless ($#images >=0) {
    print "No $extraObstype$correctionType correction needed for this epoch.\n";
    if (defined $fhlog) {
      print $fhlog "No $extraObstype$correctionType correction needed for $epoch.\n";
      $fhlog->close;
    }
    return();
  }
  if (defined $fhlog) {$fhlog->close;}

 #Make sure the images have been pre-processed.
 #Images might or might not need 'bad pixel' and/or 'dark' correction
  if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
    $fhPipeOut = new FileHandle "$ccdlist @images --quiet --inst=$$instRef{'instrument'}|" 
    		or die "Unable to pipe.\n";
  } else {
    $fhPipeOut = new FileHandle "$ccdlist @images --quiet|" or die "Unable to pipe.\n";
  }
  while (<$fhPipeOut>) {
    /^((\w|\.|-)+)\[/;
    $imName = $1;
    if (!defined (eval "$toEval")) {
      die "$@";
    }    
  }
  $fhPipeOut->close();

 #Do the correction
 # Before doing flat field correction, replace small pixel values in Flats by 1.
  if (lc($correctionType) eq 'flat') {
    @Flats = glob("${extraObstype}Flat*.fits");
    $command = "$imreplace @Flats --value=1 --upper=0.8 -log $logfile";
    system "$command";
  }
  if (lc($correctionType) eq 'dark') {
    #Find exptime of data frames
    $etime_key = Iraf::getTrans($datFile,'exptime',2);
    if ($etime_key eq 'exptime') {
      die "Exiting.\n";		#no translation found.
    }
    $pipe = "$getkeyval @images -k $etime_key -d 'float'";
    $fhPipeOut = new FileHandle "$pipe |";
    @etimes = <$fhPipeOut>;
    $fhPipeOut->close();
    for ($i=0; $i<=$#images; $i++) {
      $etimes[$i] =~ s/\n//;
      push @{ $etime_img{$etimes[$i]} }, $images[$i];
    }
    undef @etimes;
    sub numerically { $a <=> $b;}
    foreach $etime (sort numerically keys %etime_img) {
      $etime =~ /(\d+)\.(\d*?)0*$/;
      $darkCalib = $correctionType.$1.$2.'.fits'; 
      $command = "$ccdproc @{$etime_img{$etime}} --".lc($correctionType).
      		   " --ccdproc.dark=$darkCalib";
      if ($isDef & 1 << $INSTRUMENT) { $command .= " --inst=$$instRef{'instrument'}"; }
      system ("$command") == 0 
      		or die "Error while doing $correctionType correction.\n";
    }
  }
  else {
    $command = "$ccdproc @images --\L$extraObstype$correctionType\E";  #default ccdtype=''
    if ($isDef & 1 << $INSTRUMENT) { $command .= " --inst=$$instRef{'instrument'}"; }
    system ("$command") == 0 or die "Error while doing $extraObstype$correctionType correction.\n";
  }

 #Make sure DATASEC is correct.  If the instrument .dat is setup correctly
 #  I don't really need a DATASEC keyword, but just to be on the safe side.
  if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
    system ("$ccdhedit @images 'DATASEC' '$datasec' 'string' --inst=$$instRef{'instrument'}");
  } else {
    system ("$ccdhedit @images 'DATASEC' '$datasec' 'string'");
  }
  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $message = "";
    foreach $_ (@images) { $message .= "$_: DATASEC set to $datasec\n"; }
    Iraf::printlog($logfile,$message);
  }
  return();
}

#-------------------------\
#        GoFixPix          \
#---------------------------\
sub goFixPix {
  my ($isDef,$logfile,$instRef,$flag,$rec,$epoch) = @_;
  my ($fixpix) = "nice -19 $CCDred::fixbadpix";
  my ($ccdhedit) = "nice -19 $CCDred::ccdhedit";
  my ($ccdlist) = "nice -19 $CCDred::ccdlist";
  my ($cnstArg,$bit,$movebit,$pattern,$toEval);
  my (@all) = ();
  my (@both) = ();
  my (@badOnly) = ();
  my (@moveOnly) = ();
  my ($date,$time);
  my ($bad,$moving,$ptrnFile);
  my ($ext,$status,$ERRBAD,$ERRMOVE);

  $status=0;
  $ERRBAD=1;
  $ERRMOVE=2;

  $cnstArg = "-mbox 21 21 -sbox 21 21 -threshold 2 -noise 1";
  $bit = 5;
  $movebit = 6;
  $toEval = 'my (@files);
             if (($rec->{$image} & (1 << 0)) and
  			!($_ =~ /(\[.+?\]){4}\[\w*?O\w*?\]:.*?$/)) {
		    die "Some images have not been corrected for overscan.\n";
	      }
	      if (($rec->{$image} & (1 << 1)) and
		   	!($_ =~ /(\[.+?\]){4}\[\w*?T\w*?\]:.*?$/)) {
		    die "Some images have not been trimmed.\n";
	      }
	      @files = ();
	      (@files) = <Zero*.fits>;
	      if (($rec->{$image} & (1 << 2)) and ($#files >= 0) and
		   	!($_ =~ /(\[.+?\]){4}\[\w*?Z\w*?\]:.*?$/)) {
		    die "Some images have not been bias corrected.\n";
	      }
	      @files = ();
	      (@files) = <Dark*.fits>;
	      if (($rec->{$image} & (1 << 3)) and ($#files >= 0) and
		   	!($_ =~ /(\[.+?\]){4}\[\w*?D\w*?\]:.*?$/)) {
		    die "Some images have not been dark corrected ($image).\n";
	      }';


  #Find image that were flagged
  foreach $_ (keys % { $rec }) {
    if (($rec->{$_} & (1 << $bit)) and ($rec->{$_} & (1 << $movebit))) 
    						{s/\.fits//; push @both, $_;}
    elsif ($rec->{$_} & (1 << $bit)) 	{s/\.fits//; push @badOnly, $_;}
    elsif ($rec->{$_} & (1 << $movebit)) 	{s/\.fits//; push @moveOnly, $_;}
  }
  
  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $fhlog = new FileHandle ">>$logfile";
    print $fhlog "\n$epoch: FIX BAD PIXELS\n";
  }

 $|=1;			#OUTPUT_AUTOFLUSH ON
 #Identify what's needed, if nothing return
 # both
  if ($#both >= 0)  {
    if (($flag & $FIXPIX) && ($flag & $MOVFIXPIX)) {
      print "\nWill correct for fixed and moving bad pixel patterns.\n\n";
      if (defined $fhlog) {print $fhlog "\tCorrection for fixed and moving bad pixel patterns.\n";}
    }elsif ($flag & $FIXPIX) {
      print "\tWARNING: Should correct for fixed and moving bad pixels but 'movfixpix'\n",
            "\t\thas not been activated.\n";
      print "\tWARNING: Correcting for fixed bad pixels only.\n";
      print "\tWARNING: No moving bad pixels correction applied for:\n";
      if (defined $fhlog) {
        print $fhlog "\tWARNING: Should correct for fixed and moving bad pixels but 'movfixpix'\n";
	 print $fhlog "\t\thas not been activated.\n";
	 print $fhlog "\tWARNING: Correcting for fixed bad pixels only.\n";
	 print $fhlog "\tWARNING: No moving bad pixels correction applied for:\n";
      }
      foreach $_ (@both) {
        print "\t\t\t$_\n";
	 if (defined $fhlog) {print $fhlog "\t\t\t$_\n";}
      }
      push @badOnly, @both;
      @both = ();
    }else {
      print "\tWARNING: Should correct for fixed and moving bad pixels but 'fixpix'\n",
            "\t\thas not been activated.\n";
      print "\tWARNING: Correcting for moving bad pixels only.\n";
      print "\tWARNING: No fixed bad pixels correction applied for:\n";
      if (defined $fhlog) {
        print $fhlog "\tWARNING: Should correct for fixed and moving bad pixels but 'fixpix'\n";
	 print $fhlog "\t\thas not been activated.\n";
	 print $fhlog "\tWARNING: Correcting for moving bad pixels only.\n";
	 print $fhlog "\tWARNING: No fixed bad pixels correction applied for:\n";
      }
      foreach $_ (@both) {
        print "\t\t\t$_\n";
	 if (defined $fhlog) {print $fhlog "\t\t\t$_\n";}
      }
      push @moveOnly, @both;
      @both = ();
    }
  }

 # badOnly
  if ($#badOnly >= 0) {
    if ($flag & $FIXPIX) {
      print "\nWill correct for fixed bad pixel pattern.\n\n";
      if (defined $fhlog) {print $fhlog "Correction for fixed bad pixel pattern.\n";}
    }else {
      print "\tWARNING: Should correct for fixed bad pixels but 'fixpix'\n",
            "\t\thas not been activated.\n";
      print "\tWARNING: No fixed bad pixels correction applied for:\n";
      if (defined $fhlog) {
        print $fhlog "\tWARNING: Should correct for fixed bad pixels but 'fixpix'\n";
	 print $fhlog "\t\thas not been activated.\n";
	 print $fhlog "\tWARNING: No fixed bad pixels correction applied for:\n";
      }
      foreach $_ (@badOnly) {
        print "\t\t\t$_\n";
	 if (defined $fhlog) {print $fhlog "\t\t\t$_\n";}
      }
      @badOnly = ();
      $status = $ERRBAD;
    }
  }

 # moveOnly
  if ($#moveOnly >= 0) {
    if ($flag & $MOVFIXPIX) {
      print "\nWill correct for moving bad pixel pattern.\n\n";
      if (defined $fhlog) {print $fhlog "Correction for moving bad pixel pattern.\n";}
    }else {
      print "\tWARNING: Should correct for moving bad pixels but 'movfixpix'\n",
            "\t\thas not been activated.\n";
      print "\tWARNING: No moving bad pixels correction applied for:\n";
      if (defined $fhlog) {
        print $fhlog "\tWARNING: Should correct for moving bad pixels but 'movfixpix'\n";
	 print $fhlog "\t\thas not been activated.\n";
	 print $fhlog "\tWARNING: No moving bad pixels correction applied for:\n";
      }
      foreach $_ (@moveOnly) {
        print "\t\t\t$_\n";
	 if (defined $fhlog) {print $fhlog "\t\t\t$_\n";}
      }
      @moveOnly = ();
      $status = $ERRMOVE;
    }
  }

 # Nothing
  if (($#both < 0) && ($#badOnly < 0) && ($#moveOnly < 0)) {
    if ($status == 0) {
      print "No bad pixel correction needed for this epoch.\n";
      if (defined $fhlog) {print $fhlog "No bad pixel correction needed for $epoch\n";}
    }elsif ($status == $ERRBAD) {
      print "WARNING: No bad pixel correction for this epoch because 'fixpix'\n",
            "\thas not been activated.\n";
      if (defined $fhlog) {
        print $fhlog "WARNING: No bad pixel correction for this epoch because 'fixpix'\n";
	 print $fhlog "\thas not been activated.\n";
      }
    }elsif ($status == $ERRMOVE) {
      print "WARNING: No bad pixel correction for this epoch because 'movfixpix'\n",
            "\thas not been activated.\n";
      if (defined $fhlog) {
        print $fhlog "WARNING: No bad pixel correction for this epoch because 'movfixpix'\n";
        print $fhlog "\thas not been activated.\n";
      }
    }else {
      if (defined $fhlog) {$fhlog->close;}
      die "ERROR: Unknown error in GoFixPix.\n";
    }
    if (defined $fhlog) {$fhlog->close;}
    return();
  }
  if (defined $fhlog) {$fhlog->close;}
  $|=0;		#OUTPUT_AUTOFLUSH OFF

  #Make sure the images have been pre-processed (Overscan & Trim)
  push @all, @both, @badOnly, @moveOnly;
  if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
    $fhPipeOut = new FileHandle "$ccdlist @all --quiet --inst=$$instRef{'instrument'}|";
  } else {
    $fhPipeOut = new FileHandle "$ccdlist @all --quiet|";
  }
  while (<$fhPipeOut>) {
    #get subset (i.e. chip number) and store in hash
    $image = 0;
    /^((\w|\.|-)+)\[/;
    $image = $1;
    if (!$image) { die "Error in fixpix($epoch): $image, $1, $_";}
    if ($isDef & 1 << $CHECKCAM) {		#if checkcam == true
      /\[\D+(\d+)\]\[\w+\]:.*?$/;
      $subset = $1;
    }
    else {$subset='';}
    $epoch =~ /\/\w(\d+)\/$/;
    if ($checkcam) {
      SWITCH: {
        if ($1 >= $camBoundary000000) {$ext = '.000000';} else { last SWITCH; }
        if ($1 >= $camBoundary831000) {$ext = '.831000';} else { last SWITCH; }
        if ($1 >= $camBoundary831012) {$ext = '.831012';} else { last SWITCH; }
        if ($1 >= $camBoundary831013) {$ext = '.831013';} else { last SWITCH; }
	 if ($1 >= $camBoundary840524) {$ext = '.840524';} else { last SWITCH; }
	 if ($1 >= $camBoundary840927) {$ext = '.840927';} else { last SWITCH; }
        if ($1 >= $camBoundary840928) {$ext = '.840928';} else { last SWITCH; }
        if ($1 >= $camBoundary840930) {$ext = '.840930';} else { last SWITCH; }
	 if ($1 >= $camBoundary850323) {$ext = '.850323';} else { last SWITCH; }
	 if ($1 >= $camBoundary850324) {$ext = '.850324';} else { last SWITCH; }
        if ($1 >= $camBoundary870926) {$ext = '.870926';} else { last SWITCH; }
        if ($1 >= $camBoundary890409) {$ext = '.890409';} else { last SWITCH; }
        if ($1 >= $camBoundary890831) {$ext = '.890831';} else { last SWITCH; }
	 if ($1 >= $camBoundary901000) {$ext = '.901000';} else { last SWITCH; }
      }
      $subset .= $ext;
    }
    else {$subset .= ".$1";}
    s/\n//;
    if (!defined (eval "$toEval")) {
      $fhPipeOut->close();
      die "$@";
    }
    $image =~ s/\.fits//;
    $subsets{$image} = $subset;
  }
  $fhPipeOut->close();

  # Images created by fixbadpix
  @goners = ('median.fits', 'bad.fits','mask.fits','moving.fits');

  #Do the correction
  foreach $image (@both) {
    $status = 0;
    $moving = 'MaskMove'.$subsets{$image}.'.dat';
    $bad = 'Mask'.$subsets{$image}.'.dat';
    $ptrnFile = 'Pattern'.$subsets{$image}.'.dat';
    $correction = "-p $ptrnFile -moving $moving -bad $bad";
    $newimage = $image;
    if ($isDef & 1 << $LOGFILE) {		#if defined logfile
      $command = "$fixpix $image.fits -o $newimage.fits $cnstArg $correction --log=$logfile";
    }else {
      $command = "$fixpix $image.fits -o $newimage.fits $cnstArg $correction";
    }
    if ($isDef & 1 << $LOGFILE) {		#if defined logfile
      Iraf::printlog($logfile,"$image:\n");
    }
    if (system ("$command") != 0) { 
      print "\n*** Error fixing bad pixels of $image\n";
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\tERROR: Error fixing bad pixels\n");
      }
      $status=1;
    }
    if ($status == 0) {
      ($date,$time) = Util::datenTime(time);
      $comment = "$date $time With $bad and $moving";
      if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string' --inst=$$instRef{'instrument'}");
      } else {
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string'");
      }
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\t\t$comment\n");
      }
    }
   # Delete process images create by fixbadpix
    @cannot = grep {not unlink} @goners;
    foreach $cant (@cannot) {
      die "Could not unlink $cant\n" if (-e $cant);
    }
  }

  foreach $image (@badOnly) {
    $status = 0;
    $bad = 'Mask'.$subsets{$image}.'.dat';
    $correction = "-bad $bad";
    $newimage = $image;
    $command = "$fixpix $image.fits -o $newimage.fits $correction";
    if ($isDef & 1 << $LOGFILE) {		#if defined logfile
      Iraf::printlog($logfile,"$image:\n");
    }
    if (system ("$command") != 0) {
      print "\n*** Error fixing bad pixels of $image\n";
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\tERROR: Error fixing bad pixels\n");
      }
      $status=1;
    }
    if ($status == 0) {
      ($date,$time) = Util::datenTime(time);
      $comment = "$date $time Bad pixel file is $bad";
      if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string' --inst=$$instRef{'instrument'}");
      } else {
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string'");
      }
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\t\t$comment\n");
      }
    }
   # Delete process images create by fixbadpix
    @cannot = grep {not unlink} @goners;
    foreach $cant (@cannot) {
      die "Could not unlink $cant\n" if (-e $cant);
    }
  }

  foreach $image (@moveOnly) {
    $status = 0;
    $moving = 'MaskMove'.$subsets{$image}.'.dat';
    $ptrnFile = 'Pattern'.$subsets{$image}.'.dat';
    $correction = "-p $ptrnFile -moving $moving";
    $newimage = $image;
    $command = "$fixpix $image.fits -o $newimage.fits $cnstArg $correction";
    if ($isDef & 1 << $LOGFILE) {		#if defined logfile
      Iraf::printlog($logfile,"$image:\n");
    }
    if (system ("$command") != 0) {
      print "\n*** Error fixing bad pixels of $image\n";
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\tERROR: Error fixing bad pixels\n");
      }
      $status=1;
    }
    if ($status == 0) {
      ($date,$time) = Util::datenTime(time);
      $comment = "$date $time Bad pixel file is $moving";
      if ($isDef & 1 << $INSTRUMENT) { 		#if defined instrument
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string' --inst=$$instRef{'instrument'}");
      } else {
        system ("$ccdhedit $newimage 'FIXPIX' '$comment' 'string'");
      }
      if ($isDef & 1 << $LOGFILE) {		#if defined logfile
        Iraf::printlog($logfile,"\t\t$comment\n");
      }
    }
   # Delete process images create by fixbadpix
    @cannot = grep {not unlink} @goners;
    foreach $cant (@cannot) {
      die "Could not unlink $cant\n" if (-e $cant);
    }
  }
  return();
}



#-------------------------\
#      LookForCalib        \
#---------------------------\
sub lookForCalib {
  my ($isDef,$logfile,$instRef,$setFile,$calibType,$imgList,$rec,$epoch,
  	$calibDir) = @_;
  my (@types,@recImages,@imagesTmp,@images,$image,$img,@subsets,$i);
  my (@shortepochs,$epochOnly,$fhpipe,$message);
  my ($ok) = -1;
  my ($return) = 0;
  my ($pattern,$cwd);
  my ($datFile,$etime_key,@etimes,$etime);
  # Definitions
  my ($ccdlist) = $CCDred::ccdlist;
  my ($getkeyval) = $CCDred::getkeyval;
  my ($extension) = $CCDred::imtype;
  my ($extraObstype) = "";

  # Check current dir content for already combined calib
  # Check calib dir content for combined calib
  #     if some {copy them over}
  # Check current dir content for raw calib.
  # Return whether or not some of the above exist.

  if ($calibType =~ /\|/) {
    (@types) = split /\|/, $calibType;
    $calibType = $types[0];
  }
  
  if ((lc($calibType) eq 'skyflat') or (lc($calibType) eq 'domeflat')) {
    $calibType =~ s/(\w*)[F|f]lat/Flat/;
    $extraObstype = $1;
  }

 #get the image list
  @imageTmp = ();
  @recImages = keys % { $rec };
  if ($imgList ne "") {
     @imagesTmp = Util::getListOf('-f','-l',$imgList,$epoch);
     foreach $img (@imagesTmp) {
       die "ERROR: '$epoch$img' has not been verified.\n" if (not grep /^$img$/, @recImages);
     }
  } else {
     @imagesTmp = @recImages
  }
  
 #From the image list, keep only the one requiring the correction
  @images = ();
  foreach $img (@imagesTmp) {
    if ( (lc($calibType) eq 'mask') and ($rec->{$img} & (1 << 5)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'maskmove') and ($rec->{$img} & (1 << 6)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'pattern') and ($rec->{$img} & (1 << 6)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'overscan') and ($rec->{$img} & (1 << 0)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'trim') and ($rec->{$img} & (1 << 1)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'zero') and ($rec->{$img} & (1 << 2)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'dark') and ($rec->{$img} & (1 << 3)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'flat') and ($rec->{$img} & (1 << 4)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'sky') ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'illum') and ($rec->{$img} & (1 << 8)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'fringe') and ($rec->{$img} & (1 << 9)) ) {
    	push @images, $img;
    }
    elsif ( (lc($calibType) eq 'dc') and ($rec->{$img} & (1 << 7)) ) {
    	push @images, $img;
    }
    else {
    	next;
    }
  }
  
 #find the subsets found in the list of images
  @subsets=();
  if ((lc($calibType) eq 'mask') || 
  		(lc($calibType) eq 'maskmove') ||
		(lc($calibType) eq 'pattern')){
    if (lc($calibType) eq 'pattern') {
    	$message = "ERROR: Error while searching for patterns.\n";
    }else {
    	$message = "ERROR: Error while searching for masks.\n";
    }
    if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
      $fhpipe = new FileHandle 
      		qq($ccdlist @images --ccdtype="" --quiet --inst=$$instRef{'instrument'}|)
    		or die "$message";
    } else {
      $fhpipe = new FileHandle qq($ccdlist @images --ccdtype="" --quiet|)
    		or die "$message";
    }
    while (<$fhpipe>) {
      if ($isDef & 1 << $CHECKCAM) {	# if checkcam == true
        next if (!(/\[\D+(\d+)\]\[\w+\]:.*?$/));
        $subset=$1;
      }
      else {$subset = '';}
      $epoch =~ /\/\w(\d+)\/$/;
      if ($isDef & 1 << $CHECKCAM) {		#if checkcam == true
	 SWITCH: {
          if ($1 >= $camBoundary000000) {$ext = '.000000';} else { last SWITCH; }
          if ($1 >= $camBoundary831000) {$ext = '.831000';} else { last SWITCH; }
          if ($1 >= $camBoundary831012) {$ext = '.831012';} else { last SWITCH; }
          if ($1 >= $camBoundary831013) {$ext = '.831013';} else { last SWITCH; }
	   if ($1 >= $camBoundary840524) {$ext = '.840524';} else { last SWITCH; }
          if ($1 >= $camBoundary840927) {$ext = '.840927';} else { last SWITCH; }
          if ($1 >= $camBoundary840928) {$ext = '.840928';} else { last SWITCH; }
          if ($1 >= $camBoundary840930) {$ext = '.840930';} else { last SWITCH; }
	   if ($1 >= $camBoundary850323) {$ext = '.850323';} else { last SWITCH; }
	   if ($1 >= $camBoundary850324) {$ext = '.850324';} else { last SWITCH; }
          if ($1 >= $camBoundary870926) {$ext = '.870926';} else { last SWITCH; }
          if ($1 >= $camBoundary890409) {$ext = '.890409';} else { last SWITCH; }
          if ($1 >= $camBoundary890831) {$ext = '.890831';} else { last SWITCH; }
	   if ($1 >= $camBoundary901000) {$ext = '.901000';} else { last SWITCH; }
	 }
	 $subset .= $ext;
      }
      else {$subset .= ".$1";}
      next if (grep /$subset/, @subsets);
      push @subsets, $subset;
    }
    $fhpipe->close();
    $extension = 'dat';
  }
  elsif (lc($calibType) eq 'dark') {
    $datFile = Iraf::whereParam($setFile);
    $datFile =~ s/\.cl$/B\.dat/;
    $etime_key = Iraf::getTrans($datFile,'exptime',2);
    if ($etime_key eq 'exptime') {
      die "Exiting.\n";		#no translation found.
    }
    #Get exposure time for each data frame
    $pipe = "$getkeyval @images -k $etime_key -d 'float'";
    $fhPipeOut = new FileHandle "$pipe | ";
    @subsets = <$fhPipeOut>;
    $fhPipeOut->close();
    foreach $subset (@subsets) {
      $subset =~ s/\n//;
      $subset =~ s/(\d+)\.(\d*?)0*$/$1$2/;
    }
  }
  elsif (lc($calibType) eq 'flat') {
    if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
      $fhpipe = new FileHandle "$ccdlist @images --quiet --inst=$$instRef{'instrument'}|" 
    			or die "ERROR: Error while searching for flat subsets\n";
    } else {
      $fhpipe = new FileHandle "$ccdlist @images --quiet|" 
    			or die "ERROR: Error while searching for flat subsets\n";
    } 
    while (<$fhpipe>) {
      next if (/GRIZ/);
      s/\n//;
      /\[(\w+)\]\[\w+\]:.*?$/;
      next if (grep /$1/, @subsets);
      push @subsets, $1;
    }
    $fhpipe->close();
  }
  elsif (lc($calibType) eq 'sky') {
    foreach $image (@images) {
      $image =~ /(e\d+\/)/;
      next if (grep /$1/, @shortepochs);
      push @shortepochs, $1;
    }
    if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
      $fhpipe = new FileHandle "$ccdlist @images --quiet --inst=$$instRef{'instrument'}|"
      			or die "ERROR: Error while searching for sky subsets\n";
    } else {
      $fhpipe = new FileHandle "$ccdlist @images --quiet|"
      			or die "ERROR: Error while searching for sky subsets\n";
    }
    while (<$fhpipe>) {
      next if (/GRIZ/);
      s/\n//;
      /\[(\w+)\]\[\w+\]:.*?$/;
      next if (grep /$1/, @subsets);
      push @subsets, $1;
    }
    $fhpipe->close();
  }
  elsif (lc($calibType) eq 'illum') {
    if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
      $fhpipe = new FileHandle "$ccdlist @images --quiet --inst=$$instRef{'instrument'}|"
      		or die "ERROR: Error while searching for illum subsets\n";
    } else {
      $fhpipe = new FileHandle "$ccdlist @images --quiet|"
      		or die "ERROR: Error while searching for illum subsets\n";
    }
    while (<$fhpipe>) {
      next if (/GRIZ/);
      s/\n//;
      /\[(\w+)\]\[\w+\]:.*?$/;
      next if (grep /$1/, @subsets);
      push @subsets, $1;
    }
    $fhpipe->close();
  }
  elsif (lc($calibType) eq 'fringe') {
    if ($isDef & 1 << $INSTRUMENT) {		#if defined instrument
      $fhpipe = new FileHandle "$ccdlist @images --quiet --inst=$$instRef{'instrument'}|"
      		or die "ERROR: Error while searching for fringe subsets\n";
    } else {
      $fhpipe = new FileHandle "$ccdlist @images --quiet|"
      		or die "ERROR: Error while searching for fringe subsets\n";
    }
    while (<$fhpipe>) {
      next if (/GRIZ/);
      s/\n//;
      /\[(\w+)\]\[\w+\]:.*?$/;
      next if (grep /$1/, @subsets);
      push @subsets, $1;
    }
    $fhpipe->close();
  }
  elsif (lc($calibType) eq 'dc'){
    #This one is sufficient different to justify a brand new subroutine
    @images = keys % { $rec };
    return( CCDred::lookForDC(\%inst,$epoch,@images) );
  }
  else {push @subsets, 'none';}

 #clear @images
  @images = ();

  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $fhlog = new FileHandle ">>$logfile";
    $cwd=cwd();
  }
  
 #check what's available for each subset
  SUBSET: foreach $subset (@subsets) {
    $subset =~ s/none//;
    if (grep /${extraObstype}${calibType}$subset\.$extension/, 
    		glob ("${extraObstype}$calibType*.$extension")) {
      if (lc($calibType) eq 'sky') {
        print "${calibType}$subset found in current directory.\n";
      }
      else {
        print "${extraObstype}${calibType}$subset for $epoch found in current directory.\n";
      }
      if (defined $fhlog) {
        if (lc($calibType eq 'sky')) {
	   print $fhlog "${calibType}$subset found in $cwd\n";
	 }
	 else {
          print $fhlog "$epoch: ${extraObstype}${calibType}$subset found in $cwd\n";
	 }
      }
      $ok++;
      unless ($return == 3) {$return=2;}
      last if ($ok eq $#subsets);
    }
    else {
      if (defined $calibDir) {
	unless (lc($calibType) eq 'sky') {
	  $epoch =~ /\/((\w|\d)+\/)$/;
          if ((lc($calibType) eq 'mask') || 
	 		(lc($calibType) eq 'maskmove') ||
			(lc($calibType) eq 'pattern')) {
	    $shortepochs[0]='';
	  } else {
	    $shortepochs[0]=$1;
	  }
	}
	EPOCH: foreach $epochOnly (@shortepochs) { # Only 'sky' has more than 1
	  $pattern=$calibDir.$epochOnly.$extraObstype.$calibType;
    	  @calibs=glob ("$pattern*.$extension");
	  if ((defined @calibs) and (grep /${extraObstype}${calibType}$subset\.$extension/, @calibs)) {
           $|=1;                          # OUTPUT_AUTOFLUSH : ON
	   if (lc($calibType) eq 'sky') { $epoch = $epochOnly; }
           print "${extraObstype}${calibType}$subset for $epoch found in ".$calibDir.$epochOnly.".\n";
	   if (defined $fhlog) {print $fhlog "$epoch: ${extraObstype}${calibType}$subset found in $calibDir$epochOnly.\n";}
           unless (lc($calibType) eq 'sky') {
              foreach $_ (grep /${extraObstype}${calibType}$subset\.$extension/, @calibs) {
        	print "$_ -> $epoch ... ";
        	copy($_,'.');
        	print "done\n";
		if (defined $fhlog) {print $fhlog "    $_ -> $epoch\n";}
              }
	    }
            $|=0;                          #OUTPUT_AUTOFLUSH : OFF
            $ok++;
            unless ($return == 3) {$return=2;}  #already combined were obtained from calibDir
            last SUBSET if ($ok eq $#subsets);
	    next SUBSET;
	  }
	  else { next EPOCH; }
	}
      }

      # No already combined; look for raw calib among the images available
      unless ((lc($calibType) eq 'mask') || 
      			(lc($calibType) eq 'maskmove') ||
			(lc($calibType) eq 'pattern')) {
	if ((lc($calibType) eq 'dark') || (lc($calibType) eq 'flat') ||
			(lc($calibType) eq 'sky')) {
	  @images = keys % { $rec };

	  $command = "$ccdlist @images --quiet";
	  if (lc($calibType) eq 'sky') {
	    $command .= ' --ccdtype=other';
	  } else { 
	    $command .= ' --ccdtype='.lc($calibType);
	  }
	  if ($isDef & 1 << $INSTRUMENT) { $command .= " --inst=$$instRef{'instrument'}"; }

	  $fhpipe = new FileHandle "$command|";
	  @images = ();
	  @images = <$fhpipe>;
	  $fhpipe->close();
	  if ( $#images >=0 ) {
	    $nCalib=0;
            #Find available subsets
	    if (lc($calibType) eq 'dark') {
	      foreach $image (@images) {
	        $image =~ s/\n//;
		$image =~ s/^(.*?)\[.*/$1/;
	      }
	      $pipe = "$getkeyval @images -k $etime_key -d 'float'";
	      $fhPipeOut = new FileHandle "$pipe |";
	      @etimes = <$fhPipeOut>;
	      $fhPipeOut->close();
	      foreach $etime (@etimes) {
		$etime =~ s/(\d+)\.(\d*?)0*$/$1$2/;
	      }
	      @rightSubset = grep /$subset/, @etimes;
	      if ($#rightSubset >= 0) {
		$nCalib=$#rightSubset + 1;
		 $ok++;
	      }
	    }
           elsif (lc($calibType) eq 'flat') {
	     @imNames=();
	     @goodtype=();
	     if ($extraObstype ne "") {
	       foreach $image (@images) {
		 $image =~ /((\w|\d)+\.\w*)\[/;
		 push @imNames, $1;
	       }
	       $i=0;
	       $fhpipe = new FileHandle "$getkeyval @imNames -k OBSTYPE -d string|";
	       while (<$fhpipe>) {
	         chop $_;
		 if (lc($_) eq lc("${extraObstype}${calibType}")) {
	       		  push @goodtype, $images[$i];
		 }
		 $i++;
	       }
	       $fhpipe->close();
	     }
	     else { push @goodtype, @images; }
             @rightSubset = grep /\[$subset\]\[\w+\]:.*?$/, @goodtype;
             if ($#rightSubset >= 0) {
       		$nCalib=$#rightSubset + 1;
       		$ok++;
             }
           }
	    elsif (lc($calibType) eq 'sky') {
	      @rightSubset = grep /\[$subset\]\[\w+\]:.*?$/, @images;
	      if ($#rightSubset >= 0) {
	      		$nCalib=$#rightSubset + 1;
			$ok++;
	      }
	    }
           else {
              $nCalib=$#images + 1;
              $ok++;
           }
	    if (lc($calibType) eq 'sky') {
	      print "$nCalib $subset blank sky were found somewhere in: \n";
	      foreach $_ (@epochs) {
	        /(\w+\/e\d+\/)$/;
	        print "\t$1\n";
	      }
	      if (defined $fhlog) {
	        foreach $_ (@epochs) {
		   /(\w+\/e\d+\/)$/;
	          print $fhlog "$1:";
		 }
		 print $fhlog " $nCalib $subset blank sky were found\n";
	      }
	    }
	    else {
             print ($nCalib, " raw ",lc($calibType),$subset," were found in current directory.\n");
	      if (defined $fhlog) {print $fhlog "$shortepochs[0]: $nCalib raw ",lc($calibType),$subset," were found in $cwd\n";}
	    }
	    $return=3;
	    last SUBSET if ($ok == $#subsets);
#	    last if ($ok == $#subsets);
	  }
	}
	elsif ((lc($calibType) eq 'illum') || (lc($calibType) eq 'fringe')) {
	  # Try to find other options
	  # For 'illum', try to find 'Sky'
	  # For 'fringe', try to find 'SkyIllum' or 'Sky' and 'Illum'
	  # If found, copy what was found to current epoch and proceed to 
	  # MkSmooth.
	  TYPE: for ($i=1; $i<=$#types; $i++) {
	    @types2Find = split /\+/, $types[$i];
	    $typeok=-1;
	    foreach $type2Find (@types2Find) {
	      if (grep /${type2Find}$subset\.$extension/, 
  				    glob ("${type2Find}*.$extension")) {	# found in cwd
		print "${type2Find}$subset for $epoch found in current directory.\n";
		if (defined $fhlog) {
		  print $fhlog "$epoch: ${type2Find}$subset found in $cwd\n";
		}
		$typeok++;
		if ($typeok == $#types2Find) { 	# found all
		  $ok++; 
		  $return=3;
		  last SUBSET if ($ok == $#subsets);
		}
	      }
	      elsif (defined $calibDir) {		# found in calibDir
		$epoch =~ /\/((\w|\d)+\/)$/;
		$epochOnly = $1;
		$pattern=$calibDir.$epochOnly.$type2Find;
		@calibs=glob ("$pattern*.$extension");
		if ((defined @calibs) and 
    				    (grep /${type2Find}$subset\.$extension/, @calibs)) {
		  $|=1;		#OUTPUT_AUTOFLUSH ON
		  print "${type2Find}$subset for $epoch found in ".$calibDir.$epochOnly."\n";
		  if (defined ($fhlog)) {
        	    print $fhlog "$epoch: ${type2Find}$subset found in $calibDir$epochOnly.\n";
		  }
		  $typeok++;
		  #Copy what was found
		  foreach $_ (grep /${type2Find}$subset\.$extension/, @calibs) {
        	    print "$_ -> $epoch ... ";
		    copy($_,'.');
		    print "done\n";
		    if (defined $fhlog) { print $fhlog "    $_ -> $epoch\n";}
		  }
		  if ($typeok == $#types2Find) {	# found all
        	    $|=0;		#OUTPUT_AUTOFLUSH OFF
		    $ok++;
		    $return=3;
		    last SUBSET if ($ok == $#subsets);
		    next SUBSET;
		  }
		}
	      }
	      else {		# did not find all components of this type, try next.
		next TYPE;
	      }
	    }
	  }
	}
      }
    }
  }
  if (defined $fhlog) {$fhlog->close;}

  ($ok == $#subsets) ? return($return) : return(0);
}


#-------------------------\
#        LookForDC         \
#---------------------------\
sub lookForDC {
 my ($instRef,$epoch,@img) = @_;
 my ($extraParamFile,%extraParam,%sel,$image,@skys,$sky);

 #Read dcsel output
 $extraParamFile = 
    "$$instRef{'directory'}/$$instRef{'site'}/$$instRef{'instrument'}.param";
 %extraParam = Iraf::getParam("$extraParamFile",'=');
 %sel = Iraf::getParam($extraParam{'dccor.skydb'},'::');
 undef %extraParam;

 foreach $image (@img) {
   if (defined $sel{"$epoch$image"}) {
     @skys = split /,/, $sel{"$epoch$image"};
     foreach $sky (@skys) {
       unless (-e $sky) { 	#Cannot find image
         print "Unable to find sky '$sky' for target '$image'\n";
         return(0);
       }     
     }
   }
 }

 return(1);		#all sky images were found, proceed with correction
}

#-------------------------\
#        MkFringe          \
#---------------------------\
sub mkFringe {
  my ($isDef,$instRef,$logfile,$epoch,$inType,$outType) = @_;
  my ($illumFile) = $$instRef{'directory'}.$$instRef{'site'}.'/'.$$instRef{'instrument'}.".illum";
  my ($command) = "nice -19 $CCDred::mkfringe";
  my ($status) = 0;
  my ($in, $illum);

  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $fhlog = new FileHandle ">>$logfile";
    print $fhlog "$epoch:\n";
    print $fhlog "COMPUTING FRINGE IMAGES\n";
    $fhlog->close;
  }
  ($in,$illum) = split /\+/,$inType;
  $command .= " --in=$in --out=$outType --illum=$illum --param=$illumFile";
  if (defined $logfile) {
    $command .= " --log=$logfile";
  }
  if ($isDef & 1 << $INSTRUMENT) {	#if defined instrument
    $command .= " --inst=$$instRef{'instrument'}";
  }
  if ((system $command) != 0) {
    print "\n*** Error while computing fringe images\n";
    $status=1;
    if ($isDef & 1 << $LOGFILE) {	#if defined logfile
      Iraf::printlog($logfile,
      		     "\tERROR: Error while computing fringe images\n");
    }
  }

  return($status);
}

#------------------------\
#        MkIllum          \
#--------------------------\

sub mkIllum {
  my ($isDef,$instRef,$logfile,$epoch,$inType,$outType) = @_;
  my ($illumFile) = $$instRef{'directory'}.$$instRef{'site'}.'/'.$$instRef{'instrument'}.".illum";
  my ($command) = "nice -19 $CCDred::mkillum";
  my ($status) = 0;

  if ($isDef & 1 << $LOGFILE) {		# if defined logfile
    Iraf::printlog($logfile,"$epoch:\nCOMPUTING ILLUMINATION IMAGES\n");
  }
  $command .= " --in=$inType --out=$outType --param=$illumFile";
  if ($isDef & 1 << $LOGFILE) {		#if defined logfile
    $command .= " --log=$logfile";
  }
  if ((system $command) != 0) {
    print "\n*** Error while computing illumination images\n";
    $status=1;
    if (defined $logfile) {
      Iraf::printlog($logfile,
                     "\tERROR: Error while computing illumination images\n");
    }
  }

  return($status);
}

#-------------------------\
#       ReadVerify         \
#---------------------------\
sub readVerify {
  my ($file) = @_;
  my (%dBase);
  my ($fhrd,$elements,$imgName,$dirName,$suffix);

  $fhrd = new FileHandle "<$file";
  while (<$fhrd>) {
    s/\n//;
    (@elements) = split /\s+/;
    next if ($#elements != 2);
    ($imgName,$dirName,$suffix) = fileparse($elements[0],$imtype);
    $imgName .= $suffix;
    $dBase{$dirName}->{$imgName} = $elements[2];
  }
  close($fhrd);

  return(%dBase);
}



#-------------------------\
#        TestFlags         \
#---------------------------\
sub testFlags {
  my ($isDef,$logfile,$look,$refFlag,$calibType) = @_;
  my ($shiftSize,$i,$code,$nbit);
  my ($activate,$desactivate) = (0,0);
  my ($testFlag) = 0;

  $userFlag = $$refFlag;
  SWITCH: {
    if (lc ($calibType) eq 'zero') {$shiftSize=4; $nbit=2; last SWITCH;}
    if (lc ($calibType) eq 'dark') {$shiftSize=6; $nbit=2; last SWITCH;}
    if (lc ($calibType) eq 'flat') {$shiftSize=8; $nbit=2; last SWITCH;}
    if (lc ($calibType) eq 'sky')  {$shiftSize=13; $nbit=1; last SWITCH;}
    if (lc ($calibType) eq 'illum'){$shiftSize=14; $nbit=2; last SWITCH;}
    if (lc ($calibType) eq 'fringe'){$shiftSize=16;$nbit=2; last SWITCH;}
    if (lc ($calibType) eq 'dc')   {$shiftSize=19; $nbit=1; last SWITCH;}
  }

  for ($i=0;$i<$nbit;$i++) {
    if ($userFlag & (1 << ($shiftSize + $i))) { $testFlag |= 1 << $i};
  }

  unless ($testFlag == $look) {
    $comp = $testFlag & $look;
    unless ($comp == 1) {
      for ($i=0;$i<$nbit;$i++) {
        if ($look & (1 << $i)) {
           unless ($testFlag & (1 << $i) or $i==1) {
             $$refFlag |= 1 << ($shiftSize + $i);   #activate
             $activate |= 1 << $i;
             print "$i $activate\n";
           }
         }
         elsif ($testFlag & (1 << $i)) {
           $$refFlag ^= 1 << ($shiftSize + $i);
           $desactivate |= 1 << $i;                     #desactivate
         }
      }
    }
  }

  #Warning messages
  SWITCH: {
    if ($activate & 1) {$code='warn "Raw ".lc($calibType)." found. Activate combine\n"';
                              last SWITCH;}
    if ($activate & 2) {die "Error : Not allowed to activate ".lc($calibType)." correction\n";
                              last SWITCH;}
    if ($desactivate & 2) {$code='warn "Missing ".lc($calibType)."s, raw or combined.  Desactivate combine and correction\n"';
                              last SWITCH;}
    if ($desactivate & 1) {$code='warn "Missing raw ".lc($calibType).".  Desactivate combine.\n"';
                              last SWITCH;}
    if (($desactivate & 1) && ($look & 2)) {$code='warn "$calibType images were found. Desactivate combine\n"';
                              last SWITCH;}
  }

  eval "$code" if (defined $code);
  if (($isDef & 1 << $LOGFILE) && (defined $code)) {
    $code =~ s/warn /print \$fhlog /;
    $fhlog = new FileHandle ">>$logfile";
    eval "$code";
    $fhlog->close;
  }
  
  return();
}


####### Routines called by align ########


#-------------------------\
#        Convolve          \
#---------------------------\
sub convolve {
 my ($isDef,$allParamRef,$refImage, @images) = @_;
 my ($command);

 $command = "$Image::gauss";
 if ( not grep {/^$refImage$/} @images ) { #ref not part of the list
   $command .= " $refImage";
 }
 $command .= " @images -o $CONV_PREFIX --sigma=$$allParamRef{'csigma'}";
 if ($isDef & 1 << $VERBOSE) { $command .= " -v"; }
 if ($isDef & 1 << $LOGFILE) { $command .= " --log=$$allParamRef{'log'}"; }
 if ($isDef & 1 << $DEBUG) { print "$command\n"; }
 system ("$command");

 return;
}

#-------------------------\
#         FitGSurf         \
#---------------------------\
sub fitGSurf {
 my ($flag,$isDef,$allParamRef,$refImage,@images) = @_;
 my ($image,$regfile,$outfile);
 my ($name,$path,$suffix,$status);

 #prepend appropriate prefix
 if (($flag & $CONVOLVE) and ($CONV_PREFIX ne "")) {
   ($name,$path,$suffix) = fileparse($refImage,$imtype);
   $refImage = "$path/$CONV_PREFIX$name$suffix";
   $refImage =~ tr/\///s;
   foreach $image (@images) {
     ($name,$path,$suffix) = fileparse($image,$imtype);
     $image = "$path/$CONV_PREFIX$name$suffix";
     $image =~ tr/\///s;
   }
 }
 if (($flag & $REGISTER) and ($REG_PREFIX ne "")) {
   ($name,$path,$suffix) = fileparse($refImage,$imtype);
   $refImage = "$path/$CONV_PREFIX$name$suffix";
   $refImage =~ tr/\///s;
   foreach $image (@images) {
     ($name,$path,$suffix) = fileparse($image,$imtype);
     $image = "$path/$CONV_PREFIX$name$suffix";
     $image =~ tr/\///s;
   }
 }


 if ($isDef & 1 << $LOGFILE) {
    $fhlog = new FileHandle ">> $$allParamRef{'log'}" or
    			die "ERROR: Unable to open $$allParamRef{'log'} for writing.\n";
 }
 if ($isDef & 1 << $VERBOSE) { print "\n"; }
 foreach $image (@images) {
   next if ($image eq $refImage);
   ($name,$path,$suffix) = fileparse($image,$imtype);
   $regfile = "$path/$REG_PREFIX$name$REG_SUFFIX";
   $outfile = "$path/$name$FIT_EXT";
   if (not -e $regfile) {	# if had to abort. this fix needed to continue */
   	$regfile = "$path/$CONV_PREFIX$REG_PREFIX$name$REG_SUFFIX";
	$outfile = "$path/$CONV_PREFIX$name$FIT_EXT";
	if (not -e $regfile) { 
		die "ERROR: File not found ($regfile)\n";
	}
   }
   $regfile =~ tr/\///s;
   $outfile =~ tr/\///s;
   if ($isDef & 1 << $VERBOSE) { print "\t$regfile: Output to $outfile ... "; }
   if ($isDef & 1 << $LOGFILE) {
      print $fhlog "$regfile: Output to $outfile\n";
   }
   
   $options='';
   if (defined $$allParamRef{'fwhm'}) { $options .= " --fwhm=$$allParamRef{'fwhm'}"; }
   
   $status = system ("$fitgsurf $regfile $options > $outfile");

   $status >>= 8;
   if ($status == $NO_CONVERGENCE) {
      warn "ERROR: Fit for $regfile did not converged.\n";
      if ($isDef & 1 << $LOGFILE) {
         print $fhlog "\tERROR: Fit for did not converged.\n";
      }
      system("echo '#$NO_CONVERGENCE' > $outfile");
   } elsif ($status == $FILE_NOT_FOUND) {
      warn "ERROR: File not found ($regfile)\n";
      if ($isDef & 1 << $LOGFILE) {
         print $fhlog "\tERROR: File not found ($regfile).\n";
      }
      system("echo '#$FILE_NOT_FOUND' > $outfile");
   } else {
      if ($isDef & 1 << $VERBOSE) { print "done\n"; }
   }
 }
 if ($isDef & 1 << $LOGFILE) { $fhlog->close; }

 return;
}


#-------------------------\
#        Register          \
#---------------------------\
sub register {
 my ($flag,$isDef,$allParamRef,$refImage,@images) = @_;
 my ($command,$options,$i,$output);
 my ($raRef,$decRef);
 my (@raList) = ();
 my (@decList) = ();
 my (@guessX) = ();
 my (@guessY) = ();
 my (@tmplist) = ();

 if ($$allParamRef{'header'}) {
    #Get RA and Dec
    @raList = Iraf::getkeyval($$allParamRef{'align.ra'},'string',$refImage,@images);
    $raRef = shift @raList;
    @decList = Iraf::getkeyval($$allParamRef{'align.dec'},'string',$refImage,@images);
    $decRef = shift @decList;

    #Estimate shifts
    for ($i=0; $i<=$#images; $i++) {
      ($guessX[$i],$guessY[$i]) = Iraf::arcSep($raRef,$decRef,$raList[$i],$decList[$i]);
      $guessX[$i] = int ($SIGN_RA*$guessX[$i] / $$allParamRef{'align.scale'});
      $guessY[$i] = int ($SIGN_DEC*$guessY[$i] / $$allParamRef{'align.scale'});
    }
 } else {
    #Coordinates from files
    push @tmplist, ($refImage, @images);
    foreach $_ (@tmplist) { 
    	s/(.*\/)?(?:$CONV_PREFIX)?(?:$CRPREFIX)?(.*?\.$imtype)$/$1$2/;
	s/\.$imtype$/.$GUESS_SUFFIX/;
    }
    @lines = Util::getLines(@tmplist);
    ($raRef,$decRef,@junk) = split /\s+/, shift @lines;
    for ($i=0; $i<=$#images; $i++) {
      ($x,$y,@junk) = split /\s+/, $lines[$i];
      $guessX[$i] = -1 * int ($x - $raRef);
      $guessY[$i] = -1 * int ($y - $decRef);
    }
 }

 #If convolution flag is on, prepend $CONV_PREFIX to all images
 if (($flag & $CONVOLVE) and ($CONV_PREFIX ne "")) {
   ($name,$path,$suffix) = fileparse($refImage,$imtype);
   $refImage = "$path/$CONV_PREFIX$name$suffix";
   $refImage =~ tr/\///s;
   foreach $image (@images) {
     ($name,$path,$suffix) = fileparse($image,$imtype);
     $image = "$path/$CONV_PREFIX$name$suffix";
     $image =~ tr/\///s;
   }
 }

 $options = '';
 if ($REG_PREFIX ne '') {$options .= " -o $REG_PREFIX";}
 $options .= " --box=$REG_BOX --section='$$allParamRef{'rsection'}' --cut=$$allParamRef{'REG_CUT'}";
 if ($isDef & 1 << $VERBOSE) { print "\n\tReference image: $refImage\n"; }
 if ($isDef & 1 << $LOGFILE) {
    $fhlog = new FileHandle ">> $$allParamRef{'log'}" or 
    			die "ERROR: Unable to open $$allParamRef{'log'} for writing.\n";
 }

 $status=0;
 for ($i=0; $i<=$#images; $i++) { 
   next if ($images[$i] eq $refImage);
   if ($isDef & 1 << $LOGFILE) {
     print $fhlog "$images[$i]: Shift first guess ($guessX[$i],$guessY[$i])\n";
   }
   if ($isDef & 1 << $VERBOSE) { print "\n$images[$i]: ($guessX[$i],$guessY[$i])"; }
   $options .= " --init='$guessX[$i],$guessY[$i]'";
   if ($isDef & 1 << $DEBUG) { print "\n$easyreg $refImage $images[$i] $options\n"; }
   $status = system("$easyreg $refImage $images[$i] $options");
   if ($isDef & 1 << $VERBOSE) { print "\n"; }
   if ($status) {
     if ($isDef & 1 << $LOGFILE) {
       print $fhlog "\tERROR: Error while registering the image.\n";
     }
     #reset status and delete the image from the list.  That way it
     # the code won't try to continue working on it (fit and shift).
     # THE DELETION IS DONE IN MAIN SINCE @IMAGES IS LOCAL AND I WANT
     # TO CHANGE THE MASTER LIST.  @sufferedError is global.
     $status=0;	# reset status
     push @sufferedError, $i;
   }
 }

 if ($isDef & 1 << $LOGFILE) { $fhlog->close; }
 
 return;
}


#-------------------------\
#     SeparateImages       \
#---------------------------\
sub separateImages {
 my ($isDef,$allParamRef,$ref2Groups,@images) = @_;
 my (@obstypes)=();
 my (@objects)=();
 my (@filters)=();
 my (@obstypeSelect,@objectSelect,@filterSelect);
 my ($ccdlist) = $CCDred::ccdlist;

 if (defined $$allParamRef{'obstype'}) {
    if ($$allParamRef{'obstype'} eq '1') {
       #find all observation type
	@obstypes = Iraf::findAll($$allParamRef{'align.obstype'},'string', 
	                          \@images);
    } else {
       #work only with this one
	push @obstypes, $$allParamRef{'obstype'};
    }
 } else {
    #don't care about observation type
    push @obstypes, 'all';
 }

 if (defined $$allParamRef{'object'}) {
    if ($$allParamRef{'object'} eq '1') {
       #find all the objects
       @objects = Iraf::findAll($$allParamRef{'align.object'},'string',\@images);
    } else { 
       #work only with this one
       push @objects, $$allParamRef{'object'};
    }
 } else {
    #don't care about which object's which
    push @objects, 'all';
 }

 if (defined $$allParamRef{'filter'}) {
    if ($$allParamRef{'filter'} eq '1') {
       #find all the filters
       @filters = Iraf::findAll($$allParamRef{'align.filter'},'string',\@images);
    } else {
       #work only with this one
       push @filters, $$allParamRef{'filter'};
    }
    #translate filter names
    &translateFilter($$allParamRef{'align.subsets'},\@filters);
 } else {
    #don't care about the filters
    push @filters, 'all';
 }

 foreach $obstype (@obstypes) {
   @obstypeSelect = ();
   if ($isDef & 1 << $DEBUG) {print "Observation type selection ($obstype) ... ";}
   if ($obstype ne 'all') {
      @obstypeSelect = 
      	    Images::selection($obstype,$$allParamRef{'align.obstype'},@images);
   } else {
      push @obstypeSelect, @images;
   }
   if ($isDef & 1 << $DEBUG) { print "done\n"; }

   foreach $object (@objects) {
     @objectSelect = ();
     if ($isDef & 1 << $DEBUG) { print "\tObject selection ($object) ... "; }
     if ($object ne 'all') {
        @objectSelect = 
	    Images::selection($object,$$allParamRef{'align.object'},@obstypeSelect);
     } else {
        push @objectSelect, @obstypeSelect;
     }
     if ($isDef & 1 << $DEBUG) { print "done\n"; }

     foreach $filter (@filters) {
	@filterSelect = ();
	if ($isDef & 1 << $DEBUG) { print "\t\tFilter selection ($filter) ... ";}
	if ($filter ne 'all') {
          @filterSelect = 
	    Images::selection($filter,$$allParamRef{'align.filter'},@objectSelect);
	} else {
          push @filterSelect, @objectSelect;
	}
	$groupName="$obstype+$object+$filter";
	if ($isDef & 1 << $DEBUG) { print "done  => '$groupName'\n"; }
	$$ref2Groups{$groupName} = [ @filterSelect ];
     }
   }
 }
 return;
}

#-------------------------\
#         Shift            \
#---------------------------\
sub shift {
 my ($isDef,$allParamRef,$refImage, @images) = @_;
 my ($image,$outputImage,$dx,$dy,$shiftFile);
 my ($fhrd,$junk,$options,@lines);
 my ($name,$path,$suffix);

 if ($isDef & 1 << $VERBOSE) { print "\n"; }

 $options = '';
 if ($isDef & 1 << $LOGFILE) { $options .= " --log=$$allParamRef{'log'}"; }

 ($name,$path,$suffix) = fileparse($refImage,$imtype);
 $name =~ s/^($REG_PREFIX)?($CONV_PREFIX)?//;
 $refImage = "$path/$name$suffix";
 $refImage =~ tr/\///s;

 if ($isDef & 1 << $LOGFILE) {
    $fhlog = new FileHandle ">> $$allParamRef{'log'}" or
    			die "ERROR: Unable to open $$allParamRef{'log'} for writing.\n";
 }
 foreach $image (@images) {
   ($name,$path,$suffix) = fileparse($image,$imtype);
   $shiftFile = "$path/";
   if (($flag & $CONVOLVE) and ($CONV_PREFIX ne "")) { $shiftFile .= $CONV_PREFIX; }
   if (($flag & $REGISTER) and ($REG_PREFIX ne "")) { $shiftFile .= $REG_PREFIX; }
   $shiftFile .= $name.$FIT_EXT;
   if (not -e $shiftFile) {  # if had to abort. This fix needed to continue.
   	$shiftFile = "$path/$CONV_PREFIX$name$FIT_EXT";
   }
   $shiftFile =~ tr/\///s;

   $name =~ s/^($REG_PREFIX)?($CONV_PREFIX)?//;  # Get rid of the reg and conv prefix
   $image = "$path/$name$suffix";	
   $image =~ tr/\///s;

   $name =~ s/^($CR_PREFIX)?//;	# Change prefix of output images.
   $outputImage = "$path/$outPrefix$name$suffix";
   $outputImage =~ tr/\///s;

   if ($#{main::images}+1 > 1) {
      if ($image eq $refImage) {	#make a new copy of refImage with shift prefix
         if ($isDef & 1 << $VERBOSE) { print "\tReference image. $refImage -> $outputImage\n"; }
	  if ($isDef & 1 << $LOGFILE) {
	    print $fhlog "Reference image. $refImage -> $outputImage\n";
	  }
         copy($refImage, $outputImage);
         ####
         next;
         ####
      }
      
   } else {
      $outputImage = $image;
   }
   
   $fhrd = new FileHandle "< $shiftFile" or 
   				die "Cannot open $shiftFile for reading.\n";
   @lines=<$fhrd>;
   $fhrd->close;
   if ($lines[0] !~ /^#($NO_CONVERGENCE|$FILE_NOT_FOUND)/) {
     ($dx,$junk) = split /\s+/, $lines[3];
     ($dy,$junk) = split /\s+/, $lines[4];
     $dx = Util::round($dx);
     $dy = Util::round($dy);

     if ($isDef & 1 << $LOGFILE) {
       print $fhlog "$image: ($dx,$dy) -> $outputImage\n";
     }
     if ($isDef & 1 << $VERBOSE) { print "\t"; }
     if ($isDef & 1 << $DEBUG) { 
       print "$shimg $image -o $outputImage $dx $dy $options\n";
     }
     system ("$shimg $image -o $outputImage $dx $dy $options");
     if ($isDef & 1 << $VERBOSE) { print "\tdone\n"; }
   }
 }
 if ($isDef & 1 << $LOGFILE) { $fhlog->close; }

 return;
}


#-------------------------\
#     TranslateFilter      \
#---------------------------\
sub translateFilter {
 my ($subsetFile,$ref2Filters) = @_;
 my (@lines,$line,$f,$expr);

 @lines = Util::getLines($subsetFile);

 foreach $f (@{ $ref2Filters }) {
   $expr="$f";
   foreach $line (@lines) {
     $line =~ /'(.+)'\s+(.+)/;
     if (lc($f) eq lc($2)) {
       $expr .= "||$1";
     }
   }
   $f=$expr;
 }
 return;
}




1;
