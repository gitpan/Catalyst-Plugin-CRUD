package Catalyst::Plugin::CRUD;

use strict;
use warnings;
use Catalyst::Controller::CRUD::CDBI;
use Catalyst::Controller::CRUD::DBIC;

our $VERSION = '0.18';

=head1 NAME

Catalyst::Plugin::CRUD - CRUD (create/read/update/delete) Plugin for Catalyst

=head1 SYNOPSIS

  package MyApp;
  
  use Catalyst qw/-Debug ConfigLoader I18N CRUD Static::Simple/;
  
  1;
  
  package MyApp::Controller::Foo;
  
  sub create : Local {
    my ($self, $c) = @_;
    $c->create($self);
  }
  
  1;

=head1 DESCRIPTION

This module provides CRUD (create/read/update/delete) action.

 create: insert new record
 read:   retrieve record
 update: update already record
 delete: delete record
 list:   retrieve all records

=head2 EXPORT

None by default.

=head1 METHODS

=head2 create

create action.
this method internally calls Catalyst::Controller::[CDBI|DBIC]::create.

=cut

sub create {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->create($c, $self);
}

=head2 read

read action.
this method internally calls Catalyst::Controller::[CDBI|DBIC]::read.

=cut

sub read {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->read($c, $self);
}

=head2 update

update action.
this method internally calls Catalyst::Controller::[CDBI|DBIC]::update.

=cut

sub update {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->update($c, $self);
}

=head2 delete

delete action.
this method internally calls Catalyst::Controller::[CDBI|DBIC]::delete.

=cut

sub delete {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->delete($c, $self);
}

=head2 list

list action
this method internally calls Catalyst::Controller::[CDBI|DBIC]::list.

=cut

sub list {
    my ( $c, $self ) = @_;
    my $type = $self->setting($c)->{type} || 'CDBI';
    my $cntl = "Catalyst::Controller::CRUD::" . $type;
    $cntl->list($c, $self);
}

=head1 SEE ALSO

Catalyst, Catalyst::Controller::CRUD

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
