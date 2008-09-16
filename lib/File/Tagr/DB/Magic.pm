package File::Tagr::DB::Magic;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("magic");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('magic_id_seq'::regclass)",
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
__PACKAGE__->add_unique_constraint("magic_pkey", ["id"]);
__PACKAGE__->add_unique_constraint("magic_detail_key", ["detail"]);
__PACKAGE__->has_many(
  "hashes",
  "File::Tagr::DB::Hash",
  { "foreign.magic_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 23:25:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:dnJwPhGbNzA2qrc4KREqMg


# You can replace this text with custom content, and it will be preserved on regeneration
1;
