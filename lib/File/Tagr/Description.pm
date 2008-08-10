package File::Tagr::Description;

=head1 NAME

File::Tagr::Description - description handling

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut

use warnings;
use strict;
use Carp;
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Lingua::StopWords qw( getStopWords );

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

my $stopwords = getStopWords('en');

sub get_tags_from_string
{
  my $class = shift;
  my $description = shift;

  my @tags = ();

  while ($description =~ /([\w\d]+)/g) {
    if (!$stopwords->{$1} && length $1 > 1) {
      push @tags, lc $1;
    }
  }

  return @tags;
}
