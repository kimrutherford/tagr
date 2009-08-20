package File::Tagr::Web::Model::TagrDB;

use strict;
use base 'Catalyst::Model::DBIC::Schema';

__PACKAGE__->config(
    schema_class => 'File::Tagr::DB',
    connect_info => [
        'dbi:Pg:dbname=kmr-files;host=hydrogen',
        'kmr44', 'kmr'
        
    ],
);

=head1 NAME

File::Tagr::Web::Model::TagrDB - Catalyst DBIC Schema Model
=head1 SYNOPSIS

See L<File::Tagr::Web>

=head1 DESCRIPTION

L<Catalyst::Model::DBIC::Schema> Model using schema L<File::Tagr::DB>

=head1 AUTHOR

Kim Rutherford

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
