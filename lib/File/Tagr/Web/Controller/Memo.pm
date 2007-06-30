package File::Tagr::Web::Controller::Memo;

use strict;
use warnings;
use base 'Catalyst::Controller';

use File::Tagr;

=head1 NAME

File::Tagr::Web::Controller::Memo - Catalyst Controller

=head1 SYNOPSIS

See L<File::Tagr::Web>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub search : Local {
  my ( $self, $c ) = @_;
  $c->stash->{title} = 'Search results';
  $c->stash->{template} = 'thumbnails.mhtml';

  my @filenames = ();
  for my $filename ($tagr->find_file_by_tag(@ARGV)) {
    push @filenames, $filename;
  }
  $c->stash->{filenames} = \@filenames;
}


=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
