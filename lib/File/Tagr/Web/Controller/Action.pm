package File::Tagr::Web::Controller::Action;

use strict;
use warnings;
use base 'Catalyst::Controller';

use File::Tagr;

=head1 NAME

File::Tagr::Web::Controller::Action - Catalyst Controller

=head1 SYNOPSIS

See L<File::Tagr::Web>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub detail : Local {
  my ( $self, $c ) = @_;
  $c->stash->{title} = 'Search results';
  $c->stash->{template} = 'detail.mhtml';
}

sub search : Local {
  my ( $self, $c ) = @_;
  my $tag_string = $c->req->param('tags');

  if (!defined $tag_string) {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  $tag_string =~ s/\s+$//g;
  $tag_string =~ s/^\s+//g;

  if (length $tag_string == 0) {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  my @tags = split /\s+/, $tag_string;

  if (@tags) {
    $c->stash->{title} = 'Search results';
    $c->stash->{template} = 'thumbnails.mhtml';
  } else {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  my $tagr = new File::Tagr(config_dir => $File::Tagr::CONFIG_DIR);

  my @filenames = ();
  for my $filename ($tagr->find_file_by_tag(@tags)) {
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
