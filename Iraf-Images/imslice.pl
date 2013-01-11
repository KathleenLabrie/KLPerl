#!/usr/local/bin/perl -w
#
#Package: Iraf::Images
#Name: imslice
#Version: 1.0.0
#  Slice images into images of lower dimension
#
#Usage: imslice images/-l list --root=root1,root2... --dim=dimension --update
#		  --dir=directory --log=logfile
#
#	images		  : Images to slice
#	-l list	  : Name of the file containing the list of images to slice
#	--root=root1,root2:
#			    If define, the number of roots should be equal to the
#			    number of images.  If left undefined, the image name is
#			    taken as root (default).
#	--dim=dimension : The dimension to slice.
#	--update	  : Update the list to include the new image names.
#	--dir=directory : Location of the images.  To be prepended to each image
#			    name.  Default is './'.
#	--log=logfile	  : Name of the logfile. Defaut is none.

use FileHandle;
use lib qw(/home/labrie/prgp/include);	#prepend the dir to @INC
use Iraf::Images;

#Define
$datatype = 'ushort';
$getkeyval = $Images::getkeyval;
$imtype = $Images::imtype;
$NAXIS = 'NAXIS';
$NAXISn = 'NAXIS';		# later, dim is concatened on this

#Set defaults
$moreParam{'update'} = 0;
$moreParam{'verbose'} = 'yes';
$moreParam{'dir'} = './';

#Initialize
@listOfImages=();	#List of Hashes: 'name','root','naxis','naxixn'
@listOfRoots=();

#Read command line
while ($_ = shift @ARGV) {
  SWITCH: {
    if ( /^-l/ ) {$list = shift @ARGV; last SWITCH;}
    if ( /--/ ) {
       s/--//;
	if (/=/) { ($key,$value) = split /=/; }
	else     { $key = $_; $value = 1;     }
	$moreParam{$key} = $value;
	last SWITCH;
    }
    s/\.fits$|\.imh$//;	#img.fits -> img
    $rec = {};
    $rec->{'name'} = $_;
    push @listOfImages, $rec;
  }
}

#Read the file with the list of images
if (defined $list) {
  open(LIST,"<$list") or die "Cannot open $list for reading.\n";
  while (<LIST>) {
    s/\n//;
    s/\.fits$|\.imh$//;	# img.fits -> img
    $rec = {};
    $rec->{'name'} = $_;
    push @listOfImages, $rec;
  }
  close(LIST);
}

#Check that the directory exist, if specified
if (!-e $moreParam{'dir'}) {
  if (defined $moreParam{'log'}) {
    Iraf::printlog("ERROR: Cannot find $moreParam{'dir'}.\n");
  }
  die "Cannot find $moreParam{'dir'}.\n";
}
$moreParam{'dir'} .= '/';
$moreParam{'dir'} =~ s/\/\///g;

#Dimension
if (!defined $moreParam{'dim'}) {
  if (defined $moreParam{'log'}) {
    Iraf::printlog("ERROR: No dimension specified.\n");
  }
  die "ERROR: No dimension specified.\n";
}
$NAXISn .= $moreParam{'dim'};

#Check outputs' root
if (defined $root) {
  @listOfRoots = split '/', $root;
  unless ($#listOfRoots == $#listOfImages) {
  	if (defined $moreParam{'log'}) {
	  Iraf::printlog("ERROR: Number of root names not equal to number of images.\n");
	}
  	die "ERROR: Number of root names not equal to number of images.\n";
  }
  for ($i=0; $i<$#listOfImages; $i++) {
    $listOfImages[$i]{'root'} = $listOfRoot[$i];
  }
}
else {
  foreach $rec ( @listOfImages) {
    $rec->{'root'} = $rec->{'name'}.'-';
  }
}
undef @listOfRoot;

#more initialisation
if ($moreParam{'update'}) {
  if (!defined $list) {
    if (defined $moreParam{'log'}) {
      Iraf::printlog("ERROR: No list used, cannot 'update'.\n");
    }
    die "ERROR: No list used, cannot 'update'.\n";
  }
  @newListOfImages = ();
}

#Insert the right image type extension and check that they exist
foreach $rec ( @listOfImages ) {
  $rec->{'name'} .= '.'.$imtype;
  next if (-e "$moreParam{'dir'}$rec->{'name'}");
  if (defined $moreParam{'log'}) {
    Iraf::printlog("ERROR: Cannot find image $moreParam{'dir'}$rec->{'name'}.\n");
  }
  die "Cannot find image $moreParam{'dir'}$rec->{'name'}.\n";
}

#Get the number of axis of each image, and the length of the 'dim' axis
$images = '';
foreach $rec ( @listOfImages ) {
  $images .= $moreParam{'dir'}.$rec->{'name'}.' ';
}
$pipe = "$getkeyval $images -k $NAXIS -d $datatype";
$fhPipeOut = new FileHandle "$pipe |";  
foreach $rec ( @listOfImages ) {
  $_ = <$fhPipeOut>;
  s/\n//;
  $rec->{'naxis'} = $_;
}
$fhPipeOut->close();  

#Get on to it...
foreach $rec (@listOfImages) {
  if ($rec->{'naxis'} < $moreParam{'dim'}) {
    if ($moreParam{'update'}) { push @newListOfImages, $rec->{'name'}; }
    $warning = "WARNING: $rec->{'name'} -- NAXIS is lower than the dimension ".
    		 "to slice.\n         Skipping this image.\n";
    if (defined $moreParam{'log'}) {
      Iraf::printlog("\n$rec->{'name'}:  $warning");
    }
    warn "$warning";
    next;
  }
  if ( $moreParam{'update'} or defined $moreParam{'log'} ) {
    $pipe = "$getkeyval $moreParam{'dir'}$rec->{'name'} -k '$NAXISn' -d $datatype";
    $fhPipeOut = new FileHandle "$pipe |";
    $_ = <$fhPipeOut>;
    s/\n//;
    $rec->{'naxisn'}=$_;
    $id='000';
    if ( defined $moreParam{'log'} ) {
      Iraf::printlog("$rec->{'name'}:  Stack of $rec->{'naxisn'} images\n");
    }
    for ($i=1; $i<=$rec->{'naxisn'}; $i++) {
      $id++;
      $rec->{'name'} =~ /(\w+)(\.fits$)/;
      push @newListOfImages, "$rec->{'root'}$id$2";
    }
  }
  #Slice
  Images::imslice ( \%moreParam,$rec );

  if ( defined $moreParam{'log'} ) {
    $id='000';
    $fhlog = new FileHandle ">>$moreParam{'log'}" or 
    			die "Cannot open $moreParam{'log'} for writing.\n";
    for ($i=1; $i<=$rec->{'naxisn'}; $i++) {
      $id++;
      $rec->{'name'} =~ /(\w+)(\.fits$)/;
      print $fhlog "\t\t\t$rec->{'root'}$id$2\n";
    }
    $fhlog->close;
  }
}

#Edit 'list'
if ($moreParam{'update'}) {
  open (LIST, ">$list") or die "Unable to open $list for writting.\n";
  foreach $_ (@newListOfImages) {
  	print LIST "$_\n";
  }
  close (LIST);
  Iraf::printlog("WARNING: $list has been edited to list the slices.\n\n");
}


exit(0);
