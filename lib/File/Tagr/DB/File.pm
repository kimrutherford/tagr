package File::Tagr::DB::File;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("file");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('file_id_seq'::regclass)",
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
  "mdate",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "size",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "hash_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("file_detail_key", ["detail"]);
__PACKAGE__->add_unique_constraint("file_pkey", ["id"]);
__PACKAGE__->belongs_to("hash_id", "File::Tagr::DB::Hash", { id => "hash_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-17 15:50:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GZ6Z+8IJpzc0ydUn+u/Alw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
