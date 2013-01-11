#!/usr/local/bin/perl -w
#
#Package:: Iraf::CCDred
#Name: reduc
#Version: 2.9.2
#
#Data reduction pipeline.  Night by night.
#
#Command-line arguments : reducRoot rawDataRoot -f imgList [--options]
#
#	reducRoot	: Location of the reduced data (root).
#	rawDataRoot	: Location of the raw data (root).
#	-calib calibDir : Location of calibration data (root) if a special
#				directory exists for those.
#	-lr runList	: Name of the file containing the list of runs.
#	-ln nightList	: Name of the file containing the list of nights, i.e.
#				their "eYYMMDD" identification
#	-r run		: ID of the run.
#	-n night	: ID of the night.
#	-f imgList	: Name of the file containing the list of raw images
#				(def: empty)
#	--{options}	: Options are:
#				slice
#				verification
#				copyover
#				overscan
#				trim
#				fixpix
#				movfixpix
#				zerocomb
#				zero
#				darkcomb
#				dark
#				flatcomb
#				flat
#				skycomb
#				mkillum
#				illum
#				mkfringe
#				fringe
#				dcsel
#				dc
#
#				cleanonly=Type1,Type2,TypeN
#
#	--{checks}	: Check controls are:
#				nolook		: don't look for calibration files
#				checkcam	: to use when different cam were used.
#						  (for oke data only)
#	--log=<logfile>
#	--inst=<instrument>
#	--flattype=<dome|sky>
#
#Needs :
#   %%%Iraf::CCDred%%%
#   %%%Iraf::Images%%%
#   %%%Cccdred%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdproc.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/zerocombine.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/darkcombine.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/flatcombine.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdlist.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/ccdhedit.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/mkillum.pl%%%
# %%%/astro/labrie/progp/iraf/ccdred/mkfringe.pl%%%
# %%%/astro/labrie/progp/iraf/general/verifyimg.pl%%%
# %%%/astro/labrie/progp/iraf/images/imreplace.pl%%%
# %%%/astro/labrie/progp/iraf/images/imslice.pl%%%
# %%%/astro/labrie/progc/img/ccdred/fixbadpix%%%

######## check which one of these are still used ####
use Cwd;		# cwd()
use File::Basename;	# basename()
use Env qw(HOME);
use lib qw(/home/labrie/prgp/include);
use Iraf::CCDred;
use Iraf::Images;

#Definitions
$VERIFICATION = $CCDred::VERIFICATION;	#1 << 0
$COPYOVER = $CCDred::COPYOVER;		#1 << 1
$OVERSCAN = $CCDred::OVERSCAN;		#1 << 2
$TRIM = $CCDred::TRIM;			#1 << 3
$ZEROCOMB = $CCDred::ZEROCOMB;		#1 << 4
$ZERO = $CCDred::ZERO;			#1 << 5
$DARKCOMB = $CCDred::DARKCOMB;		#1 << 6
$DARK = $CCDred::DARK;			#1 << 7
$FLATCOMB = $CCDred::FLATCOMB;		#1 << 8
$FLAT = $CCDred::FLAT;			#1 << 9
$FIXPIX = $CCDred::FIXPIX;		#1 << 10
$MOVFIXPIX = $CCDred::MOVFIXPIX;	#1 << 11
$SLICE = $CCDred::SLICE;		#1 << 12
$SKYCOMB = $CCDred::SKYCOMB;		#1 << 13
$MKILLUM = $CCDred::MKILLUM;		#1 << 14
$ILLUM = $CCDred::ILLUM;		#1 << 15
$MKFRINGE = $CCDred::MKFRINGE;		#1 << 16
$FRINGE = $CCDred::FRINGE;		#1 << 17
$DCSEL = $CCDred::DCSEL;		#1 << 18
$DC = $CCDred::DC;			#1 << 19

$| = 1;
#Set defaults
$flag = 0;
$look = 1;
$cleanOnly = 0;
$checkcam = 0;
$imgList = '';
$verifyImg = $CCDred::verifyimg;
$imslice = $Images::imslice;
$setFile="$HOME/iraf/privuparm/setinst.par";
$calibDir="";
$junk='';
$runs=();
$nights=();
$flattype="";

#Read-in command-line arguments
while ($_ = shift @ARGV) {
  if ( /^--/ ) {
    s/^--//;
    SWITCH: {
      if (/^flattype/)		{($junk,$tmp) = split /=/;
      				 $flattype = ucfirst $tmp;
				 last SWITCH;
      				}

      if (/^ver/)		{$flag |= 1 << 0; last SWITCH;}
      if (/^copy/)		{$flag |= 1 << 1; last SWITCH;}
      if (/^over/)		{$flag |= 1 << 2; last SWITCH;}
      if (/^trim/)		{$flag |= 1 << 3; last SWITCH;}
      if (/^zeroc/)		{$flag |= 1 << 4; last SWITCH;}
      if (/^zero/)		{$flag |= 1 << 5; last SWITCH;}
      if (/^darkc/)		{$flag |= 1 << 6; last SWITCH;}
      if (/^dark/)		{$flag |= 1 << 7; last SWITCH;}
      if (/^flatc/)		{$flag |= 1 << 8; last SWITCH;}
      if (/^flat/)		{$flag |= 1 << 9; last SWITCH;}
      if (/^fix/)		{$flag |= 1 << 10; last SWITCH;}
      if (/^movfix/)		{$flag |= 1 << 11; last SWITCH;}
      if (/^slice/)		{$flag |= 1 << 12; last SWITCH;}
      if (/^skycomb/)	{$flag |= 1 << 13; last SWITCH;}
      if (/^mkillum/)	{$flag |= 1 << 14; last SWITCH;}
      if (/^illum/)		{$flag |= 1 << 15; last SWITCH;}
      if (/^mkfringe/)	{$flag |= 1 << 16; last SWITCH;}
      if (/^fringe/)		{$flag |= 1 << 17; last SWITCH;}
      if (/^dcsel/)		{$flag |= 1 << 18; last SWITCH;}
      if (/^dc/)		{$flag |= 1 << 19; last SWITCH;}
      if (/^nolook/)		{$look = 0; last SWITCH;}
      if (/^checkcam/)		{$checkcam = 1; last SWITCH;}
      if (/^log/)		{($junk,$logfile) = split /=/;
      				 $cwd=cwd();
				 $logfile = join '/',$cwd,basename($logfile,'');
				 last SWITCH;}
      if (/^inst/)		{($junk,$instrument) = split /=/;
      				 $setFile .= ".$instrument";
				 last SWITCH;}
      if (/^clean/)		{$cleanOnly = 1;
      				 ($junk,$types) = split /=/;
				 @types = split /,/, $types;
      				}
    }
  }
  elsif ( /^-/ ) {
    s/^-//;
    SWITCH: {
      if (/^calib/)	{$calibDir = (shift @ARGV).'/'; 
      			 $calibDir =~ s/\/\//\//; last SWITCH;}
      if (/^lr/)	{$runList = shift @ARGV; last SWITCH;}
      if (/^ln/)	{$nightList = shift @ARGV; last SWITCH;}
      if (/^r/)	{push @runs, shift @ARGV; last SWITCH;}
      if (/^n/)	{push @nights, shift @ARGV; last SWITCH;}
      if (/^f/)	{$imgList = shift @ARGV; last SWITCH;}
    }
  }
  else {
    push @otherArgv, $_;
  }
}

#Parse @otherArgv
$reducRoot = (shift @otherArgv).'/';
$rawDataRoot = (shift @otherArgv).'/';
$reducRoot =~ s/\/\//\//;
$rawDataRoot =~ s/\/\//\//;

#Set isDef flag
if (defined $instrument) { $isDef |= 1 << $CCDred::INSTRUMENT; }
if (defined $logfile)    { $isDef |= 1 << $CCDred::LOGFILE; }
if ($checkcam)           { $isDef |= 1 << $CCDred::CHECKCAM; }

#Get list of runs
if (defined $runList) {
  push @runs, Util::getListOf('-d','-l',$runList,$reducRoot);
}

#Get list of nights
if (defined $nightList) {
  push @nights, Util::getListOf('-d','-l',$nightList,$reducRoot);
}

#Define instrument
%inst = Iraf::getParam($setFile,':');
if (defined $instrument) {
  die "ERROR: Error in instrument ID.\n" if ($instrument ne $inst{'instrument'});
}
if ((defined $logfile) && (!(-e $logfile))) {
  $message  = "-----------------------------------------------------\n";
  $message .= "Intrument directory : $inst{'directory'}\n";
  $message .= "Site                : $inst{'site'}\n";
  $message .= "Instrument          : $inst{'instrument'}\n";
  $message .= "-----------------------------------------------------\n\n";
  Iraf::printlog($logfile,$message);
}

#Fix the format of the runs
foreach $run (@runs) {
  $run =~ s/(\/)+/\//g;
  unless ($run =~ /\/$/) {$run .= '/';}
}

if ($flag & ($SLICE + $VERIFICATION + $COPYOVER)) {
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = Util::getListOf('-d','-p','e*',$reducRoot.$run);
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)$/;
        $epoch2Find = $1;
	 if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    } 
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      unless ($epoch =~ /\/$/) {$epoch .= '/';}
      print "\n$epoch\n";
      
      if ($flag & $SLICE) {
        if (defined $logfile) {
	   Iraf::printlog($logfile,"$epoch: Extraction of data cube.\n");
	 }
	 $options = "--dim=3 --update --dir=$rawDataRoot/ --log=$logfile";
        system ("$imslice -l $epoch$imgList $options");
      }
      
      if ($flag & ($VERIFICATION + $COPYOVER)) {
      	 @rawImages = Util::getListOf('-f','-l',$imgList,$epoch);
	 foreach $image (@rawImages) {$image = $rawDataRoot.$image;}
	 if ($flag & $VERIFICATION) {
          print "Start verification...\n";
	   if (defined $logfile) {
	     Iraf::printlog($logfile,"$epoch: Verification of images.\n");
	   }
	    #Verification of images :
           #      - Is the ID ok?
           #      - Is the imtype ok?
           #      - Is the subset ok?
	    #	  - need to fix bad pixels?
	    #		- fixed pattern?
	    #		- moving pattern?
           #      - need overscan subtraction?
           #      - need trimming?
           #      - need bias subtraction?
           #      - need dark subtraction?
           #      - need flat field correction?
	   system ("$verifyImg @rawImages --inst=$inst{'instrument'}");
	 }

	 if ($flag & $COPYOVER) {
	   #Copy images over and fix the verification file
	   if (defined $logfile) {
	      Iraf::printlog($logfile,"$epoch: Copy raw images\n");
	      CCDred::copyOver($isDef,$logfile,'verify.out',$epoch,@rawImages);
	   } else {
	      CCDred::copyOver($isDef,'0','verify.out',$epoch,@rawImages);
	   }
	 }
      }
    }
  }
}

#Get CCDSEC-DATASEC/TRIMSEC
($ccdsec,$trimsec) = CCDred::getSection($setFile);

if (($flag & ($OVERSCAN + $TRIM + $FIXPIX + $MOVFIXPIX + $ZEROCOMB + $ZERO + 
		$DARKCOMB + $DARK + $FLATCOMB + $FLAT)) || $cleanOnly) {
  $origFlag = $flag;
  $datasec=CCDred::dataSecAfterTrim($ccdsec,$trimsec);
  (-e 'verify.out') ? %imDB = CCDred::readVerify('verify.out') :
				die "Images have not been verified\n";
  $origDir=cwd();
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = ();
    @nightAvail = grep /$run/, keys %imDB;
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)\/$/;
        $epoch2Find = $1;
	 if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      $flag = $origFlag;	#Reset 'flag'
      unless ($epoch =~ /\/$/) {$epoch .= '/';}
      chdir ($epoch);
      print "\n$epoch\n";

      if ($cleanOnly) {
        foreach $type (@types) {
	  if (defined $logfile) { 
	  	CCDred::cleanDir($isDef,$logfile,$type,$calibDir,$epoch);
	  }
	  else { CCDred::cleanDir($isDef,'0',$type,$calibDir,$epoch); }
	}
	exit(0);
      }
      
      #---------------------#
      # Overscan correction #
      #---------------------#
      if ($flag & $OVERSCAN) {
        $tmpDatasec=$datasec;
        $datasec=$ccdsec;
	if (defined $logfile) {
	  CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'Overscan',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'Overscan',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
	$datasec=$tmpDatasec;
      }
      
      #------#
      # Trim #
      #------#
      if ($flag & $TRIM) {
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'Trim',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'Trim',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
      }
      

      #----------------------#
      # Bad pixel correction #
      #----------------------#
      if ($logfile && ($flag & ($FIXPIX + $MOVFIXPIX)) && ($look)) {
        Iraf::printlog($logfile,"\n$epoch: LOOK FOR CALIB MASK\n");
      }

      if (($flag & $FIXPIX) && ($look)) {
        #Look for masks
	 # All found : 2
	 # Could not find them all : 0
	 print "\nLooking for fixed bad pixel masks\n";
	 if (defined $logfile) {
	    $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 				'Mask',$imgList,$imDB{$epoch},$epoch,$calibDir);
	 } else {
	    $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 				'Mask',$imgList,$imDB{$epoch},$epoch,$calibDir);
	 }
	 if (!$lookFlag) {die ("'Mask' files required could not be found\n");}
      }

      $epoch =~ /\/\w(\d+)\/$/;
      if (!($checkcam) || ($1 > $CCDred::camBoundary831000)) {
	 if (($flag & $MOVFIXPIX) && ($look)) {
          #Look for masks
	   # All found : 2
	   # Could not find them all : 0
	   print "\nLooking for moving bad pixel masks\n";
	   if (defined $logfile) {
	      $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 			'MaskMove',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   } else {
	      $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 			'MaskMove',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   }
	   if (!$lookFlag) {die ("'MaskMove' files required could not be found\n");}

	   print "\nLooking for pattern files\n";
	   if (defined $logfile) {
	      $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 			'Pattern',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   } else {
	      $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 			'Pattern',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   }
	   if (!$lookFlag) {die ("'Pattern' files required could not be found\n");}
	 }
      }
      
      if ($flag & ($FIXPIX + $MOVFIXPIX)) {
        #Fix bad pixels
	if (defined $logfile) {
	   CCDred::goFixPix($isDef,$logfile,\%inst,$flag,$imDB{$epoch},$epoch);
	} else {
	   CCDred::goFixPix($isDef,'0',\%inst,$flag,$imDB{$epoch},$epoch);
	}
      }

      if ($flag & ($FIXPIX)) {
        #Delete masks from the epoch directory
        if (defined $logfile) { 
		CCDred::cleanDir($isDef,$logfile,'Mask',$calibDir,$epoch); 
	}
	else { CCDred::cleanDir($isDef,'0',$type,$calibDir,$epoch); }
      }
      if ($flag & ($MOVFIXPIX)) {
        #Delete masks from the epoch directory
	if (defined $logfile) { 
		CCDred::cleanDir($isDef,$logfile,'MaskMove',$calibDir,$epoch);
		CCDred::cleanDir($isDef,$logfile,'Pattern',$calibDir,$epoch); 
	} else { 
		CCDred::cleanDir($isDef,'0','MaskMove',$calibDir,$epoch);
		CCDred::cleanDir($isDef,'0','Pattern',$calibDir,$epoch);
	}
      }


      #-----------------#
      # Zero Correction #
      #-----------------#
      if ($flag & $ZERO) {
        #Edit header of 'dark','flat','object' and 'other' (standards) that
	 # have already been zero corrected.
	 if (defined $logfile) {
	    CCDred::editAlreadyCorrected($isDef,$logfile,\%inst,
	    				'Zero',$imDB{$epoch},$epoch);
	 } else {
	    CCDred::editAlreadyCorrected($isDef,'0',\%inst,
	    				'Zero',$imDB{$epoch},$epoch);
	 }
      }

      if ($logfile && ($flag & ($ZEROCOMB + $ZERO)) && ($look)) {
        Iraf::printlog($logfile,"\n$epoch: LOOK FOR CALIB ZERO\n");
      }

      if (($flag & ($ZEROCOMB + $ZERO)) && ($look)) {
        #Look for Zeros, in run/epoch dir and in calib dir (if the later exists)
	 # Zerocombine : 1 << 0;
	 # Zero correction : 1 << 1;
	 print "Looking for calibration images\n";
	 if (defined $logfile) {
	    $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 				'Zero',$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Zero');
	 } else {
	    $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 				'Zero',$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Zero');
	 }
      }

      if ($flag & $ZEROCOMB) {
        #Zerocombine
	 #Find 'zero' images, check that they have been pre-processed,
	 # then combine them.
	 if (defined $logfile) {
	    CCDred::combCalib($isDef,$logfile,\%inst,'Zero',$imgList,
	    		$imDB{$epoch},\$epoch);
	 } else {
	    CCDred::combCalib($isDef,'0',\%inst,'Zero',$imgList,
	    		$imDB{$epoch},\$epoch);
	 }
      }

      if ($flag & $ZERO) {
        #Zero
	 #Find all images needing zerocor, use 'Zero' images, check that
	 # the images have been pre-processed, then correct.
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'Zero',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'Zero',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
     }
      
      if ($flag & $ZERO) {
        #Delete zero from the epoch directory, BUT ...
	 #If the zero are new (have just been created) copy them to a calibration
	 # directory before removing them.
	 if (defined $logfile) { 
	 	CCDred::cleanDir($isDef,$logfile,'Zero',$calibDir,$epoch);
	 }
	 else { CCDred::cleanDir($isDef,'0','Zero',$calibDir,$epoch); }
      }

      #-----------------#
      # Dark Correction #
      #-----------------#      
      if ($flag & $DARK) {
        #Edit header of 'flat','object' and 'other' (standards) that have 
	 # already been dark corrected.
	 # have already been zero corrected.
	 if (defined $logfile) {
	    CCDred::editAlreadyCorrected($isDef,$logfile,\%inst,
	    				'Dark',$imDB{$epoch},$epoch);
	 } else {
	    CCDred::editAlreadyCorrected($isDef,'0',\%inst,
	    				'Dark',$imDB{$epoch},$epoch);
	 }
      }

      if ($logfile && ($flag & ($DARKCOMB + $DARK)) && ($look)) {
        Iraf::printlog($logfile,"\n$epoch: LOOK FOR CALIB DARK\n");
      }

      if (($flag & ($DARKCOMB + $DARK)) && ($look)) {
        #Look for Darks, in run/epoch dir and in calib dir if the later exists
	 # Darkcombine : 1 << 0;
	 # Dark correction : 1 << 1;
	 if (defined $logfile) {
    	    $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 				'Dark',$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Dark');
	 } else {
	    $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 				'Dark',$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Dark');
	 }
      }

      if ($flag & $DARKCOMB) {
        #Darkcombine
	 #Find 'dark' images, check that they have been pre-processed,
	 # then combine them.
	 if (defined $logfile) {
	    CCDred::combCalib($isDef,$logfile,\%inst,'Dark',$imgList,$imDB{$epoch},
	    				\$epoch);
	 } else {
	    CCDred::combCalib($isDef,'0',\%inst,'Dark',$imgList,$imDB{$epoch}, \$epoch);
	 }
      }

      if ($flag & $DARK) {
        #Dark
	 #Find all images needing darkcor, use 'Dark' images, check that
	 # the images have been pre-processed, then correct.
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst, $setFile,
	  		       'Dark',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,
	  		       'Dark',$imgList,$imDB{$epoch},$epoch, $setFile,
			       $datasec,$ccdsec);
	}
      }

      if ($flag & $DARK) {
        #Delete dark from the epoch directory, BUT ...
	 #If the dark are new (have just been created) copy them to a calibration
	 # directory before removing them.
	 if (defined $logfile) { 
	 	CCDred::cleanDir($isDef,$logfile,'Dark',$calibDir,$epoch);
	 }
	 else { CCDred::cleanDir($isDef,'0','Dark',$calibDir,$epoch); }
      }

      #-----------------#
      # Flat Correction #
      #-----------------#
      if ($flag & $FLAT) {
        #Edit header of 'object' and 'other' (standards) that have already
	 # been flat corrected.
	 if (defined $logfile) {
	    CCDred::editAlreadyCorrected($isDef,$logfile,\%inst,
	    				'Flat',$imDB{$epoch},$epoch);
	 } else {
	    CCDred::editAlreadyCorrected($isDef,'0',\%inst,
	    				'Flat',$imDB{$epoch},$epoch);
	 }
      }

      if ($logfile && ($flag & ($FLATCOMB + $FLAT)) && ($look)) {
        Iraf::printlog($logfile,"\n$epoch: LOOK FOR CALIB \U${flattype}\EFLAT\n");
      }

      if (($flag & ($FLATCOMB + $FLAT)) && ($look)) {
        #Look for Flats, in runs/epochs dir and in calib dir if the later exists
	 # Flatcombine : 1 << 0;
	 # Flat correction : 1 << 1;
	 if (defined $logfile) {
	    $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 		"${flattype}Flat",$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Flat');
	 } else {
	    $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 		"${flattype}Flat",$imgList,$imDB{$epoch},$epoch,$calibDir);
	    CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Flat');
	 }
      }

      if ($flag & $FLATCOMB) {
        #Flatcombine
	 #Find 'flat' images, check that they have been pre-processed,
	 # then combine them.
	 if (defined $logfile) {
	    CCDred::combCalib($isDef,$logfile,\%inst,"${flattype}Flat",
	    		$imgList,$imDB{$epoch},\$epoch);
	 } else {
	    CCDred::combCalib($isDef,'0',\%inst,"${flattype}Flat",
	    		$imgList,$imDB{$epoch},\$epoch);
	 }
      }

      if ($flag & $FLAT) {
        #Flat
	 #Find all images needing flatcor, use 'Flat' images, check that
	 # the images have been pre-processed, then correct.
	 $|=1;		#OUTPUT_AUTOFLUSH ON
	 print "Start flat correction.\n";
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       "${flattype}Flat",$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       "${flattype}Flat",$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
	 $|=0;		#OUTPUT_AUTOFLUSH OFF
      }
      
      if ($flag & $FLAT) {
        #Delete flat from the epoch directory, BUT ...
	 #If the flat are new (have just been created) copy them to a calibration
	 # directory before removing them.
	 if (defined $logfile) { 
	 	CCDred::cleanDir($isDef,$logfile,"${flattype}Flat",$calibDir,$epoch);
	 }
	 else { CCDred::cleanDir($isDef,'0',"${flattype}Flat",$calibDir,$epoch); }
      }
    }
  }
  chdir ($origDir);
}

if ($flag & $SKYCOMB) {
  $origFlag = $flag;
  $datasec=CCDred::dataSecAfterTrim($ccdsec,$trimsec);
  unless (defined %imDB) {
    (-e 'verify.out') ? %imDB = CCDred::readVerify('verify.out') :
  				die "Images have not been verified\n";
  }
  $origDir=cwd();
  # Get a list of all images (CombineSky will select the right ones from this list)
  @tmpepochs=();
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = ();
    @nightAvail = grep /$run/, keys %imDB;
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)\/$/;
	$epoch2Find = $1;
	if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      foreach $image (keys % { $imDB{$epoch} }) {
        $newkey=$epoch.$image;
        $skyDB{$newkey} = $imDB{$epoch}{$image};
      }
    }
    push @tmpepochs, @epochs
  }
  @epochs = @tmpepochs;

  #--------------------#
  # Combine Sky images #
  #--------------------#
  if ($logfile && ($look)) {
    Iraf::printlog($logfile,"\nLOOK FOR COMBINED SKY IMAGES\n");
  }

  if ($look) {
    #Look for combined sky images in 'calib' directory.  Dies if calib is not
    # defined.
    # Go for combine: 1 << 0;
    # Already combined: 1 << 1;
    print "\nLooking for combined sky images\n";
    if (defined $calibDir && -d $calibDir) {
      if (defined $logfile) {
	 $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 			     'Sky',$imgList,\%skyDB,$epoch,$calibDir);
	 CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Sky');
      } else {
	 $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 			     'Sky',$imgList,\%skyDB,$epoch,$calibDir);
	 CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Sky');
      }
    }
    else { die "ERROR: No valid calibration directory has been defined.\n"; }
  }
  
  if ($flag & $SKYCOMB) {	#flag might have changed after TestFlags
    # Combine sky images
    # Find sky images, make sure they have been pre-processed, then combine
    # them.  These tasks are actually performed by 'combine.pl'.
    if (defined $logfile) {
       CCDred::combCalib($isDef,$logfile,\%inst,'Sky',$imgList,\%skyDB,\$epochs);
    } else {
       CCDred::combCalib($isDef,'0',\%inst,'Sky',$imgList,\%skyDB,\$epochs);
    }
  }

  if ($flag & $SKYCOMB) {
    # New 'Sky' images has to be send to 'calibDir/epochs'
    @toclean=();
    foreach $epoch (@epochs) {
      $epoch =~ s/.*?(e\d+)\/?$/$1\//;
      next if (grep $epoch, @toclean);
      push @toclean, $epoch;
    }
    if (defined $logfile) { 
    	CCDred::cleanDir($isDef,$logfile,'Sky',$calibDir,@toclean);
    }
    else { CCDred::cleanDir($isDef,'0','Sky',$calibDir,@toclean); }
    undef @toclean;
  }

  chdir ($origDir);
}

if ($flag & ($MKILLUM + $ILLUM + $MKFRINGE + $FRINGE)) {
  $origFlag = $flag;
  $datasec = CCDred::dataSecAfterTrim($ccdsec, $trimsec);
  unless (defined %imDB) {
    (-e 'verify.out') ? %imDB = CCDred::readVerify('verify.out') :
    				die "Images have not been verified\n";
  }
  $origDir=cwd();
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = ();
    @nightAvail = grep /$run/, keys %imDB;
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)\/$/;
	 $epoch2Find = $1;
	 if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      $flag = $origFlag;	#Reset 'flag'
      unless ($epoch =~ /\/$/) {$epoch .= '/';}
      chdir ($epoch);
      print "\n$epoch\n";

      #-------------------------#
      # Illumination correction #
      #-------------------------#
      if ($logfile && ($flag & ($MKILLUM + $ILLUM)) && ($look)) {
        Iraf::printlog($logfile,"\nLOOK FOR ILLUMINATION IMAGES\n");
      }

      if (($flag & ($MKILLUM + $ILLUM)) && ($look)) {
	# Look for Illumination or Sky images in runs/epochs dir and in calib dir if
	# it has been defined.
	# Mkillum: 1 << 0;
	# Illum correction: 1 << 1;
	if (defined $logfile) {
	   $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 			   'Illum|Sky',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Illum');
	} else {
	   $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 			   'Illum|Sky',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Illum');
	}
      }

      if ($flag & $MKILLUM) {
        # Mkillum
	# Find 'Sky' images and apply boxcar.
	if (defined $logfile) {
	   $status=CCDred::mkIllum($isDef,\%inst,$logfile,$epoch,'Sky','Illum');
	} else {
	   $status=CCDred::mkIllum($isDef,\%inst,'0',$epoch,'Sky','Illum');
	}
	die if ($status);
      }
      
      if ($flag & $ILLUM) {
        # Illumination correction
	# Find all images needing illumcor, use 'Illum' images, check that
	# the images have been pre-processed, then correct.
	$| = 1;		#OUTPUT_AUTOFLUSH ON
	print "Start illumination correction.\n";
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'Illum',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'Illum',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
	$| = 0;		#OUTPUT_AUTOFLUSH OFF
      }

      if ($flag & ($MKILLUM + $ILLUM)) {
        # Delete Illum images from the epoch directory, BUT ...
	# If the Illum are new (have just been created) copy them to the
	# calibration directory before removing them.
	if (defined $logfile) { 
		CCDred::cleanDir($isDef,$logfile,'Illum',$calibDir,$epoch);
		CCDred::cleanDir($isDef,$logfile,'Sky',$calibDir,$epoch);
	} else { 
		CCDred::cleanDir($isDef,'0','Illum',$calibDir,$epoch);
		CCDred::cleanDir($isDef,'0','Sky',$calibDir,$epoch);
	}
      }

      #-------------------#
      # Fringe correction #
      #-------------------#
      if ($logfile && ($flag & ($MKFRINGE + $FRINGE)) && ($look)) {
        Iraf::printlog($logfile,"\nLOOK FOR FRINGE IMAGES\n");
      }

      if (($flag & ($MKFRINGE + $FRINGE)) && ($look)) {
        # Look for Fringe or Sky images in runs/epochs dir and in calibdir if it
	# has been defined.
	# Mkfringe: 1 << 0;
	# Fringe correction: 1 << 1;
	if (defined $logfile) {
	   $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 		'Fringe|Sky+Illum',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'Fringe');
	} else {
	   $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 		'Fringe|Sky+Illum',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'Fringe');
	}
      }

      if ($flag & $MKFRINGE) {
        # Mkfringe
	# Find 'SkyIllum' or 'Sky' and 'Illum' images to 'Sky' -> 'SkyIllum'
	# (Sky images corrected for Illum), then apply boxcar to obtain the 
	# fringe images.
	if (defined $logfile) {
	  $status = CCDred::mkFringe($isDef,\%inst,$logfile,$epoch,'Sky+Illum',
	  			    'Fringe');
	} else {
	  $status = CCDred::mkFringe($isDef,\%inst,'0',$epoch,'Sky+Illum',
	  			    'Fringe');
	}
	die if ($status);
      }

      if ($flag & $FRINGE) {
        # Fringe correction
	# Find all images needing fringecor, use 'Fringe' images, check that
	# the images have been pre-processed, then correct.
	$|=1;		#OUTPUT_AUTOFLUSH ON
	print "Start fringe correction.\n";
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'Fringe',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'Fringe',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
	$|=0;		#OUTPUT_AUTOFLUSH OFF
      }

      if ($flag & ($MKFRINGE + $FRINGE)) {
        # Delete Fringe images from the epoch directory, BUT...
	 # If the Fringe are new (have just been created) copy them to the
	 # calibration directory before removing them.
	 if (defined $logfile) { 
	 	CCDred::cleanDir($isDef,$logfile,'Fringe',$calibDir,$epoch);
	 	CCDred::cleanDir($isDef,$logfile,'Illum',$calibDir,$epoch);
	 	CCDred::cleanDir($isDef,$logfile,'Sky',$calibDir,$epoch);
	 } else { 
	 	CCDred::cleanDir($isDef,'0','Fringe',$calibDir,$epoch);
	 	CCDred::cleanDir($isDef,'0','Illum',$calibDir,$epoch);
	 	CCDred::cleanDir($isDef,'0','Sky',$calibDir,$epoch);
	 }
      }
    }
  }
  chdir ($origDir);
}

if ($flag & ($DCSEL)) {
  unless (defined %imDB) {
    (-e 'verify.out') ? %imDB = CCDred::readVerify('verify.out') :
    				die "Images have not been verified\n";
  }
  $origDir=cwd();
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = ();
    @nightAvail = grep /$run/, keys %imDB;
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)\/$/;
	 $epoch2Find = $1;
	 if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      unless ($epoch =~ /\/$/) { $epoch .= '/';}
      chdir ($epoch);
      print "\n$epoch\n";

      #-------------------------------------------#
      # Selection of sky images for DC correction #
      #-------------------------------------------#
      print "Start selection for DC correction...\n";
      if (defined $logfile) {
        Iraf::printlog($logfile,
	               "$epoch: Selection of sky images for DC correction.\n");
      }
      CCDred::dcsel($reducRoot, \%inst, $imDB{$epoch}); 
    }
  }
  chdir ($origDir);
}

if ($flag & ($DC)) {
  $origFlag = $flag;
  $datasec= CCDred::dataSecAfterTrim($ccdsec, $trimsec);
  unless (defined %imDB) {
    (-e 'verify.out') ? %imDB = CCDred::readVerify('verify.out') :
    				die "Images have not been verified\n";
  }
  $origDir = cwd();
  foreach $run (@runs) {
    @epochs = ();
    @nightAvail = ();
    @nightAvail = grep /$run/, keys %imDB;
    if (defined @nights) {
      foreach $avail (@nightAvail) {
        $avail =~ /(e\d+)\/$/;
	 $epoch2Find = $1;
	 if (grep { /$epoch2Find/ } @nights) { push @epochs, $avail; }
      }
    }
    else { push @epochs, @nightAvail; }
    foreach $epoch (@epochs) {
      $flag = $origFlag;   #Reset 'flag'
      unless ($epoch =~ /\/$/) {$epoch .= '/';}
      chdir ($epoch);
      print "\n$epoch\n";

      #-------------------------#
      # DC sky level correction #
      #-------------------------#
      if ($logfile && ($flag & $DC) && ($look)) {
        Iraf::printlog($logfile,
	               "\nLOOK FOR SKY IMAGES REQUIRED FOR DC CORRECTION\n");
      }

      if (($flag & $DC) && ($look)) {
       # Look for sky images required for dc correction.  Search for the
	# specific sky images asked for in dcsel.
	# DC correction: 1 << 0;
	if (defined $logfile) {
	   $lookFlag = CCDred::lookForCalib($isDef,$logfile,\%inst, $setFile,
	 			       'DC',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,$logfile,$lookFlag,\$flag,'DC');
	} else {
	   $lookFlag = CCDred::lookForCalib($isDef,'0',\%inst, $setFile,
	 			       'DC',$imgList,$imDB{$epoch},$epoch,$calibDir);
	   CCDred::testFlags($isDef,'0',$lookFlag,\$flag,'DC');
	}
      }

      if ($flag & $DC) {
       # DC correction
	# Check that the target images have been pre-processed, then correct.
	$| = 1;	#OUTPUT_AUTOFLUSH ON
	print "Start DC correction.\n";
        if (defined $logfile) {
          CCDred::goCorrection($isDef,$logfile,\%inst,$setFile,
	  		       'DC',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	} else {
	  CCDred::goCorrection($isDef,'0',\%inst,$setFile,
	  		       'DC',$imgList,$imDB{$epoch},$epoch,
			       $datasec,$ccdsec);
	}
	$| = 0;	#OUTPUT_AUTOFLUSH OFF
      }
    }
  }
  chdir($origDir);
}

$| = 0;
exit(0);
