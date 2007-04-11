package TinyURL::Model::CDBI;

use strict;
use base 'Catalyst::Model::CDBI';
use Class::DBI::AbstractSearch ;

__PACKAGE__->config(
    dsn           => 'dbi:Pg:dbname=tinyurl;host=localhost;port=5432;',
    user          => 'shimizu',
    password      => 'hogehoge',
    options       => { AutoCommit => 1 },
    relationships => 1
);

=head1 NAME

tinyurl::Model::CDBI - CDBI Model Component

=head1 SYNOPSIS

See L<TinyURL>

=head1 DESCRIPTION

CDBI Model Component.

=head1 AUTHOR

Jun Shimizu

=head1 LICENSE

This library is free software . You can redistribute it and/or modify
it under the same terms as perl itself.

=cut

1;
