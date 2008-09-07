package File::Tagr::DB::Hashtag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hashtag");
__PACKAGE__->add_columns(
  "tag_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "hash_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "auto",
  { data_type => "boolean", default_value => undef, is_nullable => 0, size => 1 },
);
__PACKAGE__->set_primary_key("tag_id", "hash_id");
__PACKAGE__->add_unique_constraint("hashtag_pkey", ["tag_id", "hash_id"]);
__PACKAGE__->belongs_to("tag_id", "File::Tagr::DB::Tag", { id => "tag_id" });
__PACKAGE__->belongs_to("hash_id", "File::Tagr::DB::Hash", { id => "hash_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-08-13 11:13:28
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:rnr6xemXar+8pSNtDc++3A


# You can replace this text with custom content, and it will be preserved on regeneration
1;
