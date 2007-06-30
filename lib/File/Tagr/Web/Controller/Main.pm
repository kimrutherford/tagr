package EchoMemo::Controller::Main;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

EchoMemo::Controller::Main - Catalyst Controller

=head1 SYNOPSIS

See L<EchoMemo>

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
  $c->stash->{error} = "Unknown page - @rest";
  $c->forward('/main/start');
}



=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
