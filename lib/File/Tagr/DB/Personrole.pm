package File::Tagr::DB::Personrole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("personrole");
__PACKAGE__->add_columns(
  "person_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("person_id", "role_id");
__PACKAGE__->add_unique_constraint("personrole_pkey", ["person_id", "role_id"]);
__PACKAGE__->belongs_to("person_id", "File::Tagr::DB::Person", { id => "person_id" });
__PACKAGE__->belongs_to("role_id", "File::Tagr::DB::Role", { id => "role_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 23:25:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c61KA+HngYgF44C6Z4cLsA
# These lines were loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Personrole.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!
package File::Tagr::DB::Personrole;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("personrole");
__PACKAGE__->add_columns(
  "person_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "role_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->belongs_to("person_id", "File::Tagr::DB::Person", { id => "person_id" });
__PACKAGE__->belongs_to("role_id", "File::Tagr::DB::Role", { id => "role_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 00:36:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:9R2+DCMNJ3dHRlgRA3ftFw


# You can replace this text with custom content, and it will be preserved on regeneration
1;
# End of lines loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Personrole.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
