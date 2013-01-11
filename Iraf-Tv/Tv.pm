package Tv;
use Iraf;

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT_OK = qw();

use Env qw(HOME);

$pkg=$Iraf::pkg_tv;
$imtype=$Iraf::imtype;
$stdimage=$Iraf::stdimage;
$graphcap=$Iraf::graphcap;

$EPREFIX = '/home/labrie/prgp/iraf/tv';
$HOMEIRAF = "$HOME/iraf";

$display = "$EPREFIX/display.pl";

#$imageDisplay = "saoimage -idev $HOMEIRAF/imtXo -odev $HOMEIRAF/imtXi +imtool";
$imageDisplay = "ds9";

#-------------------------\
#        display           \
#---------------------------\

sub display {
  my ($allParamRef,$graphcap,$img) = @_;
  my $task='display';

  open(TMP,"|$pkg") or die "Cannot pipe to $pkg.\n";
  print TMP "set imtype = \"$imtype\"\n";
#  print TMP "set stdimage = \"$$allParamRef{'stdimage'}\"\n";
  print TMP "set stdimage = \"$stdimage\"\n";
  print TMP "set graphcap = \"$graphcap\"\n";
  print TMP "$task\n";
  print TMP "$img\n$$allParamRef{'frame'}\n";
  print TMP "$$allParamRef{'erase'}\n$$allParamRef{'select_frame'}\n";
  print TMP "$$allParamRef{'overlay'}\n$$allParamRef{'ocolor'}\n";
  print TMP "$$allParamRef{'bpmask'}\n$$allParamRef{'bpdisplay'}\n";
  print TMP "$$allParamRef{'bpcolor'}\n$$allParamRef{'xcenter'}\n";
  print TMP "$$allParamRef{'ycenter'}\n$$allParamRef{'xsize'}\n";
  print TMP "$$allParamRef{'ysize'}\n$$allParamRef{'fill'}\n";
  print TMP "$$allParamRef{'xmag'}\n$$allParamRef{'ymag'}\n";
  print TMP "$$allParamRef{'order'}\n$$allParamRef{'ztrans'}\n";
  print TMP "$$allParamRef{'zscale'}\n$$allParamRef{'zmask'}\n";
  print TMP "$$allParamRef{'nsample'}\n$$allParamRef{'contrast'}\n";
  print TMP "$$allParamRef{'erase'}\n";
  close(TMP);

  return();
}



1;
