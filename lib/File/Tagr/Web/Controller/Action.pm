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
  my $year = $c->req->param('year');
  my $month = $c->req->param('month');
  my $day = $c->req->param('day');
  my $dow = $c->req->param('dow');
  $c->stash->{year} = $year;
  $c->stash->{month} = $month;
  $c->stash->{day} = $day;
  $c->stash->{dow} = $dow;
}

sub search : Local {
  my ( $self, $c ) = @_;
  my $search_terms = $c->req->param('terms') || $c->req->param('tag');
  my $year = $c->req->param('year');
  my $month = $c->req->param('month');
  my $day = $c->req->param('day');
  my $dow = $c->req->param('dow');
  my $pos = $c->req->param('pos');
  my $count = $c->req->param('count');

  if (defined $pos) {
    $c->stash->{pos} = $pos;
  }
  if (defined $count) {
    $c->stash->{count} = $count;
  }

  my @search_terms = ();

  if (defined $search_terms) {
    $search_terms =~ s/\s+$//g;
    $search_terms =~ s/^\s+//g;
    @search_terms = map { lc } split /\s+/, $search_terms;
  }

  if (@search_terms || $year ne '' || $month ne '' || $dow ne '' || $day ne '') {
    $c->stash->{title} = 'Search results';
    $c->stash->{template} = 'thumbnails.mhtml';
  } else {
    $c->stash->{error} = 'You need to provide some search terms';
    $c->forward('/main/start');
    return;
  }

  $c->stash->{terms} = $search_terms;

  my $tagr = File::Tagr::Web->config->{tagr};

  my $rs = $tagr->find_hash_by_tag(terms => \@search_terms, year => $year, 
                                   month => $month, dow => $dow, day => $day);

#  if (@search_terms == 1 && $search_terms[0] =~ /[a-f\d]{32}/i) {
#    push @files, $tagr->find_file_by_hash($search_terms[0]);
#  } else {

  $c->stash->{year} = $year;
  $c->stash->{month} = $month;
  $c->stash->{day} = $day;
  $c->stash->{dow} = $dow;

  if ($rs->count() > 0) {
    my $pos = $c->req->param('pos');
    my $last = $c->req->param('last');

    if (defined $pos && defined $last) {
      $c->stash->{hash} = ($rs->slice($pos)->all())[0];
      $c->stash->{pos} = $pos;
      $c->stash->{last} = $last;
      $c->stash->{template} = 'detail.mhtml';
    } else {
      $c->stash->{hashes} = [$rs->all()];
    }
  } else {
    $c->stash->{error} = "No matches searching for @search_terms";
    $c->forward('/main/start');
  }
}

sub edit : Local {
  my ( $self, $c ) = @_;
  my $digest = $c->req->param('digest');
  my $tags = $c->req->param('tags');

  my $tagr = File::Tagr::Web->config->{tagr};

  $tagr->set_tags_for_hash($digest, [split ' ', $tags]);

  $c->stash->{message} = "<div class='message'>set tags: $tags</div>";
  $c->forward('show_message');
}

sub add_tag : Local {
    my ( $self, $c ) = @_;
    my $tags = $c->req->param('tags');
    my $start = $c->req->param('start_thumb');
    my $end = $c->req->param('end_thumb');

    if (!defined $tags) {
    $c->stash->{error} = 'tags not set';
    $c->forward('/main/start');
    return;
  }

  $tags =~ s/^\s+//;
  $tags =~ s/\s+$//;

  if ($tags eq '') {
    $c->stash->{error} = 'no tags given';
    $c->forward('/main/start');
    return;
  }

  my $tagr = File::Tagr::Web->config->{tagr};

  for (my $i = $start; $i < $end; $i++) {
    my $hash = $c->req->param($i);
    if (defined $hash) {
      for my $tag (split /\s+/, $tags) {
        $tagr->add_tag_to_hash($tagr->find_hash($hash), $tag, 0);
      }
    }
  }

  $c->stash->{message} = "<div class='message'>set tags: $tags</div>";
  $c->forward('show_message');

  $tagr->db()->txn_commit();
}

sub show_message : Private {
  my ($self, $c) = @_;
  $c->res->body($c->stash->{message});
}

=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
