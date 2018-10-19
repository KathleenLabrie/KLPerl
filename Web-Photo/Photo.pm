package Web::Photo;
use Web;

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();
%EXPORT_TAGS = ();
push @EXPORT, @Web::EXPORT;
push @EXPORT_OK, @Web::EXPORT_OK;
foreach $key (keys %Web::EXPORT_TAGS) {
    if (not defined $EXPORT_TAGS{$key}) {
        $EXPORT_TAGS{$key} = $Web::EXPORT_TAGS{$key};
    }
}

$EPREFIX ='/Users/klabrie/prgp/web/photo';

$pic2html = "$EPREFIX/pic2html.pl";

1;
