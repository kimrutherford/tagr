package File::Tagr;

=head1 NAME

File::Tagr - flexibly tag files and their contents

=head1 SYNOPSIS

=head1 DESCRIPTION

=cut

=head1 FUNCTIONS

=cut

use warnings;
use strict;
use Carp;
use vars qw($VERSION $THUMB_SIZE $BIG_IMAGE_SIZE $CONFIG_DIR @ISA @EXPORT);
use Exporter;
use Digest::MD5 qw(md5);
use List::Compare;
use File::Tagr::DB;
use File::Tagr::Cache;

@ISA = qw( Exporter );
@EXPORT = qw( );

BEGIN {
  $VERSION = '0.01';
  $THUMB_SIZE = '96x96';
  $BIG_IMAGE_SIZE = '640x480';
  $CONFIG_DIR = "/home/kmr/.tagr";
}

my $DATABASE_NAME = 'database';

sub new
{
  my $class = shift;
  my $self = {@_};
  die "need config_dir argument\n" if not exists $self->{config_dir};
  $self->{_db} = new File::Tagr::DB($self->{config_dir} . '/' .  $DATABASE_NAME);
  return bless $self, $class;
}

sub config_dir
{
  return $CONFIG_DIR;
}

sub verbose
{
  my $self = shift;
  return 1 if defined $self->{verbose} && $self->{verbose};
}

sub db
{
  my $self = shift;
  return $self->{_db};
}

my %filename_hash_cache = ();

sub get_file_hash_digest
{
  my $filename = shift;

  if (exists $filename_hash_cache{$filename}) {
    return $filename_hash_cache{$filename};
  }

  my $ctx = Digest::MD5->new;
  open my $fh, '<', $filename or die "can't open $filename\n";
  while (<$fh>) {
    $ctx->add($_);
  }

  my $digest = $ctx->hexdigest;
  $filename_hash_cache{$filename} = $digest;
  return $digest;
}

sub find_or_create_magic
{
  my $self = shift;
  my $magic_description = shift;
  return $self->db()->resultset('Magic')->find_or_create({
                                                          detail => $magic_description,
                                                         });
}

sub find_file
{
  my $self = shift;
  my $filename = shift;
  my $hash_id = shift;

  my $file = $self->db()->resultset('File')->find({
                                                   detail => $filename,
                                                  });

  if (defined $file) {
    my @stats = stat($filename);
    my $mdate = $stats[9];
    my $size = $stats[7];

    if ($file->mdate() != $mdate || $file->size() != $size) {
      $file->mdate($mdate);
      $file->size($size);
      my $hash_digest = get_file_hash_digest($filename);
      my $hash = $self->find_hash($hash_digest);
      if (defined $hash) {
        if ($file->hash_id()->detail() ne $hash->detail()) {
          my @old_tags = $file->hash_id()->tags();

          for my $old_tag (@old_tags) {
            if ($self->verbose()) {
              warn "re-attched tag '" . $old_tag->detail() . "' to $filename\n";
            }
            $self->add_tag_to_hash($hash, $old_tag->detail(), $old_tag->auto());
          }
          $file->hash_id($hash);
          $file->update();
        }
      } else {
        $hash = $self->create_hash($file);
        $file->hash_id($hash);
        $file->update();
      }
    }
  }

  return $file;
}

sub create_file
{
  my $self = shift;
  my $filename = shift;
  my $hash_digest = get_file_hash_digest($filename);
  my $hash_id = $self->find_hash($hash_digest);

  if (!defined $hash_id) {
    $hash_id = $self->create_hash($filename);
  }

  if ($self->verbose()) {
    warn "automatically adding tags to $filename\n";
  }

  my @stats = stat($filename);
  my $file = $self->db()->resultset('File')->create({
                                                     detail => $filename,
                                                     mdate => $stats[9],
                                                     size => $stats[7],
                                                     hash_id => $hash_id,
                                                    });
  $file->update;
}


sub create_hash
{
  my $self = shift;
  my $filename = shift;
  my $digest = get_file_hash_digest($filename);
  my $res = File::Tagr::Magic->get_magic($filename, $self->verbose());
  my $magic_description = $res->{description};
  my $magic_id = $self->find_or_create_magic($magic_description);
  my $hash = $self->db()->resultset('Hash')->create({
                                                     detail => $digest,
                                                     magic_id => $magic_id,
                                                    });

  # do auto-tagging
  $self->add_tag_to_hash($hash, $res->{category}, 1);

  for my $tag (@{$res->{extra_tags}}) {
    $self->add_tag_to_hash($hash, $tag, 1);
  }

  return $hash;
}

sub find_or_create_tag
{
  my $self = shift;
  my $name = shift;
  my $auto = shift;
  return $self->db()->resultset('Tag')->find_or_create({
                                                        detail => $name,
                                                       });
}


sub find_tag
{
  my $self = shift;
  my $name = shift;
  return $self->db()->resultset('Tag')->find({
                                              detail => $name,
                                             });
}

sub find_hash
{
  my $self = shift;
  my $digest = shift;
  return $self->db()->resultset('Hash')->find({
                                               detail => $digest,
                                              });
}

sub find_or_create_description
{
  my $self = shift;
  my $text = shift;
  return $self->db()->resultset('Description')->find_or_create({
                                                                detail => $text,
                                                               });
}

sub auto_tag
{
#   my $self = shift;
#   my $filename = shift;

#   my $file = $self->find_file($filename);

#   if (!defined $file) {
#     $file = $self->create_file($filename);
#   }

#   my $hash = $file->hash_id();
#   my $magic = $hash->magic_id();

#   return $file;
}

sub add_tag_to_hash
{
  my $self = shift;
  my $hash = shift;
  my $tag_string = lc shift;
  my $auto = shift;

  die "auto not set" if not defined $auto;

  die if $tag_string eq '1';

  my $tag = $self->find_or_create_tag($tag_string);

  my @tags = $hash->tags();
  if (!grep { $_->detail() eq $tag->detail()} @tags) {
    $hash->add_to_tags($tag, {auto => $auto});
  }
}

sub tag_file
{
  my $self = shift;
  my $filename = shift;
  my $auto = shift;
  my @tag_strings = @_;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my $hash = $file->hash_id();

  for my $tag_string (@tag_strings) {
    $self->add_tag_to_hash($hash, $tag_string, $auto);
  }

  return $file;
}

sub describe_file
{
  my $self = shift;
  my $filename = shift;
  my $description_details = shift;

  $description_details =~ s/^\s+//;
  $description_details =~ s/\s+$//;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my $hash = $file->hash_id();

  my $description = $self->find_or_create_description($description_details);

  $hash->description_id($description);
  $hash->update();

  return $file;
}

sub update_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my @tags = $self->get_tags_of_file($filename);

  if (grep {$_->detail() eq 'image'} @tags) {
    File::Tagr::Cache->get_image_from_cache($file->hash_id()->detail(), 
                                            $file->detail(), [$THUMB_SIZE]);

    File::Tagr::Cache->get_image_from_cache($file->hash_id()->detail(), 
                                            $file->detail(), [$BIG_IMAGE_SIZE]);

  }

  return $file;
}

sub find_file_by_tag
{
  my $self = shift;
  my @tag_names = @_;

  my @constraints = map {{detail => $_}} @tag_names;
  my @tags = $self->db()->resultset('Tag')->search([@constraints]);
  my @filename_lists = map {[map {$_->detail()} map {$_->files()} $_->hashes()]} @tags;


  if (@filename_lists == 1) {
    return @{$filename_lists[0]};
  } else {
    if (@filename_lists == 0) {
      return ();
    } else {
      my $lcm = List::Compare->new( {
                                     lists    => \@filename_lists,
                                    } );

      return $lcm->get_intersection();
    }
  }
}

sub find_file_by_hash
{
  my $self = shift;
  my $hash_digest = shift;

  my @hashes = $self->db()->resultset('Hash')->search({detail => $hash_digest});
  return map {$_->detail()} map {$_->files()} @hashes;
}

# find files with the same hash as the given file
sub find_file_by_file_hash
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file && defined $file->hash_id()) {
    return $self->find_file_by_hash($file->hash_id()->detail());
  } else {
    return ();
  }
}

sub get_tag_names
{
  my $self = shift;

  my @tags = $self->db()->resultset('Tag')->all();

  return map {$_->detail()} @tags;
}

sub get_tags_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file && defined $file->hash_id()) {
    return $file->hash_id()->tags();
  } else {
    return ();
  }
}

sub get_description_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file) {
    return $file->hash_id()->description_id();
  }

  return undef;
}

sub get_hash_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file) {
    return $file->hash_id();
  }

  return undef;
}

1;
