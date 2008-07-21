package File::Tagr::Web;

use strict;
use warnings;

use File::Tagr;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
# Static::Simple: will serve static files from the applications root directory
#
use Catalyst qw[-Debug Static::Simple StackTrace Cache::FileCache PageCache];

File::Tagr::Web->config->{static}->{debug} = 1;
File::Tagr::Web->config->{tagr} =
  new File::Tagr(config_dir => $File::Tagr::CONFIG_DIR, verbose => 0);

File::Tagr::Web->config->{page_cache} = {
    expires => 30000,
    set_http_headers => 1,
    debug => 1,
};

our $VERSION = '0.01';

#
# Configure the application
#
__PACKAGE__->config( name => 'File::Tagr::Web' );

#
# Start the application
#
__PACKAGE__->setup;


sub default : Private {
  my ( $self, $c ) = @_;

  $c->res->headers->header( 'Cache-Control' => 'max-age=86400' );

  if ($c->request->path() eq '') {
    $c->forward('/main/start');
  } else {
    $c->forward('/main/error');
  }
}

sub end : Private {
  my ( $self, $c ) = @_;
  $c->forward('File::Tagr::Web::View::Main') unless $c->res->output;
}

1;
