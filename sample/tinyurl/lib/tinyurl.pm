package tinyurl;

use strict;
use warnings;

#
# Set flags and add plugins for the application
#
#         -Debug: activates the debug mode for very useful log messages
#   ConfigLoader: will load the configuration from a YAML file in the
#                 application's home directory
# Static::Simple: will serve static files from the application's root 
#                 directory
#
use Catalyst qw/-Debug Dumper StackTrace ConfigLoader Charsets::Japanese I18N CRUD::CDBI Static::Simple/;

our $VERSION = '0.01';

#
# Configure the application 
#
__PACKAGE__->config( name => 'tinyurl' );

#
# Start the application
#
__PACKAGE__->setup;

#
# IMPORTANT: Please look into tinyurl::Controller::Root for more
#

=head1 NAME

tinyurl - Catalyst based application

=head1 SYNOPSIS

    script/tinyurl_server.pl

=head1 DESCRIPTION

Catalyst based application.

=head1 SEE ALSO

L<tinyurl::Controller::Root>, L<Catalyst>

=head1 AUTHOR

Jun Shimizu

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
