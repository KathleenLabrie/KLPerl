package Util::File;
use Util;

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();
push @EXPORT, @Util::EXPORT;
push @EXPORT_OK, @Util::EXPORT_OK;
foreach $key (keys %Util::EXPORT_TAGS) {
   if (not defined $EXPORT_TAGS{$key}) {
   	$EXPORT_TAGS{$key} = $Util::EXPORT_TAGS{$key};
   }
}

$EPREFIX = '/home/labrie/prgp/util/file';

$nmbrline="$EPREFIX/nmbrline.pl";

1;
