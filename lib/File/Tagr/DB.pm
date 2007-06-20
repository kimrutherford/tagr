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

use DBIx::Class::Schema::Loader qw/make_schema_at/;

sub new
{
  my $class = shift;
  my $database_file = shift;

  die "need database_file argument\n" if not defined $database_file;

  die "database not found: " . $database_file . "\n"  if (!-f $database_file);

  my @connect_args = ("dbi:SQLite:" . $database_file, "", "",
                      {RaiseError => 1, AutoCommit => 1 });

  make_schema_at(
                 'File::Tagr::DB',
                 {
                  debug => 0
                 },
                 [ $connect_args[0],'sqlite' ],
                );

  my $this;
  if (!($this = File::Tagr::DB->connect( @connect_args ))) {
    die "Cannot connect: $DBI::errstr";
  }

  return $this;
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

  my @create_strings =
    (
     "CREATE TABLE file ( id INTEGER PRIMARY KEY AUTOINCREMENT, detail TEXT NOT NULL, mdate, hash_id INTEGER NOT NULL REFERENCES hash(id) )",
     "CREATE INDEX file_detail_index ON file ( detail )",
     "CREATE INDEX file_hash_id_index ON file ( hash_id )",
     "CREATE TABLE hash ( id INTEGER PRIMARY KEY AUTOINCREMENT, detail TEXT NOT NULL, magic_id INTEGER NOT NULL REFERENCES magic(id))",
     "CREATE INDEX hash_detail_index ON hash ( detail )",
     "CREATE INDEX hash_magic_id_index ON hash ( magic_id )",
     "CREATE TABLE tag ( id INTEGER PRIMARY KEY AUTOINCREMENT, detail TEXT NOT NULL )",
     "CREATE INDEX tag_detail_index ON tag ( detail )",
     "CREATE TABLE magic ( id INTEGER PRIMARY KEY AUTOINCREMENT, detail TEXT NOT NULL )",
     "CREATE INDEX magic_detail_index ON magic ( detail )",
     "CREATE TABLE hashtag ( tag_id INTEGER NOT NULL REFERENCES hash(id), hash_id INTEGER NOT NULL REFERENCES hash(id), auto )",
     "CREATE INDEX hashtag_tag_id_index ON hashtag ( tag_id )",
     "CREATE INDEX hashtag_hash_id_index ON hashtag ( hash_id )",
    );

  my @connect_args = ("dbi:SQLite:" . $file, "", "",
                      {RaiseError => 1, AutoCommit => 0 });

  my $dbh;
  if (!($dbh = DBI->connect( @connect_args ))) {
    die "Cannot connect: $DBI::errstr";
  }

  for my $create_string (@create_strings) {
    if ($create_string =~ /CREATE (\S+) (\S+)/) {
      $dbh->do("DROP $1 IF EXISTS $2");
    }
  }
  for my $create_string (@create_strings) {
    $dbh->do($create_string);
  }
  $dbh->commit();
}

# sub _database_file
# {
#   my $self = shift;
#   return $self->{database_file}
# }
# 
# sub get_file_id
# {
#   my $self = shift;
#   my $file = shift;
#   return get_id('file', $file, 'detail')
# }
# 
# 
# sub add_hash_tag
# {
#   my $self = shift;
#   my $hash = shift;
#   my $tag = shift;
#   my $auto = shift;
# 
#   my $tag_id = $self->_get_tag_id($tag);
#   my $hash_id = $self->_get_hash_id($hash);
# 
#   $self->{_dbh}->do(<<"EOF");
# INSERT INTO hashtag (tag_id, hash_id, auto) VALUES ($tag_id, $hash_id, $auto)
# EOF
# }
# 
# sub add_hash_magic
# {
#   my $self = shift;
#   my $hash = shift;
#   my $magic = shift;
# 
#   my $magic_id = $self->_get_magic_id($magic);
#   my $hash_id = $self->_get_hash_id($hash);
# 
#   $self->{_dbh}->do(<<"EOF");
# INSERT INTO hashmagic (magic_id, hash_id) VALUES ($magic_id, $hash_id)
# EOF
# }
# 
# sub _get_id
# {
#   my $self = shift;
#   my $table = shift;
#   my $constrain_column_name = shift;
#   my $new_value = shift;
# 
#   my $sth = $self->{_dbh}->prepare("SELECT id FROM $table WHERE $constrain_column_name = ?")
#     or die "Can't prepare SQL statement: ", $self->{_dbh}->errstr(), "\n";
# 
#   $sth->execute($new_value)
#     or die "Can't execute SQL statement: ", $sth->errstr(), "\n";
# 
#   my @row = $sth->fetchrow_array();
#   die "Problem in fetchrow_array(): ", $sth->errstr(), "\n" if $sth->err();
# 
#   if (@row) {
#     return $row[0];
#   } else {
#     return undef;
#   }
# }
# 
# sub _get_or_create
# {
#   my $self = shift;
#   my $table = shift;
#   my $constrain_column_name = shift;
#   my $new_value = shift;
# 
#   my @row = $self->_get_id($table, $constrain_column_name, $new_value);
# 
#   if (@row) {
#     return $row[0];
#   } else {
#     $sth = $self->{_dbh}->prepare("INSERT INTO $table ($constrain_column_name) VALUES (?)");
#     $sth->execute($new_value)
#       or die "Can't execute SQL statement: ", $sth->errstr(), "\n";
#     return $self->_get_or_create($table, $constrain_column_name, $new_value);
#   }
# }
# 
# sub _get_tag_id
# {
#   my $self = shift;
#   my $tag_name = shift;
#   return $self->_get_or_create('tag', $tag_name);
# }
# 
# sub _get_file_id
# {
#   my $self = shift;
#   my $file_name = shift;
#   return $self->_get_or_create('file', $file_name);
# }
# 
# sub _get_hash_id
# {
#   my $self = shift;
#   my $hash_digest = shift;
#   return $self->_get_or_create('hash', $hash_digest);
# }
# 
# sub _get_magic_id
# {
#   my $self = shift;
#   my $magic_detail = shift;
#   return $self->_get_or_create('magic', $magic_description);
# }
# 
sub dbh
{
  my $self = shift;
  return $self->{_dbh};
}
