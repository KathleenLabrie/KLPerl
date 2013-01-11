package Header

use Exporter qw();
@ISA = qw(Exporter);
@EXPORT_OK = qw();

use Img::Header::CFHT;

$OS = 'redhat';
$EPREFIX = '/home/labrie/prgp/img/header';

$imtype = 'fits';

# C routines
$C_PREFIX = '/home/labrie/prgc';

#%%%Begin KLimgutil%%%
$C_KLIMGUTIL = '/home/labrie/prgc/img/util';
#%%%End KLimgutil%%%
$getkeyval = "$C_KLIMGUTIL/getkeyval";

#-------------------------\
#        getkeyval         \
#---------------------------\
sub getkeyval {
 my ($keyword,$type,@images) = @_;
 my ($command,$fhPipeOut);
 my (@list) = ();

 $command="$Iraf::getkeyval @images -k $keyword -d $type";
 $fhPipeOut = new FileHandle "$command |" or
                        die "Unable to pipe out of $getkeyval.\n";
 @list = <$fhPipeOut>;
 $fhPipeOut->close or die "Unable to close pipe ($getkeyval).\n";

 foreach $_ (@list) { s/\n//; }

 return(@list);
}

#-------------------------\
#        getTime           \
#---------------------------\
sub getTime {
 my ($timeKey,$timeFormat,$timePattern,$img) = @_;
 my ($fhpipe,$datestr,@imgDate);
 #@imgDate = (sec,min,hour,mday,mon,year)

 $fhpipe = new FileHandle "$getkeyval $img -k $timeKey -d 'string' |";
 $datestr = <$fhpipe>;
 $fhpipe->close() or die "Unable to close pipe from $getkeyval\n";
 $datestr =~ s/\n//;
 
 @imgDate = &parseDate($datestr,$timeFormat,$timePattern);

 return(timelocal(@imgDate));
}

#-------------------------\
#        parseDate         \
#---------------------------\
sub parseDate {
 my ($dateString, $format, $pattern) = @_;
 my (@date);
 my (@months) = qw(Jan Feb Mar Apr May Jun Jul Aug Sep Oct Nov Dec);

 $dateString =~ /$pattern/;
 SWITCH: {
   if ( $format eq $CFHT::DATE_FMT ) {
     $date[0] = $6;
     $date[1] = $5;
     $date[2] = $4;
     $date[3] = $3;
     $date[4] = Util::indexOf($2,@months);
     $date[5] = $8 - 1900;
     last SWITCH;
   }
 }
 
 return(@date);
}


1;
