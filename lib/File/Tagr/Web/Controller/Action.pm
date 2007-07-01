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
  $c->res->headers->header( 'Cache-Control' => 'max-age=86400' );
}

sub search : Local {
  my ( $self, $c ) = @_;
  my $search_terms = $c->req->param('terms');

  if (!defined $search_terms) {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  $search_terms =~ s/\s+$//g;
  $search_terms =~ s/^\s+//g;

  if (length $search_terms == 0) {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  my @search_terms = split /\s+/, $search_terms;

  if (@search_terms) {
    $c->stash->{title} = 'Search results';
    $c->stash->{template} = 'thumbnails.mhtml';
  } else {
    $c->stash->{title} = 'Error';
    $c->forward('/error');
    return;
  }

  my $tagr = new File::Tagr(config_dir => $File::Tagr::CONFIG_DIR);

  my @filenames = ();

  if (@search_terms == 1 && $search_terms[0] =~ /[a-f\d]{32}/i) {
    push @filenames, $tagr->find_file_by_hash($search_terms[0]);
  } else {
    push @filenames, $tagr->find_file_by_tag(@search_terms);
  }
  $c->stash->{filenames} = \@filenames;
  $c->stash->{terms} = "@search_terms";
}

=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
