package Iraf;

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT_OK = qw(printlog);

$EPREFIX='/home/labrie/prgp/iraf';

$OS='redhat';
$imtype='fits';
$stdimage='imt800';
$IRAFBIN = "/iraf/irafbin";
$IRAFIRAF= "/iraf/iraf";
$graphcap = $IRAFIRAF.'/dev/graphcap';

$pkg_ccdred = "$IRAFBIN/noao.bin.$OS/x_ccdred.e";
$pkg_images = "$IRAFBIN/bin.$OS/x_images.e";
$pkg_system = "$IRAFBIN/bin.$OS/x_system.e";
$pkg_tv     = "$IRAFBIN/bin.$OS/x_tv.e";

$MAXLENGTH = 512;

# C routines
$CDIR = '/home/labrie/prgc';
$getkeyval = "$CDIR/img/util/getkeyval";

%IRAFbasetime = (	#00:00:00 1-Jan-80
	sec => 0,
	min => 0,
	hours => 0,
	mday => 1,
	mon => 0,
	year => 80,
);

#-------------------------\
#         arcSep           \
#---------------------------\
sub arcSep {
 my ($raRef,$decRef,$raImg,$decImg) = @_;
 my ($dx,$dy);
 my (@tmp);
 my ($PI,$PIover180);

 $PI = atan2(1,1) * 4;
 $PIover180 = $PI/180.;

 @tmp = split /:/, $raRef;
 $raRef = ($tmp[0]+($tmp[1]/60.)+($tmp[2]/3600.)) * 360. / 24.;
 @tmp = split /:/, $decRef;
 $decRef = $tmp[0]+($tmp[1]/60.)+($tmp[2]/3600.);
 @tmp = split /:/, $raImg;
 $raImg = ($tmp[0]+($tmp[1]/60.)+($tmp[2]/3600.)) * 360. / 24.;
 @tmp = split /:/, $decImg;
 $decImg = $tmp[0]+($tmp[1]/60.)+($tmp[2]/3600.);
 
 #Now that everything is in degrees, calculate the separation in arcseconds.
 $dx = ($raImg - $raRef) * cos($decRef * $PIover180) * 3600.;
 $dy = ($decImg - $decRef) * 3600.;

 return($dx,$dy);
}

#-------------------------\
#         findAll          \
#---------------------------\
sub findAll {
 my ($keyword,$type,$ref2Images) = @_;
 my (@all) = ();
 my (@list) = ();

 @list = &getkeyval($keyword,$type,@{ $ref2Images });
 foreach $value (@list) {
   unless ( grep /^$value$/, @all ) { push @all, $value; }
 }

 return(@all);
}


#-------------------------\
#        getkeyval         \
#---------------------------\
sub getkeyval {
 my ($keyword,$type,@images) = @_;
 my ($command,$fhPipeOut);
 my (@list) = ();

 $command="$getkeyval @images -k $keyword -d $type";
 $fhPipeOut = new FileHandle "$command |" or
 			die "Unable to pipe out of $getkeyval.\n";
 @list = <$fhPipeOut>;
 $fhPipeOut->close or die "Unable to close pipe ($getkeyval).\n";

 foreach $_ (@list) { s/\n//; }

 return(@list);
}


#-------------------------\
#       printlog           \
#---------------------------\
sub printlog {
  my ($logfile,$message) = @_;

  $fhlog = new FileHandle ">>$logfile" or 
  			die "Unable to open $logfile for writing\n";
  print $fhlog "$message";
  $fhlog->close;

  return();
}

#-------------------------\
#      whereParam          \
#---------------------------\

sub whereParam {
  local ($setFile) = @_;
  local ($file);
  local (%hash);

  %hash = &getParam($setFile,':');
  $file = $hash{'directory'}.$hash{'site'}.'/'.$hash{'instrument'}.'.cl';
  
  return($file);
}

#-------------------------\
#        getParam          \
#---------------------------\

sub getParam {
  local ($file,$token) = @_;
  local (%hash,$key,$value);

  open (INPUT,"<$file") or die "Cannot open $file for reading.\n";
  while (<INPUT>) {
    next if /^#/;
    next if /^\s/;
    s/\n//;
    ($key,$value) = split /$token/;
    $key =~ s/\s$//;
    $value =~ s/^\s//;
    $value =~ s/"//g;
    $hash{$key} = $value;
  }
  close(INPUT);
  
  return(%hash);
}

#-------------------------\
#        getTrans          \
#---------------------------\

sub getTrans {
  my ($file,$key,$col) = @_;
  my ($value,@cols,@tmpcols,$string,$c);
  my ($notfound) = 1;
  my ($notdone) = 0;

  open (INPUT, "<$file") or die "Cannot open $file for reading.\n";
  while (defined ($_ = <INPUT>) and $notfound) {
    @cols=();
    @tmpcols = split /(\s+)/;
    $notdone = 0;
    $string='';
    foreach $c (@tmpcols) {
      if (($c =~ s/^'//) or $notdone) {
        $notdone = 1;
	$string .= $c;
	if ($string =~ s/'$//) {
	  $notdone = 0;
	  push @cols, $string;
	}
	next;
      }
      if ($c =~ /\w/) { push @cols, $c; }
    }
    if ($cols[0] eq $key) {
      $value = $cols[$col-1];
      $notfound = 0;
    }
  }
  close(INPUT);
  if ($notfound) {
    warn "Could not find a translation for '$key'.\n";
    warn "Assuming that no translation was necessary.\n";
    return($key);
  }
  return($value);
}
