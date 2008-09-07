package File::Tagr::DB::Hash;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hash");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('hash_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "detail",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 0,
    size => undef,
  },
  "magic_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "description_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "creation_timestamp",
  {
    data_type => "timestamp without time zone",
    default_value => undef,
    is_nullable => 1,
    size => 8,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("hash_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("hash_detail_key", ["detail"]);
__PACKAGE__->has_many(
  "files",
  "File::Tagr::DB::File",
  { "foreign.hash_id" => "self.id" },
);
__PACKAGE__->belongs_to("magic_id", "File::Tagr::DB::Magic", { id => "magic_id" });
__PACKAGE__->belongs_to(
  "description_id",
  "File::Tagr::DB::Description",
  { id => "description_id" },
);
__PACKAGE__->has_many(
  "hashtags",
  "File::Tagr::DB::Hashtag",
  { "foreign.hash_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-08-13 11:13:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:ZczzMXrq4LMvd69nWGk2Vw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
