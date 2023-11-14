package commonFunction;
use Exporter qw/ import /;

use strict;
use warnings; 

our @EXPORT_OK = qw / is_positive /;

sub is_positive {
my ($num) = @_;
return $num > 0;
}

1;