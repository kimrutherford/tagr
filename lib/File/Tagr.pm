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

sub new
{
  my $class = shift;
  my $self = {};
  return bless $self, $class;
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

sub tag_file
{
  my $self = shift;
  my $file = shift;

  print get_file_hash($file), "\n";
}
