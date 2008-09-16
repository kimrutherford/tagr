package File::Tagr::DB::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('role_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "role",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("role_pkey", ["id"]);
__PACKAGE__->has_many(
  "personroles",
  "File::Tagr::DB::Personrole",
  { "foreign.role_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 23:25:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8+ZuMdplp20x9tDU0OYomQ
# These lines were loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Role.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!
package File::Tagr::DB::Role;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("role");
__PACKAGE__->add_columns(
  "id",
  {
    data_type => "integer",
    default_value => "nextval('role_id_seq'::regclass)",
    is_nullable => 0,
    size => 4,
  },
  "role",
  {
    data_type => "text",
    default_value => undef,
    is_nullable => 1,
    size => undef,
  },
);
__PACKAGE__->set_primary_key("id");
__PACKAGE__->add_unique_constraint("role_pkey", ["id"]);
__PACKAGE__->has_many(
  "personroles",
  "File::Tagr::DB::Personrole",
  { "foreign.role_id" => "self.id" },
);


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 00:36:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:z1u43Jf+aiCYc1D0kbrNOQ


# You can replace this text with custom content, and it will be preserved on regeneration
1;
# End of lines loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Role.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
