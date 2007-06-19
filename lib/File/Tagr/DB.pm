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
use File::Path;

@ISA = qw( Exporter );
@EXPORT = qw( );

$VERSION = '0.01';

sub new
{
  my $class = shift;
  my $self = {@_};

  die "need database_file argument\n" if not exists $self->{database_file};

  my $db_exists = -f $self->{database_file};

  if (!($self->{_dbh} = DBI->connect( "dbi:SQLite:" . $self->{database_file}))) {
    die "Cannot connect: $DBI::errstr";
  }
  bless $self, $class;

  if (!$db_exists) {
    $self->create();
  }

  return $self;
}

sub close
{
  my $self = shift;
  $self->{_dbh}->disconnect();
}

sub create
{
  my $self = shift;
  my $file = $self->_database_file();

  my $dir = ($file =~ m:(.*)/:)[0];

  if (!-e $dir) {
    warn "making $dir\n";
    mkpath($dir);
  }

  warn "making $file\n";

  my @create_strings =
    (
     "CREATE TABLE dir ( id INTEGER PRIMARY KEY AUTOINCREMENT, name )",
     "CREATE INDEX dir_name_index ON dir ( name )",
     "CREATE TABLE file ( id INTEGER PRIMARY KEY AUTOINCREMENT, name, dir_id, hash_id )",
     "CREATE INDEX file_name_index ON file ( name )",
     "CREATE TABLE hash ( id INTEGER PRIMARY KEY AUTOINCREMENT, digest, magic_id )",
     "CREATE INDEX hash_digest_index ON hash ( digest )",
     "CREATE INDEX hash_magic_id_index ON hash ( magic_id )",
     "CREATE TABLE filetag ( id INTEGER PRIMARY KEY AUTOINCREMENT, tag_id, file_id, auto )",
     "CREATE INDEX filetag_tag_id_index ON filetag ( tag_id )",
     "CREATE INDEX filetag_file_id_index ON filetag ( file_id )",
     "CREATE TABLE hashtag ( id INTEGER PRIMARY KEY AUTOINCREMENT, tag_id, hash_id, auto )",
     "CREATE INDEX hashtag_tag_id_index ON hashtag ( tag_id )",
     "CREATE INDEX hashtag_hash_id_index ON hashtag ( hash_id )",
     "CREATE TABLE tag ( id INTEGER PRIMARY KEY AUTOINCREMENT, name )",
     "CREATE INDEX tag_name_index ON tag ( name )",
     "CREATE TABLE magic ( id INTEGER PRIMARY KEY AUTOINCREMENT, description )",
     "CREATE INDEX magic_description_index ON magic ( description )",
    );

  for my $create_string (@create_strings) {
    if ($create_string =~ /CREATE (\S+) (\S+)/) {
      $self->{_dbh}->do("DROP $1 IF EXISTS $2");
    }
  }
  for my $create_string (@create_strings) {
    $self->{_dbh}->do($create_string);
  }
}

sub _database_file
{
  my $self = shift;
  return $self->{database_file}
}


sub add_file_tag
{
  my $self = shift;
  my $file = shift;
  my $tag = shift;
  my $auto = shift;

  my $tag_id = $self->_get_tag_id($tag);
  my $file_id = $self->_get_file_id($file);

  $self->{_dbh}->do(<<"EOF");
INSERT INTO filetag (tag_id, file_id, auto) VALUES ($tag_id, $file_id, $auto)
EOF
}

sub add_hash_tag
{
  my $self = shift;
  my $hash = shift;
  my $tag = shift;
  my $auto = shift;

  my $tag_id = $self->_get_tag_id($tag);
  my $hash_id = $self->_get_hash_id($hash);

  $self->{_dbh}->do(<<"EOF");
INSERT INTO hashtag (tag_id, hash_id, auto) VALUES ($tag_id, $hash_id, $auto)
EOF
}

sub _get_or_create
{
  my $self = shift;
  my $table = shift;
  my $constrain_column_name = shift;
  my $new_value = shift;

  my $sth = $self->{_dbh}->prepare("SELECT id FROM $table WHERE $constrain_column_name = ?")
    or die "Can't prepare SQL statement: ", $self->{_dbh}->errstr(), "\n";

  $sth->execute($new_value)
    or die "Can't execute SQL statement: ", $sth->errstr(), "\n";

  my @row = $sth->fetchrow_array();
    die "Problem in fetchrow_array(): ", $sth->errstr(), "\n" if $sth->err();

  if (@row) {
    return $row[0];
  } else {
    $sth = $self->{_dbh}->prepare("INSERT INTO $table ($constrain_column_name) VALUES (?)");
    $sth->execute($new_value)
      or die "Can't execute SQL statement: ", $sth->errstr(), "\n";
    return $self->_get_or_create($table, $constrain_column_name, $new_value);
  }
}

sub _get_tag_id
{
  my $self = shift;
  my $tag_name = shift;
  return $self->_get_or_create('tag', 'name', $tag_name);
}

sub _get_file_id
{
  my $self = shift;
  my $file_name = shift;
  return $self->_get_or_create('file', 'name', $file_name);
}

sub _get_hash_id
{
  my $self = shift;
  my $hash_digest = shift;
  return $self->_get_or_create('hash', 'digest', $hash_digest);
}

sub dbh
{
  my $self = shift;
  return $self->{_dbh};
}
