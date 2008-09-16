package File::Tagr::DB;

use strict;
use warnings;

use base 'DBIx::Class::Schema';

__PACKAGE__->load_classes;


# Created by DBIx::Class::Schema::Loader v0.04005 @ 2008-09-15 23:25:09
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:c3iybB2dz5Dn1/6bqiKb2g

File::Tagr::DB::Hash->many_to_many('tags' => 'hashtags', 'tag_id');
File::Tagr::DB::Tag->many_to_many('hashes' => 'hashtags', 'hash_id');


# You can replace this text with custom content, and it will be preserved on regeneration
1;
