package CFHT

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT_OK = qw();

use Img::Header;

$OS = 'redhat';
$EPREFIX = '/home/labrie/prgp/img/header/cfht';

$imtype=$Header::imtype;

$DATE_FMT = 'Day Mon DD hh:mm:ss ZZZ YYYY';
$DATE_PTRN = '([a-zA-Z]{3}) ([a-zA-Z]{3}) (\d{2}| \d) '.
	      '(\d{2}| \d):(\d{2}):(\d{2}) ([a-zA-Z]{3}) (\d{4})';
$LOCALTIME_KEY = 'HSTTIME';
$FILTER_KEY = 'FILTER';

1;
