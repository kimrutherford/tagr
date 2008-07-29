package File::Tagr::Web::Util;

use strict;
use warnings;

sub get_params_from_date_bits
{
  my $class = shift;
  my %args = @_;

  my $date_bits = "";

  for my $type (qw(year month day dow)) {
    if (exists $args{$type} && $args{$type} ne '') {
      $date_bits .= $type . '=' . $args{$type} . '&'
    }
  }

  return $date_bits;
}

1;
