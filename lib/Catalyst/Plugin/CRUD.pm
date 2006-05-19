package Catalyst::Plugin::CRUD;

use strict;
use warnings;

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::CRUD - CRUD (create/read/update/delete) Plugin Interface

=head1 SYNOPSIS

  package Catalyst::Plugin::CRUD::CDBI;
  
  use base qw(Catalyst::Plugin::CRUD);
  
  sub create {
    # somecode
  }
  
  1;

=head1 DESCRIPTION

This module define CRUD (create/read/update/delete) action interface.

 create: insert new record
 read:   retrieve record
 update: update record
 delete: delete record
 list:   retrieve all records

=head2 EXPORT

None by default.

=head1 METHODS

=head2 create

create action

triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'create_before', $c, $hash );
 $self->call_trigger( 'create_after', $c, $model );

=cut

sub create {
    die;
}

=head2 read

read action

triggers:

 $self->call_trigger( 'read_before', $c );

=cut

sub read {
    die;
}

=head2 update

update action

triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'update_before', $c, $model );
 $self->call_trigger( 'update_after', $c, $model );

=cut

sub update {
    die;
}

=head2 delete

delete action

triggers:

 $self->call_trigger( 'delete_before', $c, $model );
 $self->call_trigger( 'delete_after', $c );

=cut

sub delete {
  die;
}

=head2 list

list action

triggers:

 $self->call_trigger( 'list_before', $c );

=cut

sub list {
  die;
}

=head1 SEE ALSO

Mention other useful documentation such as the documentation of
related modules or operating system documentation (such as man pages
in UNIX), or any relevant external documentation such as RFCs or
standards.

If you have a mailing list set up for your module, mention it here.

If you have a web site set up for your module, mention it here.

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
