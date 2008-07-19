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
    open GZIP, qq[gzip -d < "$file" |] or die "can't open pipe to gzip\n";

    my $data;
    read GZIP, $data, 1000;
    $desc = $flm->describe_contents($data);
    push @extra_tags, "gzip";
    push @extra_tags, "gz";

    close GZIP;
  }

  my @test_re_confs = (
                       [qr'Netpbm PPM "(.*)" image data' , 'ppm', 'image'],
                       [qr'^(\S+) shell script' , 'script', 'source'],
                       [qr'^(\S+) script text' , 'script', 'source'],
                       [qr'^(\S+) image data' , 'image'],
                       [qr'^MPEG sequence' , 'video'],
                       [qr'^Microsoft ASF' , 'video'],
                       [qr'^(\S+) document text' , 'document'],
                       [qr'^(\S+) (\S+) program text' , 'source'],
                       [qr'Microsoft Office Document' , 'office', 'microsoft', 'document'],
                       [qr'^(\S+) document' , 'document'],
                       [qr'^(\S+) (\S+) text' , 'text'],
                       [qr'(ASCII) text' , 'text'],
                       [qr'(executable)' , 'executable'],
                       [qr'^(\S+) (\S+) (\S+) Language data', 'source'],
                       [qr'^(\S+) (\S+) Language data', 'source'],
                       [qr'^(\S+) Language data', 'source'],
                       [qr'^(\S+)$'],
                      );

  for my $re_conf (@test_re_confs) {
    my ($re, @categories) = @$re_conf;
    my @matches;
    if (@matches = ($desc =~ m/$re/)) {
      my $category;

      if (@categories) {
        $category = $categories[0];
        push @extra_tags, @categories[1..$#categories];
      } else {
        $category = lc $desc;
      }

      if (@matches > 1 || $matches[0] ne "1") {
        # match returns 1 if there are no captures in the re
        push @extra_tags, @matches;
      }

      map { $_ = lc $_ } @extra_tags;

      $category = lc $category;

      if ($category eq 'data' && $file =~ /(\.mov|\.avi|\.mpe?g)$/i) { 
        $category = 'video';
        $desc = 'video';
      }

      return {
              description => $desc,
              category => $category,
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
