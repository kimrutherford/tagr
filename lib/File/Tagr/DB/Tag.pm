package File::Tagr::DB::Tag;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("tag");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('tag_id_seq'::regclass)",
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
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("tag_detail_key", ["detail"]);
__PACKAGE__->add_unique_constraint("tag_pkey", ["id"]);
__PACKAGE__->has_many(
  "hashtags",
  "File::Tagr::DB::Hashtag",
  { "foreign.tag_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-17 15:50:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:fbZuQ7oWn8kLFidlCV3lRg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
