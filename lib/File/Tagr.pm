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

sub db
{
  my $self = shift;
  return $self->{_db};
}

sub get_file_hash
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

#   my $hash_id = $self->db()->add_hash_tag(get_file_hash($file), $tag, $auto);
#   $self->db()->add_file_tag($file, $tag, $auto);
# }

# sub add_magic
# {
#   my $self = shift;
#   my $file = shift;
#   my $magic_description = shift;
#   my $auto = shift;

#   my $magic_id = $self->db()->add_hash_magic(get_file_hash($file), $magic_description, $auto);
#   $self->db()->add_file_magic($file, $magic_description, $auto);
# }

sub get_magic_id
{
  my $self = shift;
  my $magic_description = shift;
  return $self->db()->resultset('Magic')->find_or_create({
                                                          detail => $magic_description,
                                                         });
}

sub get_file_id
{
  my $self = shift;
  my $filename = shift;
  my $hash_id = shift;
  return $self->db()->resultset('File')->find_or_create({
                                                         detail => $filename,
                                                         mdate => time(),
                                                         hash_id => $hash_id,
                                                        });
}

sub get_hash_id
{
  my $self = shift;
  my $digest = shift;
  my $magic_id = shift;
  return $self->db()->resultset('Hash')->find_or_create({
                                                         detail => $digest,
                                                         magic_id => $magic_id,
                                                        });
}

sub auto_tag
{
  my $self = shift;
  my $filename = shift;

  my $res = File::Tagr::Magic->get_magic($filename);
  my $magic_description = $res->{description};
  my $magic_id = $self->get_magic_id($magic_description);
  my $hash_id = $self->get_hash_id(get_file_hash($filename), $magic_id);
  my $file_id = $self->get_file_id($filename, $hash_id);


  $self->db()->txn_commit();


#   $self->add_magic($file, );
#   $self->add_tag($file, $res->{category}, 1); 
#   for my $tag (@{$res->{extra_tags}}) {
#     $self->add_tag($file, $tag, 1); 
#   }
}

sub find_file_by_tag
{
  my $self = shift;
  my @tags = @_;

  my $sql = "select file.name from tag, file, filetag where tag.id = filetag.tag_id and file.id = filetag.file_id and tag.name = ?";

  my $sth = $self->db()->dbh()->prepare($sql)
    or die "Can't prepare SQL statement: ", $self->{_dbh}->errstr(), "\n";

  $sth->execute($tags[0])
    or die "Can't execute SQL statement: ", $sth->errstr(), "\n";

  while (my @row = $sth->fetchrow_array()) {
    print $row[0], "\n";
  }

  die "Problem in fetchrow_array(): ", $sth->errstr(), "\n" if $sth->err();
}
