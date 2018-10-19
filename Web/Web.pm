package Web;
use HTML::Stream;

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT = qw();
@EXPORT_OK = qw();

$EPREFIX ='/Users/klabrie/prgp/web';

#---------\
# htmlhead \
#-----------\
sub htmlhead {
 my ($html, $title, $bgcolor, $fgcolor) = @_;
 
 $html  -> HTML
        -> HEAD
        -> TITLE -> t($title) -> _TITLE
        -> _HEAD
        -> BODY(BGCOLOR=>$bgcolor, TEXT=>$fgcolor);
 
 return;
}

#---------\
# htmlfoot \
#-----------\
sub htmlfoot {
 my ($html) = @_;
 
 $html  -> _BODY
        -> _HTML;
        
 return;
}

1;
