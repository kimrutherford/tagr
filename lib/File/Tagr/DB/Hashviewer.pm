package File::Tagr::DB::Hashviewer;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hashviewer");
__PACKAGE__->add_columns(
  "hash_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
  "viewer_id",
  { data_type => "integer", default_value => undef, is_nullable => 0, size => 4 },
);
__PACKAGE__->set_primary_key("viewer_id", "hash_id");
__PACKAGE__->add_unique_constraint("hashviewer_pkey", ["viewer_id", "hash_id"]);
__PACKAGE__->belongs_to("viewer_id", "File::Tagr::DB::Person", { id => "viewer_id" });
__PACKAGE__->belongs_to("hash_id", "File::Tagr::DB::Hash", { id => "hash_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-17 15:50:10
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:8YZDigdEvgJHST1k6WQJEQ
# These lines were loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Hashviewer.pm' found in @INC.# They are now part of the custom portion of this file# for you to hand-edit.  If you do not either delete# this section or remove that file from @INC, this section# will be repeated redundantly when you re-create this# file again via Loader!
package File::Tagr::DB::Hashviewer;

use strict;
use warnings;

use base 'DBIx::Class';

__PACKAGE__->load_components("Core");
__PACKAGE__->table("hashviewer");
__PACKAGE__->add_columns(
  "hash_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
  "viewer_id",
  { data_type => "integer", default_value => undef, is_nullable => 1, size => 4 },
);
__PACKAGE__->belongs_to("viewer_id", "File::Tagr::DB::Person", { id => "viewer_id" });
__PACKAGE__->belongs_to("hash_id", "File::Tagr::DB::Hash", { id => "hash_id" });


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 00:36:16
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:GiU9MDShKzMqodJONcbsrA


# You can replace this text with custom content, and it will be preserved on regeneration
1;
# End of lines loaded from '/usr/local/share/perl/5.10.0/File/Tagr/DB/Hashviewer.pm' 


# You can replace this text with custom content, and it will be preserved on regeneration
1;
