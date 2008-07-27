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
use vars qw($VERSION $THUMB_SIZE $BIG_IMAGE_SIZE $CONFIG_DIR @ISA @EXPORT);
use Exporter;
use Digest::MD5 qw(md5);
use List::Compare;
use File::Tagr::DB;
use File::Tagr::Cache;
use Tie::IxHash;
use Image::ExifTool qw(ImageInfo);
use Date::Parse;
use POSIX qw(strftime);

@ISA = qw( Exporter );
@EXPORT = qw( config_dir );

BEGIN {
  $VERSION = '0.01';
  $THUMB_SIZE = '96x96';
  $BIG_IMAGE_SIZE = '640x480';
  $CONFIG_DIR = "/home/kmr/.tagr";
}

my $DATABASE_NAME = 'database';

sub new
{
  my $class = shift;
  my $self = {@_};
  die "need config_dir argument\n" if not exists $self->{config_dir};
  my $cache = new File::Tagr::Cache(config_dir => $self->{config_dir},
                                    tagr => $self);
  $self->{_cache} = $cache;
  $self->{_db} = new File::Tagr::DB($self->{config_dir} . '/' .  $DATABASE_NAME);
  my $memd = new Cache::Memcached(
                                  {
                                   servers => [ 'bob:11211' ],
                                   namespace => 'tagr:',
                                   connect_timeout => 1.9,
                                   max_failures => 10,
                                   failure_timeout => 2,
                                   nowait => 1
                                  });

  $self->{_memd} = $memd;
  return bless $self, $class;
}

sub config_dir
{
  return $CONFIG_DIR;
}

sub get_cache
{
  my $self = shift;
  return $self->{_cache};
}

sub verbose
{
  my $self = shift;
  return 1 if defined $self->{verbose} && $self->{verbose};
}

sub db
{
  my $self = shift;
  return $self->{_db};
}

my %filename_hash_cache = ();

sub get_file_hash_digest
{
  my $filename = shift;

  if (exists $filename_hash_cache{$filename}) {
    return $filename_hash_cache{$filename};
  }

  local $/;  # slurp

  my $ctx = Digest::MD5->new;
  open my $fh, '<', $filename or die "can't open $filename\n";
  while (<$fh>) {
    $ctx->add($_);
  }

  my $digest = $ctx->hexdigest;
  $filename_hash_cache{$filename} = $digest;
  return $digest;
}

sub find_or_create_magic
{
  my $self = shift;
  my $magic_description = shift;
  return $self->db()->resultset('Magic')->find_or_create({
                                                          detail => $magic_description,
                                                         });
}

sub find_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({
                                                   detail => $filename,
                                                  });

  if (defined $file) {
    my @stats = stat($filename);
    my $mdate = $stats[9];
    my $size = $stats[7];

    if ($file->mdate() != $mdate || $file->size() != $size) {
      if ($self->verbose()) {
        warn "file exists but size or date has changed: $filename\n";
      }
      $file->mdate($mdate);
      $file->size($size);
      $file->update();
      my $hash_digest = get_file_hash_digest($filename);
      my $hash = $self->find_hash($hash_digest);
      if (defined $hash) {
        if ($file->hash_id()->detail() ne $hash->detail()) {
          my $hash = $file->hash_id();
          my @old_hashtags = $hash->hashtags();

          for my $old_hashtag (@old_hashtags) {
            my $tag = $old_hashtag->tag_id();
            if ($self->verbose()) {
              warn "re-attched tag '" . $tag->detail() . "' to $filename\n";
            }
            $self->add_tag_to_hash($hash, $tag->detail(), $old_hashtag->auto());
          }
          $file->hash_id($hash);
          $file->update();
        }
      } else {
        $hash = $self->create_hash($file->detail());
        $file->hash_id($hash);
        $file->update();
      }
    } else {
      my $hash = $file->hash_id();

      $self->update_auto_tags($file);

      if (defined $hash->creation_timestamp()) {
        if ($self->verbose()) {
          warn "not updating timestamp on file that hasn't changed: $filename\n";
        }
      } else {
        my $creation_timestamp = get_creation_date($filename);
        if (defined $creation_timestamp) {
          $hash->creation_timestamp($creation_timestamp);
          $hash->update();
          if ($self->verbose()) {
            warn "file hasn't changed: $filename but needs creation_timestamp: $creation_timestamp\n";
          }
        }
      }
    }
  }

  return $file;
}

sub update_auto_tags
{
  my $self = shift;
  my $file = shift;
  my $filename = $file->detail();
  my $hash = $file->hash_id();

  my $res = File::Tagr::Magic->get_magic($filename, $self->verbose());

  # do auto-tagging
  $self->add_tag_to_hash($hash, $res->{category}, 1);

  for my $tag (@{$res->{extra_tags}}) {
    $self->add_tag_to_hash($hash, $tag, 1);
  }
}

sub create_file
{
  my $self = shift;
  my $filename = shift;
  my $hash_digest = get_file_hash_digest($filename);
  my $hash_id = $self->find_hash($hash_digest);

  if (!defined $hash_id) {
    $hash_id = $self->create_hash($filename);
  }

  if (!defined $hash_id->creation_timestamp()) {
    if ($self->verbose()) {
      warn "updating creation_timestamp of $filename\n";
    }
    $hash_id->creation_timestamp(get_creation_date($filename));
    $hash_id->update();
  }

  if ($self->verbose()) {
    warn "automatically adding tags to $filename\n";
  }

  my @stats = stat($filename);
  my $file = $self->db()->resultset('File')->create({
                                                     detail => $filename,
                                                     mdate => $stats[9],
                                                     size => $stats[7],
                                                     hash_id => $hash_id,
                                                    });
  $file->update;
}

my $exifTool = new Image::ExifTool();

sub get_creation_date
{
  my $filename = shift;

  my %info = %{$exifTool->ImageInfo($filename)};
  my $date_str = $info{'CreateDate'};

  if (defined $date_str) {
    my @bits = gmtime str2time($date_str);
    return strftime ("%F %H:%M:%S", @bits);
  } else {
    return undef;
  }
}

sub create_hash
{
  my $self = shift;
  my $filename = shift;
  my $digest = get_file_hash_digest($filename);
  my $res = File::Tagr::Magic->get_magic($filename, $self->verbose());
  my $magic_description = $res->{description};
  my $magic_id = $self->find_or_create_magic($magic_description);

  my $creation_date = get_creation_date($filename);

  print $creation_date, "\n";

  my $hash = $self->db()->resultset('Hash')->create({
                                                     detail => $digest,
                                                     magic_id => $magic_id,
                                                     creation_timestamp => $creation_date
                                                    });

  # do auto-tagging
  $self->add_tag_to_hash($hash, $res->{category}, 1);

  my $exifTool = new Image::ExifTool;
  $exifTool->Options(Unknown => 1);

  for my $tag (@{$res->{extra_tags}}) {
    $self->add_tag_to_hash($hash, $tag, 1);
  }

  return $hash;
}

sub find_or_create_tag
{
  my $self = shift;
  my $name = shift;
  my $auto = shift;
  return $self->db()->resultset('Tag')->find_or_create({
                                                        detail => $name,
                                                       });
}


sub find_tag
{
  my $self = shift;
  my $name = shift;
  return $self->db()->resultset('Tag')->find({
                                              detail => $name,
                                             });
}

sub find_hash
{
  my $self = shift;
  my $digest = shift;
  return $self->db()->resultset('Hash')->find({
                                               detail => $digest,
                                              });
}

sub find_or_create_description
{
  my $self = shift;
  my $text = shift;
  return $self->db()->resultset('Description')->find_or_create({
                                                                detail => $text,
                                                               });
}

sub auto_tag
{
#   my $self = shift;
#   my $filename = shift;

#   my $file = $self->find_file($filename);

#   if (!defined $file) {
#     $file = $self->create_file($filename);
#   }

#   my $hash = $file->hash_id();
#   my $magic = $hash->magic_id();

#   return $file;
}

sub add_tag_to_hash
{
  my $self = shift;
  my $hash = shift;
  my $tag_string = lc shift;
  my $auto = shift;

  die "auto not set" if not defined $auto;

  die if $tag_string eq '1';

  my $tag = $self->find_or_create_tag($tag_string);

  my @tags = map {$_->tag_id()} $hash->hashtags();
  if (!grep { $_->detail() eq $tag->detail()} @tags) {
    $hash->add_to_tags($tag, {auto => $auto});
  }
}

sub tag_file
{
  my $self = shift;
  my $filename = shift;
  my $auto = shift;
  my @tag_strings = @_;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my $hash = $file->hash_id();

  for my $tag_string (@tag_strings) {
    $self->add_tag_to_hash($hash, $tag_string, $auto);
  }

  return $file;
}

sub describe_file
{
  my $self = shift;
  my $filename = shift;
  my $description_details = shift;

  $description_details =~ s/^\s+//;
  $description_details =~ s/\s+$//;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my $hash = $file->hash_id();

  my $description = $self->find_or_create_description($description_details);

  $hash->description_id($description);
  $hash->update();

  return $file;
}

sub update_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->find_file($filename);

  if (!defined $file) {
    $file = $self->create_file($filename);
  }

  my @tags = $self->get_tags_of_file($filename);

  if (grep {$_->detail() eq 'image'} @tags) {
    $self->get_cache()->get_image_from_cache($file->hash_id(), [$THUMB_SIZE]);
    $self->get_cache()->get_image_from_cache($file->hash_id(), [$BIG_IMAGE_SIZE]);
  }

  return $file;
}

sub find_file_by_tag
{
  my $self = shift;
  my @tag_names = @_;

  my @constraints = map {('tag_id.detail' => $_)} @tag_names;

  my @files = $self->db()->resultset('File')->search(
    {
     @constraints
    },
    {
     join => {
              'hash_id' => { 'hashtags' => 'tag_id' }
             },
     order_by => 'hash_id.creation_timestamp'
    }
  );

  return @files;
}

my %months = (
              january   =>  1,
              february  =>  2,
              march     =>  3,
              april     =>  4,
              may       =>  5,
              june      =>  6,
              july      =>  7,
              august    =>  8,
              september =>  9,
              october   => 10,
              november  => 11,
              december  => 12,
             );

my %days = (
            sunday    =>  0,
            monday    =>  1,
            tuesday   =>  2,
            wednesday =>  3,
            thursday  =>  4,
            friday    =>  5,
            saturday  =>  6,
           );

map {/^(...)/; $months{$1} = $months{$_}} keys %months;

sub get_constraint_from_tag
{
  my $tag_name = shift;

  if ($tag_name =~ /^\d+$/ &&
      ($tag_name >= 1900 && $tag_name < 2100 ||
       $tag_name >= 1 && $tag_name <= 21) ||
      exists $months{$tag_name} || exists $days{$tag_name}) {
    # a date
    if (exists $months{$tag_name}) {
      return "date_part('month'::text, creation_timestamp) = $months{$tag_name}";
    } else {
      if (exists $days{$tag_name}) {
        return "date_part('dow'::text, creation_timestamp) = $days{$tag_name}";
      } else {
        if ($tag_name < 1900) {
          return "date_part('day'::text,creation_timestamp) = $tag_name";
        } else {
          return "date_part('year'::text, creation_timestamp) = $tag_name";
        }
      }
    }
  } else {
    my $str =
      "me.id in (select hashtag.hash_id from hashtag, tag " .
      "   where hashtag.hash_id = me.id" .
      "      and hashtag.tag_id = tag.id" .
      "      and tag.detail = '%s')";
    $tag_name =~ m/(!?)(.*)/;
    if ($1 eq '!') {
      return sprintf "not $str", $2;
    } else {
      return sprintf $str, $2;
    }
  }
}

my $HIDE = ':hide';

sub find_hash_by_tag
{
  my $self = shift;
  my $tag_names_ref = shift;

  my @tag_names = @$tag_names_ref;
  push @tag_names, "!$HIDE";

  my $where = join ' and ', map {
    get_constraint_from_tag($_);
  } @tag_names;

  my $rs = $self->db()->resultset('Hash')->search(
    undef,
    {
     order_by => 'creation_timestamp'
    })->search_literal($where);


  return $rs;
}

sub find_file_by_hash
{
  my $self = shift;
  my $hash_digest = shift;

  my @hashes = $self->db()->resultset('Hash')->search({detail => $hash_digest});
  return map {$_->files()} @hashes;
}

# find files with the same hash as the given file
sub find_file_by_file_hash
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file && defined $file->hash_id()) {
    return $self->find_file_by_hash($file->hash_id()->detail());
  } else {
    return ();
  }
}

sub get_tag_names
{
  my $self = shift;

  my @tags = $self->db()->resultset('Tag')->all();

  return map {$_->detail()} @tags;
}

sub get_tags_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file && defined $file->hash_id()) {
    return map {$_->tag_id()} $file->hash_id()->hashtags();
  } else {
    return ();
  }
}

sub hash_has_tag
{
  my $self = shift;
  my $hash = shift;
  my $tag = shift;

  if (!ref $hash) {
    $hash = $self->find_hash($hash);
  }

  my $memd = $self->get_memchached();

  my $digest = $hash->detail();

  my $key = "hashtag:$digest-$tag";
  my $has_tag = $memd->get($key);

  if (!defined $has_tag) {
    $has_tag = grep {$_->detail() eq $tag} $self->get_tags_of_hash($hash, 1);
    $memd->set($key, $has_tag);
  }

  return $has_tag;
}


sub get_tags_of_hash
{
  my $self = shift;
  my $hash = shift;
  my $auto = shift;

  my @constraints = ('hash_id.detail' => $hash->detail());

  if ($auto == 0 || $auto == 1) {
    push @constraints, 'hashtags.auto' => $auto;
  }

  my $rs = $self->db()->resultset('Tag')->search(
      {
       @constraints
      },
      {
       join => {'hashtags' => 'hash_id'},
      }
   );

  return $rs->all();
}

sub get_description_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file) {
    return $file->hash_id()->description_id();
  }

  return undef;
}

sub get_hash_of_file
{
  my $self = shift;
  my $filename = shift;

  my $file = $self->db()->resultset('File')->find({detail => $filename});
  if (defined $file) {
    return $file->hash_id();
  }

  return undef;
}

sub get_tag_counts
{
  my $self = shift;

  my $query = <<"END";

SELECT tag.detail AS tagname, count(hash.detail) AS count
  FROM hash, hashtag, tag
  WHERE hash.id = hashtag.hash_id AND hashtag.tag_id = tag.id
    AND tag.detail <> '$HIDE'
  GROUP BY tag.detail ORDER BY COUNT(hash.detail)

END

  my $dbh = $self->db()->storage()->dbh();
  my $sth = $dbh->prepare($query) || die $dbh->errstr;
  $sth->execute() || die $sth->errstr;
  return $sth;
}

my @dow = qw(sunday monday tuesday wednesday thursday friday saturday);

my @month = qw(error january february march april may june
               july august september october november december);

sub get_date_bits
{
  my $self = shift;
  my $type = shift;

  my $date_part = "date_part('$type'::TEXT, creation_timestamp)";
  my $query = <<END;
SELECT $date_part AS val, COUNT(id) FROM hash
 WHERE $date_part IS NOT NULL GROUP BY $date_part ORDER BY $date_part
END

  tie my %ret, 'Tie::IxHash';

  my $dbh = $self->db()->storage()->dbh();
  my $sth = $dbh->prepare($query) || die $dbh->errstr;
  $sth->execute() || die $sth->errstr;
  while (my $r = $sth->fetchrow_hashref()) {
    my $val = $r->{val};
    my $count = $r->{count};

    if ($type eq 'year' || $type eq 'day') {
      $ret{$val} = $count;
    } else {
      if ($type eq 'dow') {
        $ret{$dow[$val]} = $count;
      } else {
        $ret{$month[$val]} = $count;
      }
    }
  }

  return %ret;
}

sub get_memchached
{
  my $self = shift;
  return $self->{_memd};
}

### doesn't do anything useful yet
#
# sub clean_up
# {
#   my $self = shift;

#   my $file_cursor = $self->db()->resultset('File')->search();

#   while (my $file = $file_cursor->next()) {
#     my $filename = $file->detail();

#     if (-e $filename) {
#       warn "exists: $filename\n";
#     } else {
#       warn "not exists: $filename\n";
#       if ($self->verbose()) {
#         warn "forgetting: $filename\n";
#       }
#     }
#   }
# }

1;
