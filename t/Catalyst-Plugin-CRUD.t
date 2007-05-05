# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl Catalyst-Plugin-CRUD.t'

#########################

# change 'tests => 1' to 'tests => last_test_to_print';

use Test::More tests => 8;
BEGIN { use_ok('XML::Simple') };
BEGIN { use_ok('Class::Trigger') };
BEGIN { use_ok('Jcode') };
BEGIN { use_ok('Catalyst::Plugin::CRUD') };
BEGIN { use_ok('Catalyst::Controller::CRUD') };
BEGIN { use_ok('Catalyst::Controller::CRUD::CDBI') };
BEGIN { use_ok('Catalyst::Controller::CRUD::DBIC') };
BEGIN { use_ok('Catalyst::Helper::Model::CRUD') };

#########################

# Insert your test code below, the Test::More module is use()ed here so read
# its man page ( perldoc Test::More ) for help writing this test script.

