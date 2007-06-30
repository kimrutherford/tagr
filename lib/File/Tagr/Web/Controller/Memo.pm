package File::Tagr::Web::Controller::Memo;

use strict;
use warnings;
use base 'Catalyst::Controller';

=head1 NAME

File::Tagr::Web::Controller::Memo - Catalyst Controller

=head1 SYNOPSIS

See L<File::Tagr::Web>

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut

sub create : Local {
  my ( $self, $c ) = @_;
  $c->stash->{title} = 'Message created';
  $c->stash->{template} = 'created.mhtml';
}


=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
