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

use File::Tagr;


@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

$CACHE = "/home/kmr/.tagr/cache";

sub get_image_from_cache
{
  my $class = shift;
  my $hash = shift;
  my $sizes = shift;

  if (!-d $CACHE) {
    eval { mkpath($CACHE) };
    if ($@) {
      print "Couldn't create $CACHE: $@";
    }
  }

  my @files = $hash->files();

  my $filename = undef;

  for my $file (@files) {
    my $detail = $file->detail();
    if (-f $detail) {
      $filename = $detail;
      last;
    }
  }

  if (!defined $filename) {
    return undef;
  }

  $filename =~ m:.*/(.*):;

  my @missing_sizes = ();
  my $make_full = 0;

  for my $size (@$sizes) {
    if ($size eq 'full') {
      $make_full = 1;
    } else {
      my $cache_filename = "$CACHE/" . cache_file_name($hash->detail(), $size, $filename);
      if (!-f $cache_filename) {
        push @missing_sizes, $size;
      }
    }
  }

  if (@missing_sizes) {
    my $base_image = Image::Magick->new;
    my $ret_code = $base_image->Read($filename);
    if ($ret_code) {
      warn "$ret_code";
      return undef;
    }

    for my $size (@missing_sizes) {
      my $image = $base_image->clone();

      if (!ref $image) {
        next;
      }

      my $cache_filename = "$CACHE/" . cache_file_name($hash->detail(), $size, $filename);

      $ret_code = $image->Thumbnail(geometry=>$size);
      if ($ret_code) {
        warn "$ret_code";
        return undef;
      }

      $ret_code = $image->Set(quality => 85);
      if ($ret_code) {
        warn "$ret_code";
        return undef;
      }
      $ret_code = $image->Write($cache_filename);
    }
  }

  if ($make_full) {
    my $dest_file = "$CACHE/" . cache_file_name($hash->detail(), 'full', $filename);
    unlink $dest_file;
    if (!symlink $filename, $dest_file) {
      die "couldn't symlink to $dest_file";
    }
  }

  return map {cache_file_name ($hash->detail(), $_, $filename)} @$sizes;
}

sub cache_file_name
{
  my $hash = shift;
  my $size = shift;
  my $filename = shift;
  my $ext = 'jpg';

  if ($filename =~ /.*\.(.*)$/) {
    $ext = lc $1;
  }

  my $cache_filename = $hash . "-$size.$ext";
}
