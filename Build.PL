#!/usr/bin/perl -w

use strict;

use Module::Build;
my $build = Module::Build->new
(
 module_name => 'File::Tagr',
 license  => 'perl',
 requires => {
              'File::LibMagic'  => 0,
              'DBD::SQLite' => 0,
              'Lingua::StopWords' => 0,
              'Tree::Trie' => 0,
             },
 sign => 1,
 script_files => ['bin/tagr']
);
$build->create_build_script;

