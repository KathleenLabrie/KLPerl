#!/usr/local/bin/perl -w
#
# Are strings in 'file1' found in 'file2' ?


$file1 = shift @ARGV;
$file2 = shift @ARGV;

open(FILE2,"<$file2");
@lines = <FILE2>;
close(FILE2);

open(FILE1,"<$file1");
while ($str = <FILE1>) {
  next if ($str =~ /^#/ or $str =~ /^\s*\n/);
  @found = ();
  $str =~ s/\n//;
  @found = grep { /$str/ } @lines;
  if ($#found >= 0) { print @found; }
}
close(FILE1);

exit(0);
