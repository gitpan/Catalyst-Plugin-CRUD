package Catalyst::Plugin::CRUD;

use strict;
use warnings;
use Catalyst::Controller::CRUD::CDBI;
use Catalyst::Controller::CRUD::DBIC;

our $VERSION = '0.16';

=head1 NAME

Catalyst::Plugin::CRUD - CRUD (create/read/update/delete) Plugin for Catalyst

=head1 SYNOPSIS

  package MyApp;
  
  use base qw(CRUD);
  
  sub create : Local {
    my ($self, $c) = @_;
    $c->create($self);
  }
  
  1;

=head1 DESCRIPTION

This module provides CRUD (create/read/update/delete) action.

 create: insert new record
 read:   retrieve record
 update: update record
 delete: delete record
 list:   retrieve all records

=head2 EXPORT

None by default.

=head1 METHODS

=head2 create

create action.

if $c->stash->{create}->{error} is 1, then do not insert new recoed.

triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'create_before', $c, $hash );
 $self->call_trigger( 'create_after', $c, $model );

=cut

sub create {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->create($c, $self);
}

=head2 read

read action.

triggers:

 $self->call_trigger( 'read_before', $c );

=cut

sub read {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->read($c, $self);
}

=head2 update

update action.

if $c->stash->{update}->{error} is 1, then do not update recoed.

triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'update_before', $c, $model );
 $self->call_trigger( 'update_after', $c, $model );

=cut

sub update {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->update($c, $self);
}

=head2 delete

delete action.

if $c->stash->{delete}->{error} is 1, then do not delete recoed.

triggers:

 $self->call_trigger( 'delete_before', $c, $model );
 $self->call_trigger( 'delete_after', $c );

=cut

sub delete {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->delete($c, $self);
}

=head2 list

list action

triggers:

 $self->call_trigger( 'list_before', $c );

=cut

sub list {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->list($c, $self);
}

=head1 SEE ALSO

Catalyst

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
