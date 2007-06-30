package File::Tagr::Cache;

=head1 NAME

File::Tagr::Description - description handling

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut

use warnings;
use strict;
use Carp;
use vars qw($VERSION $CACHE @ISA @EXPORT);
use Exporter;

use Image::Magick;
use File::Path;


@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

$CACHE = "$ENV{HOME}/.tagr/cache";

sub get_image_from_cache
{
  my $class = shift;
  my $hash = shift;
  my $filename = shift;
  my $size = shift;

  if (!-d $CACHE) {
    eval { mkpath($CACHE) };
    if ($@) {
      print "Couldn't create $CACHE: $@";
    }
  }

  $filename =~ m:.*/(.*):;

  my $short_name = $1;

  my $cache_filename = "$CACHE/$short_name-$size";
  if (!-f $cache_filename) {
    my $image = Image::Magick->new;
    my $ret_code = $image->Read($filename);
    if ($ret_code) {
      warn "$ret_code";
      return undef;
    }

    $ret_code = $image->Thumbnail(geometry=>$size);
    if ($ret_code) {
      warn "$ret_code";
      return undef;
    }

    $ret_code = $image->Set(quality => 60);
    if ($ret_code) {
      warn "$ret_code";
      return undef;
    }
    $ret_code = $image->Write($cache_filename);
  }

  return $cache_filename;
}
