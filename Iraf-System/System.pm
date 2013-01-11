package System;
use Iraf;

use Exporter ();
@ISA = qw(Exporter);
@EXPORT_OK = qw();	# 'delete' must not be exported

$EPREFIX='/home/labrie/prgp/iraf/system';

$pkg=$Iraf::pkg_system;
$imtype=$Iraf::imtype;

#-------------------------\
#        delete            \
#---------------------------\
sub delete {
 my ($moreParamRef,@images) = @_;
 my task='delete';

 #### WARNING ####
 $"=',';
 #### WARNING ####

 open(TMP,"|$pkg") or die "Cannot open pipe to $pkg.\n";
 print TMP "$task\n@images\n$$$moreParamRef{'verify'}\n";
 print TMP "$$moreParamRef{'allVersion'}\n$$moreParamRef{'subFiles'}\n";
 close(TMP);

 #### WARNING ####
 $"=' ';
 #### WARNING ####

 return();
}

1;
