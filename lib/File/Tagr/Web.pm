package EchoMemo;

use strict;
use warnings;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the applications root directory
#
use Catalyst qw/-Debug Static::Simple StackTrace/;

our $VERSION = '0.01';

#
# Configure the application
#
__PACKAGE__->config( name => 'EchoMemo' );

#
# Start the application
#
__PACKAGE__->setup;


sub default : Private {
  my ( $self, $c ) = @_;
  if ($c->request->path() eq '') {
    $c->forward('/main/start');
  } else {
    $c->forward('/main/error');
  }
}

sub end : Private {
  my ( $self, $c ) = @_;
  $c->forward('EchoMemo::View::Main') unless $c->res->output;
}

1;
