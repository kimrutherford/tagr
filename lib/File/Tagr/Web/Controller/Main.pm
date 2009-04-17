package File::Tagr::Web::Controller::Main;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

File::Tagr::Web::Controller::Main - Catalyst Controller

=head1 SYNOPSIS

See L<File::Tagr::Web>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub start : Local {
  my ( $self, $c ) = @_;
  $c->stash->{title} = 'Start page';
  $c->stash->{template} = 'main.mhtml';
}

sub error : Local {
  my ( $self, $c, @rest ) = @_;
  $c->stash->{error} = "Unknown page - /@rest";
  $c->forward('/main/start');
}

sub login : Global {
  my ( $self, $c ) = @_;
  my $username = $c->req->param('username');
  my $password = $c->req->param('password');

  my $return_path = $c->req->param('return_path');

  if ($c->authenticate({username => $username, password => $password})) {
    if ($return_path =~ m:logout:) {
      $c->forward('/main/start');
      return 0;
    }
  } else {
    $c->stash->{error} = "log in failed";
  }

  $c->res->redirect($return_path, 302);
  $c->detach();
  return 0;
}

sub logout : Global {
  my ( $self, $c ) = @_;
  $c->logout;

  $c->forward('/main/start');
}

sub exitme : Global {

  exit(0);
}

=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
