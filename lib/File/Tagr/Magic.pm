package File::Tagr::Magic;

=head1 NAME

File::Tagr::Magic - interaction with File::LibMagic

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
use File::LibMagic;

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

my $flm;

BEGIN {
  $flm = File::LibMagic->new();
}

sub get_magic {
  my $class = shift;
  my $file = shift;

  my $desc = $flm->describe_filename($file);

  my @test_re_confs = (
                       [qr'(.*) shell script' , 'script'],
                       [qr'(.*) script text' , 'script'],
                       [qr'(.*) image data' , 'image'],
                       [qr'executable' , 'executable'],
                       [qr'' , 'misc'],
                      );

  for my $re_conf (@test_re_confs) {
    my ($re, $category) = @$re_conf;
    my @matches;
    if (@matches = ($desc =~ m/$re/)) {
      map { $_ = lc $_ } @matches;
      return {
              description => $desc,
              category => lc $category,
              extra_tags => [@matches],
             };
    }
  }
}
