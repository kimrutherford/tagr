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
  $self->{_db} = new File::Tagr::DB(database_file => $self->{config_dir} . '/' .  $DATABASE_NAME);
  return bless $self, $class;
}

sub _get_db
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

sub add_tag
{
  my $self = shift;
  my $file = shift;
  my $tag = shift;
  my $auto = shift;

  $self->_get_db()->add_file_tag($file, $tag, $auto);
  $self->_get_db()->add_hash_tag(get_file_hash($file), $tag, $auto);
}

sub auto_tag
{
  my $self = shift;
  my $file = shift;

  my $res = File::Tagr::Magic->get_magic($file);
  $self->add_tag($file, $res->{category}, 1); 
  for my $tag (@{$res->{extra_tags}}) {
    $self->add_tag($file, $tag, 1); 
  }
}
