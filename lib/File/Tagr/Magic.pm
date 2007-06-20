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

  my @extra_tags = ();

  if ($desc =~ /^gzip compressed data/) {
    open GZIP, "gzip -d < $file |" or die "can't open pipe to gzip\n";

    my $data;
    read GZIP, $data, 1000;
    $desc = $flm->describe_contents($data);
    push @extra_tags, "gzip";
    push @extra_tags, "gz";

    close GZIP;
  }

  my @test_re_confs = (
                       [qr'(.*) shell script' , 'script'],
                       [qr'(.*) script text' , 'script'],
                       [qr'(.*) image data' , 'image'],
                       [qr'ASCII (.*) program text' , 'source'],
                       [qr'ASCII text' , 'text'],
                       [qr'ASCII (.*) text' , 'text'],
                       [qr'executable' , 'executable'],
                       [qr'^(\S+)$' , undef],
                      );

  for my $re_conf (@test_re_confs) {
    my ($re, $category) = @$re_conf;
    my @matches;
    if (@matches = ($desc =~ m/$re/)) {
      if (!defined $category) {
        $category = lc $desc;
      }

      push @extra_tags, @matches;

      map { $_ = lc $_ } @extra_tags;
      return {
              description => $desc,
              category => lc $category,
              extra_tags => [@extra_tags],
             };
    }
  }

  return {
          description => $desc,
          category => 'misc',
          extra_tags => [@extra_tags],
         };
}
