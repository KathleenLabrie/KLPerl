#!/usr/local/bin/perl -w
#
#Package: Iraf::CCDred
#Name: align
#Version: 1.1.2
#	Align a set of images.
#
#	Uses C-programs 'easyreg', 'fitgsurf' and 'shimg'.  Also
#	uses IRAF's 'gauss'.
#
# Usage: align.pl images [-o root] [image selection] [options]
#        align.pl -l listOfImages [-o root] [image selection] [options]
#        align.pl reducDir [-o root] [directory restrictions] [image selection] 
#										[options]
#
#	-o root	: If only one input image, name of output image
#			  if multiple input images, prefix of the output images
#			  [Default: overwrites input images]
#	images		: Input images.  First image taken as reference and all
#			  images aligned to it unless overruled by 
#			  'image selection' tags.
#	-l listOfImages: file with a list of images. see 'images'.
#	reducDir	: Root directory of the 'obj/e??????/image'.
#
#    Directory Restrictions:
#	-lr runList	: Name of the file containing the list of runs/objects.
#	-ln nightList : Name of the file containing the list of nights, i.e.
#			  their "eYYMMDD" identification
#	-r run		: ID of the run/objects.
#	-n night	: ID of the night.
#
#    Image Selection:
#	--obstype	  : Align all images, but segregate in obs. type subsets.
#	--obstype=obstype: Align this obs. type images.
#	--object        : Align all images, but segregate in object subsets
#	--object=object : Align this object images.
#	--filter        : Align all images, but segregate in filter subsets
#	--filter=filter : Align images with this filter.
#	--ref           : Interactive selection of the reference image(s).
#	--ref=refImg    : Designed reference image.
#	--param=file    : Name of the file containing useful information like
#			     header definitions, convolution parameters, etc.
#
#	--header        : Use header information for first guess (default)
#	--file          : Use files containing the coordinates of a common 
#				feature instead. (suffix should be 'algn')
#
#    Options:
#	If none of the following 4 switches are toggled, will do all.
#	--convolve	: Convolve the images to increase signal.
#	--register	: Create a registration map.
#	--findshift	: Find the shift by fitting the registration map.
#	--shift	: Shift the images.
#
#	--inst=instrument : Name of the instrument (help to find parameters)
#	--log=logfile     : Name of the logfile
#
# Needs:
#   %%%KLimgutil%%%
#   %%%immatch%%%
#   %%%fit%%%
#   %%%Iraf::Images%%%
#
#   %%%/astro/labrie/progc/img/align/easyreg%%%
#   %%%/astro/labrie/progc/img/util/shimg%%%
#   %%%/astro/labrie/progc/fit/fitgsurf%%%
#   %%%/astro/labrie/progp/iraf/imfilter/gauss.pl%%%
#   %%%/astro/labrie/progp/iraf/images/hselect.pl%%%
#   %%%/astro/labrie/progc/img/fits/getkeyval%%%

use Env qw(HOME);
use File::Basename;	# fileparse()
use FileHandle;	# $fh files
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;

############
$| = 1;
############

$DEBUG = 0;
$VERBOSE = 0;
#$CLOBBER = 0;

#Definitions
$CONVOLVE = $CCDred::CONVOLVE;		#1 << 0
$REGISTER = $CCDred::REGISTER;		#1 << 1
$FINDSHIFT = $CCDred::FINDSHIFT;	#1 << 2
$SHIFT = $CCDred::SHIFT;		#1 << 3
$CLEAN = $CCDred::CLEAN;		#1 << 4

$imtype = $CCDred::imtype;
$CONV_PREFIX = $CCDred::CONV_PREFIX;

#Error codes
$FILE_NOT_FOUND = $CCDred::$FILE_NOT_FOUND;
$NO_CONVERGENCE = $CCDred::$NO_CONVERGENCE;

#Set defaults
$status = 0;
$flag = 0;
$isDef=0;
$runs=();
$images=();
$setFile="$HOME/iraf/privuparm/setinst.par";
$param{'param'}=$CCDred::$DEFAULT_PARAM_FILE;
$param{'rsection'}=$CCDred::REG_SECTION;

#Read command line
while ($_ = shift @ARGV) {
  if ( /^--/ ) {
    s/^--//;
    SWITCH: {
      if (/^convolve$/)	{$flag |= 1 <<0; last SWITCH;}
      if (/^register$/)	{$flag |= 1 <<1; last SWITCH;}
      if (/^findshift$/)	{$flag |= 1 <<2; last SWITCH;}
      if (/^shift$/)		{$flag |= 1 <<3; last SWITCH;}
      if (/^clean$/)		{$flag |= 1 <<4; last SWITCH;}
      $acceptedSwitches = '^obstype|^object|^filter|^ref|^param|^inst'.
      			     '|^log|^debug|^header|^file|^rsection|^fwhm'.
			     '|^csigma|^rcut|^verbose';
      if (/$acceptedSwitches/) {
        if (/=/) {
	   ($key,$value) = split /=/;
	   $param{$key} = $value;
	 }
	 else { $param{$_} = 1; }
	 last SWITCH;
      }
      else  {die "ERROR: Unknown switch ($_)\n";}
    }
  }
  elsif ( /^-/ ) {
    s/^-//;
    SWITCH: {
      if (/^l$/)	{$listOfImages = shift @ARGV; last SWITCH;}
      if (/^o$/)	{$outPrefix = shift @ARGV; last SWITCH;}
      if (/^lr$/)	{$runList = shift @ARGV; last SWITCH;}
      if (/^ln$/)	{$nightList = shift @ARGV; last SWITCH;}
      if (/^r$/)	{push @runs, shift @ARGV; last SWITCH;}
      if (/^n$/)	{push @nights, shift @ARGV; last SWITCH;}
      if (/^v$/)	{$VERBOSE = 1; last SWITCH;}
      else 		{die "ERROR: Unknown switch ($_)\n";}
    }
  }
  else {
    push @otherArgv, $_;
  }
}

#DEBUG and VERBOSE toggle
if (defined $param{'debug'}) { $DEBUG = $param{'debug'}; }
if (defined $param{'verbose'}) { $DEBUG = $param{'verbose'}; }

# Set the isDef flag
if (defined $param{'inst'}) { $isDef |= 1 << $CCDred::INSTRUMENT; }
if (defined $param{'log'})  { $isDef |= 1 << $CCDred::LOGFILE; }
if ($DEBUG) 		    { $isDef |= 1 << $CCDred::DEBUG; }
if ($VERBOSE)		    { $isDef |= 1 << $CCDred::VERBOSE; }

# Modify defaults
if (not defined $param{'csigma'}) { $param{'csigma'} = $CCDred::CONV_SIGMA; }
if (not defined $param{'rcut'}) { $param{'rcut'} = $CCDred::REG_CUT; }

# Validate rsection
if ( (defined $param{'rsection'}) and 
     ( $param{'rsection'} !~ /^\[\d+\:\d+,\d+\:\d+\]$/ ) ) {
    die "ERROR: Invalid input (--rsection='[mmm:nnn,ppp:qqq]')\n";
}

#Where to look for first guess
if ( (defined $param{'header'}) && (defined $param{'file'}) ) {
	die "ERROR: --header and --file are mutually exclusive.\n";
} elsif (defined $param{'file'}) {
	$param{'header'} = 0;	#Not header, but files
} else {
	$param{'header'} = 1;	#Use header
}

#Figure out what the user wants to do.
if ($flag == 0) {	#default -> all, from convolve to shift plus clean
	$flag = $CONVOLVE + $REGISTER + $FINDSHIFT + $SHIFT + $CLEAN;
}			#otherwise use his/her flags

#Parse @otherArgv
if ($#otherArgv+1 == 0) {		#should have a list of images then
	if (not defined $listOfImages) {die "ERROR: No input images.\n";}
}
else {
	@dir = grep {-d} @otherArgv;
	if ($#dir+1 > 1) {die "ERROR: Only one directory name please.\n";}
	if ($#dir+1 == 0) {		# all images
	  foreach $_ (@otherArgv) {
	    if (not -e $_) {
	    	warn "ERROR: Image not found. ($_)\n";
		$status=$FILE_NOT_FOUND;
           } else {
	    	push @images, $_;
	    }
	  }
	}
	if ($#dir+1 == 1) {
	  if ($#dir == $#otherArgv) {	#directory
	    $reducDir = $dir[0].'/';
	    $reducDir =~ tr/\///s;
	  } else {				#Mix of directory and images.
	    die "ERROR: Only directories or only images, not both.\n";
	  }
	}
}

#Read image list
if (defined $listOfImages) {
  $fhrd = new FileHandle "< $listOfImages" or
  			die "ERROR: Unable to open $listOfImages for reading.\n";
  while (<$fhrd>) {
    if (not -e $_) {
    	warn "ERROR: Image not found. ($_)\n";
	$status = $FILE_NOT_FOUND;
    } else {
    	push @images, $_;
    }
  }
  $fhrd->close;
}

if ($status != 0) { die "Error Code $status\n"; }

#Read parameter file
if (defined $param{'inst'}) { $setFile .= ".$param{'inst'}"; }
%inst = Iraf::getParam($setFile,':');
if ((defined $param{'inst'}) and ($param{'inst'} ne $inst{'instrument'})) {
	die "ERROR: Error in instrument ID.\n";
}
if ($param{'param'} eq $DEFAULT_PARAM_FILE) {	#hasn't been defined by user
  # First look in instdb
  if ((defined $param{'inst'}) and
      (-e "$inst{'directory'}/$inst{'site'}/$param{'inst'}.param")) {
    $param{'param'}="$inst{'directory'}/$inst{'site'}/$param{'inst'}.param";
  }
  else	{	# try the default file then
    if (not -e $param{'param'}) {
    	die "ERROR: Unable to find any parameter file.\n";
    }
  }
} 
else {		# else: it has been defined by user so use that one.
  if (not -e $param{'param'}) {
    #not found in current dir
    #try in inst dir then
    if ((defined $param{'inst'}) and 
        (not -e "$inst{'directory'}/$inst{'site'}/$param{'param'}")) {	
  		die "ERROR: Unable to find $param{'param'}.\n";
    } else {
      #found in inst dir.  add full path.
      $param{'param'}="$inst{'directory'}/$inst{'site'}/$param{'param'}";
    }
  }
}
# Ok, we've got our parameter file. Now read it.
%tmp = Iraf::getParam($param{'param'},'=');
foreach $key (keys %tmp) { $param{$key} = $tmp{$key}; }

# Confirm overwrite mode with the user
if (not defined $outPrefix) {
  if (defined $param{'align.output'}) { $outPrefix = $param{'align.output'}; }
  else {	#overwrite mode
    if ($flag & $SHIFT) {
      print "WARNING: Working in overwrite mode.\n";
      print "\tThe shifted images will overwrite the input images.\n";
      print "\tDo you really want to do that? (y/n) ";
      $answer = <stdin>;
      $answer =~ s/\n//;
      die "Existing.\n" if (lc($answer) ne 'y');
      print "Alright, you've been warned...\n\n";
    }
  }
}


# Write instrument info to logfile
if ((defined $param{'log'}) and (not -e $param{'log'})) {
  $message  = "-----------------------------------------------------\n";
  $message .= "Intrument directory : $inst{'directory'}\n";
  $message .= "Site                : $inst{'site'}\n";
  $message .= "Instrument          : $inst{'instrument'}\n";
  $message .= "-----------------------------------------------------\n\n";
  Iraf::printlog($param{'log'},$message);
}

#Get list of runs if in reducDir mode
if ((defined $reducDir) && (defined $runList)) {
  push @runs, Util::getListOf('-d','-l',$runList,$reducDir);
}
grep { $_ .= '/'; tr/\///s; } @runs;


#Get list of nights if in reducDir mode
if ((defined $reducDir) && (defined $nightList)) {
  push @nights, Util::getListOf('-d','-l',$nightList,$reducDir);
}
grep { $_ .= '/'; tr/\///s; } @nights;

if ( ($#runs+1 >= 1) and (defined $param{'log'}) ) {
    Iraf::printlog($param{'log'},"ALIGNMENT OF IMAGES IN: @runs\n");
}

#When in reducDir, get the complete list of images
if (defined $reducDir) {
  #Loop through the runs
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = Util::getListOf('-d','-p','e??????',$reducDir.$run);
    if (defined @nights) {
      foreach $avail (@nightAvail) {
      	  $avail =~/(e\d+)$/;
	  $epoch2Find = $1;
	  if (grep {/$epoch2Find/} @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    grep { $_ .= '/'; tr/\///s; } @epochs;

    #Loop through the epochs to get image names
    foreach $epoch (@epochs) {
      @newImages = Util::getListOf('-e','-p','*.fits',$epoch);
      foreach $image (@newImages) {  #reject files starting with 'conv' and 'sh'
        if ($image !~ /^conv|^sh/) { push @images, $image; }
      }
    }	#end epoch loop
  } #end run loop
}

#Separate images into subsets [groups => hash of arrays]
#	Keys are 'obstype+object+filter'
%groups = ();
CCDred::separateImages($isDef,\%param,\%groups,@images);

if (defined $param{'log'}) {
  Iraf::printlog($param{'log'},"\nALIGNMENT REFERENCE IMAGES:\n");
}

foreach $groupName (keys %groups) {	# define reference image
  print "'$groupName': ";
  if (defined $param{'ref'}) {
     if ($param{'ref'} eq '1') {
        #for each group, ask the user
        print "\n";
	 foreach $_ (@{ $groups{$groupName} }) { print "\t$_\n"; }
	 print "Which image should be used as reference for this group? ";
	 $refImage{$groupName} = <stdin>;
     } else {
        #use what the user specified
	 if ($param{'ref'} =~ /^(\.\/|\/)/) {	#must be full path
	    $refImage{$groupName} = $param{'ref'};
	 } else {		#relative path, add common path as prefix
	    #Only in reducDir mode
	    $prefix='';
	    if (defined $reducDir) { $prefix=$reducDir; }
	    if ($#runs+1 == 1) { 
	      $prefix .= $runs[0];
	      if ($#nights+1 == 1) {
	        $prefix .= $nights[0];
	      }
	    }
	    $refImage{$groupName} = $prefix.$param{'ref'};
	 }
     }
  } else {
     $refImage{$groupName} = $groups{$groupName}[0];
  }
  print "Reference is $refImage{$groupName}\n";
  if (defined $param{'log'}) {
    Iraf::printlog($param{'log'},
    		   "$groupName: Reference is $refImage{$groupName}\n");
  }
}

foreach $groupName (keys %groups) {
  #----------#
  # Convolve #
  #----------#
  if ($flag & $CONVOLVE) {
    if (defined $param{'log'}) {
      Iraf::printlog($param{'log'},"\nPRE-ALIGNMENT CONVOLUTION: $groupName\n");
    }

    if ($VERBOSE) { print "\nConvolving images in group $groupName ... \n";}
    CCDred::convolve($isDef,\%param,$refImage{$groupName},@{ $groups{$groupName} });
    if ($VERBOSE) { print "done\n"; }
  }

  #----------#
  # Register #
  #----------#
  if ($flag & $REGISTER) {
    if (defined $param{'log'}) {
      Iraf::printlog($param{'log'},"\nREGISTRATION OF IMAGES: $groupName\n");
    }

    @sufferedError=();
    if ($VERBOSE) { print "\nRegistering images in group $groupName ... ";}
    CCDred::register($flag,$isDef,\%param,$refImage{$groupName},@{ $groups{$groupName} });

    if ($VERBOSE) { print "done\n"; }
    foreach $i (@sufferedError) {		# stop working on these images.
      splice(@{ $groups{$groupName} }, $i, 1);
    }
  }
  
  #-----------------------#
  # Clean convolve images #
  #-----------------------#
  if (($flag & $CLEAN) && ($flag & $CONVOLVE)) {
    #Delete all conv* images corresponding to this group.
    if ($VERBOSE) { print "\nDeleting '$CONV_PREFIX*' images of group $groupName ... ";}
    @goners=();
    @cannot=();
    foreach $image (@{ $groups{$groupName} }) { 
      ($name,$path,$suf) = fileparse($image,$imtype);
      push @goners, "$path/$CONV_PREFIX$name$suf";
    }
    @cannot = grep {not unlink} @goners;
    if (@cannot) {
      warn "$0: could not unlink: \n";
      foreach $_ (@cannot) { warn "$_\n"; }
    }
    if ($VERBOSE) { print "done\n"; }
  }

  #------------#
  # Find shift #
  #------------#
  if ($flag & $FINDSHIFT) {
    if (defined $param{'log'}) {
      Iraf::printlog($param{'log'},"\nCALCULATION OF THE SHIFTS: $groupName\n");
    }

    if ($VERBOSE) { print "\nCalculating the shifts for group $groupName ... ";}
    CCDred::fitGSurf($flag,$isDef,\%param,$refImage{$groupName},
    		     @{ $groups{$groupName} });
    if ($VERBOSE) { print "done\n"; }
  }

  #-------#
  # Shift #
  #-------#
  if ($flag & $SHIFT) {
    if (defined $param{'log'}) {
      Iraf::printlog($param{'log'},"\nSHIFTING OF IMAGES: $groupName\n");
    }
    if ($VERBOSE) { print "\nShifting images in group $groupName ... ";}
    CCDred::shift($isDef,\%param,$refImage{$groupName}, @{ $groups{$groupName} });
    if ($VERBOSE) { print "done\n";}
  }
}

exit(0);
