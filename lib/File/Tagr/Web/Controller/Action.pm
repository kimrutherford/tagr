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
  $c->stash->{title} = 'Detail';
  $c->stash->{template} = 'detail.mhtml';
  $c->res->headers->header( 'Cache-Control' => 'max-age=86400' );
}

sub search : Local {
  my ( $self, $c ) = @_;
  my $search_terms = $c->req->param('terms') || $c->req->param('tag');
  my $pos = $c->req->param('pos');
  my $count = $c->req->param('count');

  if (!defined $search_terms) {
    $c->stash->{error} = 'You need to provide some search terms';
    $c->forward('/main/start');
    return;
  }

  if (defined $pos) {
    $c->stash->{pos} = $pos;
  }
  if (defined $count) {
    $c->stash->{count} = $count;
  }

  $search_terms =~ s/\s+$//g;
  $search_terms =~ s/^\s+//g;

  my @search_terms = split /\s+/, $search_terms;

  @search_terms = map { lc } @search_terms;

  if (@search_terms) {
    $c->stash->{title} = 'Search results';
    $c->stash->{template} = 'thumbnails.mhtml';
  } else {
    $c->stash->{error} = 'You need to provide some search terms';
    $c->forward('/main/start');
    return;
  }

  $c->stash->{'terms'} = $search_terms;

  my $tagr = new File::Tagr(config_dir => $File::Tagr::CONFIG_DIR);

  my @hashes = $tagr->find_hash_by_tag(@search_terms);

#  if (@search_terms == 1 && $search_terms[0] =~ /[a-f\d]{32}/i) {
#    push @files, $tagr->find_file_by_hash($search_terms[0]);
#  } else {

   $c->stash->{terms} = "@search_terms";

  if (@hashes) {
    my $pos = $c->req->param('pos');
    my $last = $c->req->param('last');

    if (defined $pos && defined $last) {
      $c->stash->{hash} = $hashes[$pos];
      $c->stash->{pos} = $pos;
      $c->stash->{last} = $last;
      $c->stash->{template} = 'detail.mhtml';
    } else {
      $c->stash->{hashes} = \@hashes;
    }
  } else {
    $c->stash->{error} = "No matches searching for @search_terms";
    $c->forward('/main/start');
  }
}

sub tagedit : Local {
  my ( $self, $c ) = @_;
  my $filename = $c->req->param('filename');
  my $tags = $c->req->param('tags');

  if (!defined $filename) {
    $c->stash->{error} = 'filename not set';
    $c->forward('/main/start');
    return;
  }

  if (!defined $tags) {
    $c->stash->{error} = 'tags not set';
    $c->forward('/main/start');
    return;
  }

}

=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
