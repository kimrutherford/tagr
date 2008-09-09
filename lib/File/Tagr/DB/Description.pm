package File::Tagr::DB::Description;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("description");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('description_id_seq'::regclass)",
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
__PACKAGE__->add_unique_constraint("description_detail_key", ["detail"]);
__PACKAGE__->add_unique_constraint("description_pkey", ["id"]);
__PACKAGE__->has_many(
  "hashes",
  "File::Tagr::DB::Hash",
  { "foreign.description_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-09 22:30:56
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:5irnnajCwm6OWlowRkOcBQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
