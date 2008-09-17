package File::Tagr::Web::Controller::Action;

use strict;
use warnings;
use base 'Catalyst::Controller';

use File::Tagr;
use File::Tagr::Description;

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

  my $user = $c->user();

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

  my $rs = $tagr->find_hash_by_tag($user, terms => \@search_terms, year => $year,
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

sub edit_tags
{
  my $self = shift;
  my $c = shift;

  my $digest = $c->req->param('digest');
  my $tags_param = $c->req->param('tags');
  my $username = $c->user()->username();

  my @tags = split ' ', $tags_param;

  my $tagr = File::Tagr::Web->config->{tagr};

  my ($del_ref, $add_ref) = $tagr->set_tags_for_hash($digest, [@tags], $username);

  $tagr->db()->txn_commit();

  my $message;

  if (@$del_ref || @$add_ref) {
    my $del_mess = 'none';
    my $add_mess = 'none';
    if (scalar(@$del_ref) > 0) {
      $del_mess = "@$del_ref";
    }
    if (scalar(@$add_ref) > 0) {
      $add_mess = "@$add_ref";
    }
    $message = "deleted tags: $del_mess &nbsp;&nbsp;added tags: $add_mess";
  } else {
    $message = 'no tags changed';
  }

  my $new_tags = join ',', (map { qq("$_") } @tags);

  $c->stash->{message} = qq({message: "<div class='message'>$message</div>", newField: [$new_tags]});
  $c->forward('show_message');
}

sub edit_description
{
  my $self = shift;
  my $c = shift;

  my $digest = $c->req->param('digest');
  my $description = $c->req->param('description');

  my $tagr = File::Tagr::Web->config->{tagr};

  my $hash = $tagr->find_hash($digest);
  my @old_tags = map {
    $_->detail();
  } $tagr->get_tags_of_hash($hash);

  my %old_tags = ();
  @old_tags{@old_tags} = @old_tags;

  $tagr->describe_hash($digest, $description);

  $tagr->db()->txn_commit();

  my @tags = File::Tagr::Description->get_tags_from_string($description);

  @tags = grep { !exists $old_tags{$_} } @tags;

  my $possible_tags = join ',', (map { qq("$_") } @tags);

  $c->stash->{message} = qq({message: "<div class='message'>set description</div>", possible_tags: [$possible_tags]});
  $c->forward('show_message');
}

sub edit : Local {
  my ($self, $c) = @_;

  if (defined $c->req->param('editTags')) {
    $self->edit_tags($c);
  } else {
    if (defined $c->req->param('editDescription')) {
      $self->edit_description($c);
    }
  }
}

sub add_tag : Local {
    my ( $self, $c ) = @_;
    my $tags = $c->req->param('tags');
    my $start = $c->req->param('start_thumb');
    my $end = $c->req->param('end_thumb');
    my $username = $c->user()->username();

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
        $tagr->add_tag_to_hash($tagr->find_hash($hash), $tag, $username, 0);
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
