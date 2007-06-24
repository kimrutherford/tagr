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
use vars qw($VERSION @ISA @EXPORT);
use Exporter;
use Digest::MD5 qw(md5);

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';
my $DATABASE_NAME = 'database';

sub new
{
  my $class = shift;
  my $self = {@_};
  die "need config_dir argument\n" if not exists $self->{config_dir};
  $self->{_db} = new File::Tagr::DB($self->{config_dir} . '/' .  $DATABASE_NAME);
  return bless $self, $class;
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

sub get_file_hash_digest
{
  my $file = shift;
  my $ctx = Digest::MD5->new;
  open my $fh, '<', $file or die "can't open $file\n";
  while (<$fh>) {
    $ctx->add($_);
  }
  return $ctx->hexdigest;
}

# sub add_tag
# {
#   my $self = shift;
#   my $file = shift;
#   my $tag = shift;
#   my $auto = shift;

#   my $hash_id = $self->db()->add_hash_tag(get_file_hash_digest($file), $tag, $auto);
#   $self->db()->add_file_tag($file, $tag, $auto);
# }

# sub add_magic
# {
#   my $self = shift;
#   my $file = shift;
#   my $magic_description = shift;
#   my $auto = shift;

#   my $magic_id = $self->db()->add_hash_magic(get_file_hash_digest($file), $magic_description, $auto);
#   $self->db()->add_file_magic($file, $magic_description, $auto);
# }

sub find_or_create_magic
{
  my $self = shift;
  my $magic_description = shift;
  return $self->db()->resultset('Magic')->find_or_create({
                                                          detail => $magic_description,
                                                         });
}

sub find_or_create_file
{
  my $self = shift;
  my $filename = shift;
  my $hash_id = shift;
  my @stats = stat($filename);
  return $self->db()->resultset('File')->find_or_create({
                                                         detail => $filename,
                                                         mdate => $stats[9],
                                                         size => $stats[7],
                                                         hash_id => $hash_id,
                                                        });
}

sub find_or_create_hash
{
  my $self = shift;
  my $digest = shift;
  my $magic_id = shift;
  return $self->db()->resultset('Hash')->find_or_create({
                                                         detail => $digest,
                                                         magic_id => $magic_id,
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

sub _make_hash
{
  my $self = shift;
  my $file = shift;
  my $hash_digest = shift;
  my $res = File::Tagr::Magic->get_magic($file->detail());
  my $magic_description = $res->{description};
  my $magic_id = $self->find_or_create_magic($magic_description);
  return $self->db()->resultset('Hash')->create({
                                                 detail => $hash_digest,
                                                 magic_id => $magic_id,
                                                });
}

sub auto_tag
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->find_file($filename);

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
        if ($file->hash()->detail() ne $hash->detail()) {
          my @old_tags = $file->hash()->tags();
          push @{$hash->tags()}, @old_tags;
          $file->hash($hash);
        }
      } else {
        $hash = $self->_make_hash($file, $hash_digest);
      }
    }
  } else {
    my $res = File::Tagr::Magic->get_magic($filename);
    my $magic_description = $res->{description};
    my $magic_id = $self->find_or_create_magic($magic_description);
    my $hash_id = $self->find_or_create_hash(get_file_hash_digest($filename),
                                             $magic_id);
    my $file_id = $self->find_or_create_file($filename, $hash_id);

#   $self->add_tag($file, $res->{category}, 1);
#   for my $tag (@{$res->{extra_tags}}) {
#     $self->add_tag($file, $tag, 1);
#   }

# TODO    $file =
  }

  return $file;
}

sub find_file_by_tag
{
  my $self = shift;
  my @tag_names = @_;

#   my @tags = ();

#   for my $tag_name (@tag_names) {
#     my $tag = $self->find_tag($tag_name);
#     if (defined $tag) {
#       push @tags, $tag;
#     } else {
#       # much match all
#       if ($self->verbose()) {
#         warn "no matches for tag list: @tag_names\n"
#       }
#       return 0;
#     }
#   }

  my @constraints = map {{'tags' => {detail => $_}}} @tag_names;

#  my @hashes = $self->db()->resultset('Hash')->search_related(@constraints);
  my @tags = $self->db()->resultset('Tag')->search(detail => 'test');

  warn scalar(@tags), "\n";

  for my $tag (@tags) {
    for my $hash ($tag->hashes()) {
      warn $hash->detail(), "\n";

      for my $file ($hash->files()) {
        print $file->detail(), "\n";
      }
    }

  }
}
