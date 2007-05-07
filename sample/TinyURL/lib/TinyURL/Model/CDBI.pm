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

1;
