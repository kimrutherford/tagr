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

use Cache::Memcached; 

my %cache = ();

my $memd = new Cache::Memcached(
  {
   servers => [ 'bob:11211' ],
   namespace => 'tagr:',
   connect_timeout => 1.9,
   io_timeout => 0.5,
   close_on_error => 1,
   compress_threshold => 100_000,
   compress_ratio => 0.9,
   compress_methods => [ \&IO::Compress::Gzip::gzip,
                         \&IO::Uncompress::Gunzip::gunzip ],
   max_failures => 3,
   failure_timeout => 2,
   ketama_points => 150,
   nowait => 1,
   hash_namespace => 1,
   serialize_methods => [ \&Storable::freeze, \&Storable::thaw ],
   utf8 => ($^V ge v5.8.1 ? 1 : 0),
  });

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

  my $filename = undef;

  my $digest = $hash->detail();

  my $filename_from_cache = $memd->get($digest);

  if (defined $filename_from_cache) {
    $filename = $filename_from_cache;
  } else {
    for my $file ($hash->files()) {
      my $detail = $file->detail();
      if (-f $detail) {
        $filename = $detail;
        $memd->set($digest, $filename);
        last;
      }
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
      my $cache_filename = "$CACHE/" . cache_file_name($digest, $size, $filename);
      if (!-f $cache_filename) {
        my $joined = $cache_filename;
        $joined =~ s:(.*/)(..)/(.*):$1$2$3:;
        if (-f $joined) {
          rename $joined, $cache_filename;
        } else {
          push @missing_sizes, $size;
        }
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

      my $cache_filename = "$CACHE/" . cache_file_name($digest, $size, $filename);

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
    my $dest_file = "$CACHE/" . cache_file_name($digest, 'full', $filename);
    unlink $dest_file;
    if (!symlink $filename, $dest_file) {
      die "couldn't symlink to $dest_file";
    }
  }

  return map {cache_file_name ($digest, $_, $filename)} @$sizes;
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

  $hash =~ s:^(..)(.*):$1/$2:;

  my $new_dir = "$CACHE/$1";

  if (!-d $new_dir) {
    mkdir $new_dir or die "can't make directory: $!\n";
  }

  my $cache_filename = $hash . "-$size.$ext";
}

1;
