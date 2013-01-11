# Module configuration template.
# Prepend desired configuration
# DO NOT MODIFY THIS FILE

@lines = <FILE>;
close(FILE);

KEY: foreach $key (keys %hash) {
  foreach $_ (@lines) {
    if (/$key/) {
      s/$1/$hash{$key}/;
      next KEY;
    }
  }
}
print @lines;

exit(0);
