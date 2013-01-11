package Images;
use Iraf;

use Exporter ();
@ISA = qw(Exporter);
@EXPORT_OK = qw(median);

$EPREFIX = '/home/labrie/prgp/iraf/images';

$pkg=$Iraf::pkg_images;
$imtype=$Iraf::imtype;
$getkeyval=$Iraf::getkeyval;

$gauss="$EPREFIX/gauss.pl";
$hselect="$EPREFIX/hselect.pl";
$imcombine="$EPREFIX/imcombine.pl";
$imcopy="$EPREFIX/imcopy.pl";
$imreplace="$EPREFIX/imreplace.pl";
$imslice="$EPREFIX/imslice.pl";
$imstatsel="$EPREFIX/imstatsel.pl";
$rotate="$EPREFIX/rotate.pl";
$thumbnail="$EPREFIX/thumbnail.pl";

#Error codes
$UNABLE_CLOSE_PIPE = 301;

#-------------------------\
#          gauss           \
#---------------------------\
sub gauss {
 my ($allParamRef,$ref2inputs, $ref2outputs) = @_;
 my $task='gauss';
 my $status=0;

 #### WARNING ####
 $" = ',';
 
 for ($i=0; $i<=$#listOfImages; $i++) {
   $status=0;
   if ($VERBOSE) { print "${ $ref2inputs }[$i] -> ${ $ref2outputs }[$i]\n"; }
   if (defined $$allParamRef{'log'}) {
     Iraf::printlog($$allParamRef{'log'},
     		    "${ $ref2inputs }[$i] -> ${ $ref2outputs }[$i]");
   }


   $fhPipeIn = new FileHandle "|$pkg" or die "Cannot pipe to $pkg.\n";
   print $fhPipeIn "set imtype = \"$imtype\"\n";
   print $fhPipeIn "$task\n";
   print $fhPipeIn "${ $ref2inputs }[$i]\n";
   print $fhPipeIn "${ $ref2outputs }[$i]\n";
   print $fhPipeIn "$$allParamRef{'sigma'}\n";
   print $fhPipeIn "$$allParamRef{'ratio'}\n$$allParamRef{'theta'}\n";
   print $fhPipeIn "$$allParamRef{'nsigma'}\n";
   print $fhPipeIn "$$allParamRef{'bilinear'}\n$$allParamRef{'boundary'}\n";
   if ($$allParamRef{'boundary'} eq 'constant') {
     print $fhPipeIn "$$allParamRef{'constant'}\n";
   }
   $fhPipeIn->close or $status=$UNABLE_CLOSE_PIPE;
   if (defined $$allParamRef{'log'}) {
     if ($status == $UNABLE_CLOSE_PIPE) {
	 $message = "\n\tERROR: Error while doing the convolution.\n";
     } else {
	 $message = "\n";
     }
     Iraf::printlog($$allParamRef{'log'},$message);
   }
 }

 #### WARNING ####
 $" = ' ';

 return;
}

#-------------------------\
#         hselect          \
#---------------------------\
sub hselect {
  my ($moreParamRef,@images) = @_;
  my ($totalLength);
  my ($MAXLENGTH) = 512;
  my (@imgs);

  while ( defined $images[0] ) {
    @imgs = ();
    $totalLength = 0;
    while ( ( defined $images[0] ) and
    		( ($totalLength + length ($images[0])) <= $MAXLENGTH ) ) {
	$totalLength += length ($images[0]) + 1;	# +1 for comma
	push @imgs, shift @images;
    }
    &hselect_sub($moreParamRef,@imgs);
  }
  return();
}

#-------------------------\
#      hselect_sub         \
#---------------------------\
sub hselect_sub {
  my ($moreParamRef,@images) = @_;
  my $task = 'hselect';

  #**** WARNING ****
  $" = ',';
  #**** WARNING ****

  open(TMP,"|$pkg") or die "Unable to fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "@images\n";
  print TMP "$$moreParamRef{'fields'}\n$$moreParamRef{'expr'}\n";
  close(TMP) or die "Unable to close $pkg.\n";

  #**** WARNING ****
  $" = ' ';
  #**** WARNING ****

  return();
}

#-------------------------\
#       imcombine          \
#---------------------------\
sub imcombine {
  my ($moreParamRef,@images) = @_;
  my $task='imcombine';

  #**** WARNING ****
  $" = ',';
  #**** WARNING ****
  
  open (TMP, "|$pkg") or die "Unable to fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  if (-e 'scratch') {
    print TMP "\@scratch\n";
  }
  else {
    print TMP "@images\n";
  }
  print TMP "$$moreParamRef{'output'}\n";
  print TMP "$$moreParamRef{'rejmask'}\n$$moreParamRef{'plfile'}\n";
  print TMP "$$moreParamRef{'sigma'}\n$$moreParamRef{'logfile'}\n";
  print TMP "$$moreParamRef{'project'}\n$$moreParamRef{'combine'}\n";
  print TMP "$$moreParamRef{'reject'}\n$$moreParamRef{'blank'}\n";
  print TMP "$$moreParamRef{'gain'}\n$$moreParamRef{'rdnoise'}\n";
  print TMP "$$moreParamRef{'snoise'}\n$$moreParamRef{'lthreshold'}\n";
  print TMP "$$moreParamRef{'hthreshold'}\n$$moreParamRef{'lsigma'}\n";
  print TMP "$$moreParamRef{'hsigma'}\n$$moreParamRef{'pclip'}\n";
  print TMP "$$moreParamRef{'nlow'}\n$$moreParamRef{'nhigh'}\n";
  print TMP "$$moreParamRef{'nkeep'}\n$$moreParamRef{'grow'}\n";
  print TMP "$$moreParamRef{'mclip'}\n$$moreParamRef{'sigscale'}\n";
  print TMP "$$moreParamRef{'offsets'}\n$$moreParamRef{'outtype'}\n";
  print TMP "$$moreParamRef{'masktype'}\n$$moreParamRef{'maskvalue'}\n";
  print TMP "$$moreParamRef{'expname'}\n$$moreParamRef{'scale'}\n";
  print TMP "$$moreParamRef{'zero'}\n$$moreParamRef{'weight'}\n";
  print TMP "\"$$moreParamRef{'statsec'}\"\n";
  if ($$moreParamRef{'scale'} ne 'none') {
    print TMP "\"$$moreParamRef{'statsec'}\"\n";
  }
  close (TMP) or die "Unable to close $pkg.\n";

  return();
}

#-------------------------\
#         imcopy           \
#---------------------------\
sub imcopy {
  my ($moreParamRef,$input,$output) = @_;
  my $task='imcopy';
  
  #### WARNING ####
  $"=',';
  #### WARNING ####
  
  open(TMP,"|$pkg") or die "Cannot fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$input\n$output\n";
  print TMP "$$moreParamRef{'verbose'}\n";
  close(TMP) or die "Unable to close $pkg.\n";
  
  #### WARNING ####
  $"=' ';
  #### WARNING ####

  return();
}


#-------------------------\
#       imdelete           \
#---------------------------\
sub imdelete {
  my ($moreParamRef,@images) = @_;
  my $task='imdelete';

  #### WARNING ####
  $"=',';
  #### WARNING ####

  open (TMP,"|$pkg") or die "Cannot open pipe to $pkg.\n";
  print TMP "$task\n@images\n$$moreParamRef{'verify'}\n";
  close (TMP);

  #### WARNING ####
  $"=' ';
  #### WARNING ####

  return();
}

#-------------------------\
#       imreplace          \
#---------------------------\
sub imreplace {
  my ($moreParamRef,@images) = @_;
  my $task='imreplace';

  #### WARNING ####
  $"=',';
  #### WARNING ####

  open(TMP,"|$pkg") or die "Cannot fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "@images\n";
  print TMP "$$moreParamRef{'value'}\n$$moreParamRef{'imaginary'}\n";
  print TMP "$$moreParamRef{'lower'}\n$$moreParamRef{'upper'}\n";
  print TMP "$$moreParamRef{'radius'}\n";
  close(TMP) or die "Unable to close $pkg.\n";

  #### WARNING ####
  $"=' ';
  #### WARNING ####

  return();
}

#-------------------------\
#        imslice           \
#---------------------------\
sub imslice {
  my ($moreParamRef,$rec) = @_;
  my $task='imslice';

  open(TMP, "|$pkg") or die "Unable to fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$$moreParamRef{'dir'}$rec->{'name'}\n";
  print TMP "$$moreParamRef{'dir'}$rec->{'root'}\n";
  print TMP "$$moreParamRef{'dim'}\n$$moreParamRef{'verbose'}\n";
  close(TMP) or die "Unable to close $pkg.\n";

  return();
}

#-------------------------\
#      imstatistics        \
#---------------------------\
sub imstatistics {
  my ($moreParamRef,@images) = @_;
  my ($task) = 'imstatistics';

  #**** WARNING ****
  $"=',';
  #**** WARNING ****

  open(TMP, "|$pkg") or die "Cannot open pipe to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "@images\n";
  print TMP "$$moreParamRef{'fields'}\n$$moreParamRef{'lower'}\n";
  print TMP "$$moreParamRef{'upper'}\n$$moreParamRef{'binwidth'}\n";
  print TMP "$$moreParamRef{'format'}\n";
  close(TMP) or die "Unable to close pipe to $pkg.\n";

  $"=' ';

  return();
}

#-------------------------\
#         median           \
#---------------------------\
sub median {
  my ($moreParamRef,$input,$output) = @_;
  my $task='median';

  open(TMP,"|$pkg") or die "Cannot open pipe to $pkg.\n";
  print TMP "set imtype= \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$input\n$output\n";
  print TMP "$$moreParamRef{'xbox'}\n$$moreParamRef{'ybox'}\n";
  print TMP "$$moreParamRef{'zlo'}\n$$moreParamRef{'zhi'}\n";
  print TMP "$$moreParamRef{'boundary'}\n$$moreParamRef{'constant'}\n";
  print TMP "$$moreParamRef{'verbose'}\n";
  close(TMP);

  return();
}

#-------------------------\
#         rotate           \
#---------------------------\
sub rotate {
  my ($moreParamRef) = @_;
  my $task='geotran';
  
  $geotranParam{'database'}="";
  $geotranParam{'transforms'}="";
  $geotranParam{'geometry'}='linear';
  $geotranParam{'xmin'}=1.0;
  $geotranParam{'xmax'}=$$moreParamRef{'ncols'};
  $geotranParam{'ymin'}=1.0;
  $geotranParam{'ymax'}=$$moreParamRef{'nlines'};
  $geotranParam{'xscale'}=1.0;
  $geotranParam{'yscale'}=1.0;
  $geotranParam{'xshift'}='INDEF';
  $geotranParam{'yshift'}='INDEF';
  $geotranParam{'xmag'}='INDEF';
  $geotranParam{'ymag'}='INDEF';
  $geotranParam{'xrotation'}=$$moreParamRef{'rotation'};
  $geotranParam{'yrotation'}=$$moreParamRef{'rotation'};
  $geotranParam{'xsample'}=1.;
  $geotranParam{'ysample'}=1.;
  $geotranParam{'fluxconserve'}='no';
  
  open(TMP, "|$pkg") or die "Unable to fork to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
  print TMP "$task\n";
  print TMP "$$moreParamRef{'input'}\n$$moreParamRef{'output'}\n";
  print TMP "$geotranParam{'database'}\n";
  #print TMP "$geotranParam{'transforms'}\n";
  #print TMP "$geotranParam{'geometry'}\n";
  print TMP "$geotranParam{'xmin'}\n";
  print TMP "$geotranParam{'xmax'}\n$geotranParam{'ymin'}\n";
  print TMP "$geotranParam{'ymax'}\n$geotranParam{'xscale'}\n";
  print TMP "$geotranParam{'yscale'}\n$$moreParamRef{'ncols'}\n";
  print TMP "$$moreParamRef{'nlines'}\n$$moreParamRef{'xin'}\n";
  print TMP "$$moreParamRef{'yin'}\n$geotranParam{'xshift'}\n";
  print TMP "$geotranParam{'yshift'}\n$$moreParamRef{'xout'}\n";
  print TMP "$$moreParamRef{'yout'}\n$geotranParam{'xmag'}\n";
  print TMP "$geotranParam{'ymag'}\n$geotranParam{'xrotation'}\n";
  print TMP "$geotranParam{'yrotation'}\n$$moreParamRef{'interpo'}\n";
  print TMP "$$moreParamRef{'boundar'}\n$$moreParamRef{'constan'}\n";
  print TMP "$geotranParam{'xsample'}\n$geotranParam{'ysample'}\n";
  print TMP "$geotranParam{'fluxconserve'}\n$$moreParamRef{'nxblock'}\n";
  print TMP "$$moreParamRef{'nyblock'}\n$$moreParamRef{'verbose'}\n";
  close(TMP) or die "Unable to close $pkg.\n";
  
  return();
}

#-------------------------\
#        selection         \
#---------------------------\
sub selection {
 my ($findThis,$headerName,@images) = @_;
 my ($options, $command,$expr,@allThis,$fhPipeOut);
 my (@selection) = ();
 
 if ($findThis =~ /\|\|/) {	# OR list
    @allThis = split /\|\|/, $findThis;
    for $_ (@allThis) {
      $expr.="$headerName == \"$_\" || ";
    }
    $expr =~ s/( \|\| )$//;
 } else {
    $expr="$headerName == \"$findThis\"";
 }

 $options="--fields='\$I' --expr='$expr'";
 $command = "$hselect @images $options";
 $fhPipeOut = new FileHandle "$command |";
 while (<$fhPipeOut>) {
   s/(^\s|\n)//g;
   s/> > images: fields: expr: //;
   next if />/;
   push @selection, $_;
 }
 $fhPipeOut->close;

 return(@selection);
}


1;
