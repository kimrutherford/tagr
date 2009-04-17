package File::Tagr::DB;

=head1 NAME

File::Tagr::DB - tag storage and retrieval for tagr

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
use DBI;

use base qw/DBIx::Class::Schema/;

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

sub _get_connect_args
{
  my $file = shift;

#  return ("dbi:SQLite:" . $file, "", "", {RaiseError => 1, AutoCommit => 1 })

  return ('dbi:Pg:dbname=kmr-files;host=hydrogen', 'kmr44', '',
          {RaiseError => 1, AutoCommit => 0 });
}

sub create
{
  my $class = shift;
  my $file = shift;

  my $dir = ($file =~ m:(.*)/:)[0];

  if (!-e $dir) {
    warn "making $dir\n";
    mkpath($dir);
  }

  warn "making $file\n";

  my $ID_DEF = 'id SERIAL PRIMARY KEY';
  my $DETAIL_DEF = 'detail TEXT NOT NULL UNIQUE';
  my @create_strings =
    (
     "CREATE TABLE magic ( $ID_DEF, $DETAIL_DEF )",
     "CREATE TABLE description ( $ID_DEF, $DETAIL_DEF )",
     "CREATE TABLE hash ( $ID_DEF, $DETAIL_DEF, magic_id INTEGER NOT NULL REFERENCES magic(id), description_id INTEGER REFERENCES description(id), creation_timestamp timestamp without time zone)",
     "CREATE INDEX hash_magic_id_index ON hash ( magic_id )",
     "CREATE TABLE file ($ID_DEF, $DETAIL_DEF, mdate INTEGER NOT NULL, size INTEGER NOT NULL, hash_id INTEGER NOT NULL REFERENCES hash(id))",
     "CREATE INDEX file_hash_id_index ON file ( hash_id )",
     "CREATE TABLE tag ( $ID_DEF, $DETAIL_DEF )",
     "CREATE INDEX tag_detail_key ON tag(detail)",
     "CREATE INDEX tag_detail_key_text_pattern_ops ON tag(detail text_pattern_ops)",
     "CREATE TABLE hashtag ( tag_id INTEGER NOT NULL REFERENCES tag(id), hash_id INTEGER NOT NULL REFERENCES hash(id), auto BOOLEAN NOT NULL, PRIMARY KEY (tag_id, hash_id) ) ",
     "CREATE INDEX hashtag_tag_id_index ON hashtag ( tag_id )",
     "CREATE INDEX hashtag_hash_id_index ON hashtag ( hash_id )",
     "CREATE INDEX hash_creation_year_index ON hash ( EXTRACT (YEAR FROM creation_timestamp) )", 
     "CREATE INDEX hash_creation_month_index ON hash ( EXTRACT (MONTH FROM creation_timestamp) )", 
     "CREATE INDEX hash_creation_day_index ON hash ( EXTRACT (DAY FROM creation_timestamp) )", 
    );

  my @connect_args = _get_connect_args($file);

  my $dbh;
  if (!($dbh = DBI->connect( @connect_args ))) {
    die "Cannot connect: $DBI::errstr";
  }

#   for my $create_string (@create_strings) {
#     if ($create_string =~ /CREATE (\S+) (\S+)/) {
#       warn "dropping: $create_string\n";
#       $dbh->do("DROP $1 $2");
#     }
#   }

  for my $create_string (@create_strings) {
    warn "$create_string\n";
    $dbh->do($create_string);
  }
  $dbh->commit();
}
