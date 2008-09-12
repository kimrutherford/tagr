package File::Tagr::DB::Person;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("person");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('person_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "roles",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
  "username",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "fullname",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("person_pkey", ["id"]);
__PACKAGE__->has_many(
  "hashes",
  "File::Tagr::DB::Hash",
  { "foreign.source_id" => "self.id" },
);
__PACKAGE__->has_many(
  "hashtags",
  "File::Tagr::DB::Hashtag",
  { "foreign.tagger_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-09 22:30:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z9t0EqZnJPgXCsgu96VoMA


# You can replace this text with custom content, and it will be preserved on regeneration
1;