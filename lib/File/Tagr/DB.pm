package File::Tagr::DB;

=head1 NAME

File::Tagr:: - tag storage and retrieval for tagr

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
use File::Path;

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

sub create {
  my $class = shift;
  my $file = shift;

  my $dir = ($file =~ m:(.*)/:)[0];
  mkpath($dir);

  warn "making $dir\n";
  my $dbh = DBI->connect( "dbi:SQLite:$file" ) || die "Cannot connect: $DBI::errstr";

  $dbh->do( "DROP TABLE IF EXISTS dir" );
  $dbh->do( "DROP INDEX IF EXISTS dir_name_index" );
  $dbh->do( "DROP TABLE IF EXISTS file" );
  $dbh->do( "DROP INDEX IF EXISTS file_name_index" );
  $dbh->do( "DROP TABLE IF EXISTS hash" );
  $dbh->do( "DROP INDEX IF EXISTS hash_digest_index" );

  $dbh->do( "CREATE TABLE dir ( id INTEGER PRIMARY KEY AUTOINCREMENT, name )" );
  $dbh->do( "CREATE INDEX dir_name_index ON dir ( name )" );
  $dbh->do( "CREATE TABLE file ( id INTEGER PRIMARY KEY AUTOINCREMENT, name, dir_id, hash_id )" );
  $dbh->do( "CREATE INDEX file_name_index ON file ( name )" );
  $dbh->do( "CREATE TABLE hash ( id INTEGER PRIMARY KEY AUTOINCREMENT, digest )" );
  $dbh->do( "CREATE INDEX hash_digest_index ON hash ( digest )" );
  

  $dbh->disconnect;
}
