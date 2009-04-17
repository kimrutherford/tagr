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
use vars qw($VERSION @ISA @EXPORT);
use Exporter;

use Image::Magick;
use File::Path;

use File::Tagr;


@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

use Cache::Memcached;

my %cache = ();

sub new
{
  my $class = shift;
  my $self = {@_};
  my $cache_dir = $self->{config_dir} . '/cache';
  $self->{cache_dir} = $cache_dir;
  return bless $self, $class;
}

sub cache_dir
{
  my $self = shift;
  return $self->{cache_dir};
}

sub get_image_from_cache
{
  my $self = shift;
  my $hash = shift;
  my $sizes = shift;

  if (!-d $self->cache_dir()) {
    eval { mkpath($self->cache_dir()) };
    if ($@) {
      print "Couldn't create ". $self->cache_dir(), ": $@";
    }
  }

  my $filename = undef;
  my $digest = $hash->detail();
  my $tagr = $self->{tagr};
  my $memd = $tagr->get_memchached();

  my $key = "hashfilename:$digest";

  my $filename_from_cache = $memd->get($key);

  if (defined $filename_from_cache) {
    $filename = $filename_from_cache;
  } else {
    for my $file ($hash->files()) {
      my $detail = $file->detail();
      if (-f $detail) {
        $filename = $detail;
        $memd->set($key, $filename);
        last;
      }
    }
  }

  if (!defined $filename) {
    return undef;
  }

  my $orig_filename = $filename;

  my @missing_sizes = ();
  my $make_full = 0;

  my $pid = "$$";

  my $is_video = $self->is_video($hash);

  if ($is_video) {
    $filename = "/tmp/tagr_video_branded_${pid}.jpg";
  }

  for my $size (@$sizes) {
    if ($size eq 'full') {
      $make_full = 1;
    } else {
      my $cache_filename = $self->cache_dir() . '/' . $self->cache_file_name($digest, $size, $filename, $orig_filename);

      if (!-f $cache_filename || (stat $orig_filename)[9] > (stat $cache_filename)[9]) {
        push @missing_sizes, $size;
      }
    }
  }

  if (@missing_sizes) {
    if ($is_video) {
      my $dest_file = "/tmp/tagr_video_${pid}_001.jpg";
      unlink $dest_file;

      my $sys_filename = $orig_filename;

      $sys_filename =~ s/\'/\\'/;

      system "cd /tmp; ffmpeg -vframes 1 -i $sys_filename 'tagr_video_${pid}_%03d.jpg'"; # == 0 or die "system() failed: $?";
      my $frame_filename = "$dest_file";

      my $frame_image = Image::Magick->new;
      my $ret_code = $frame_image->Read($frame_filename);

      die $ret_code if $ret_code;

      $filename = "/tmp/tagr_video_branded_${pid}.jpg";

      my $video_icon = $self->{config_dir} . '/tagr_trunk/root/images/video_icon.png';
      my $im_vid = Image::Magick->new;
      my $im_vid_ret = $im_vid->Read($video_icon);

      die $im_vid_ret if $im_vid_ret;

      $frame_image->Composite(image=>$im_vid, compose=>'over');

      $frame_image->Write($filename);
    }

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

      my $cache_filename = $self->cache_dir() . '/' . $self->cache_file_name($digest, $size, $filename, $orig_filename);

      $ret_code = $image->Thumbnail(geometry=>$size);
      if ($ret_code) {
        warn "$ret_code";
        return undef;
      }

      $ret_code = $image->Set(quality => 80);
      if ($ret_code) {
        warn "$ret_code";
        return undef;
      }
      $ret_code = $image->Write($cache_filename);
    }
  }

  if ($make_full) {
    my $dest_file = $self->cache_dir() . '/' . $self->cache_file_name($digest, 'full', $filename, $orig_filename);
    unlink $dest_file;
    if (!symlink $orig_filename, $dest_file) {
      die "couldn't symlink to $dest_file";
    }
  }

  return map {$self->cache_file_name ($digest, $_, $filename, $orig_filename)} @$sizes;
}

sub is_video
{
  my $self = shift;
  my $hash = shift;

  if ($self->{tagr}->hash_has_tag($hash, 'video')) {
    return 1;
  } else {
    return 0;
  }
}

sub cache_file_name
{
  my $self = shift;
  my $hash = shift;
  my $size = shift;
  my $filename = shift;
  my $orig_filename = shift;
  my $ext = 'jpg';

  if ($size eq 'full') {
    if ($orig_filename =~ /.*\.(.*)$/) {
      $ext = lc $1;
    }
  } else {
    if ($filename =~ /.*\.(.*)$/) {
      $ext = lc $1;
    }
  }

  $hash =~ s:^(..)(.*):$1/$2:;

  my $new_dir = $self->cache_dir() . "/$1";

  if (!-d $new_dir) {
    mkdir $new_dir or die "can't make directory: $!\n";
  }

  my $cache_filename = $hash . "-$size.$ext";

  return $cache_filename;
}

1;
