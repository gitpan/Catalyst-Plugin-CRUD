package Catalyst::Plugin::CRUD;

use strict;
use warnings;

our $VERSION = '0.10';

=head1 NAME

Catalyst::Plugin::CRUD - CRUD (create/read/update/delete) Plugin for Catalyst

=head1 SYNOPSIS

  package Catalyst::Plugin::CRUD::CDBI;
  
  use base qw(Catalyst::Plugin::CRUD);
  
  sub create {
    # somecode
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
    my $setting = $self->setting($c);
    my @columns = @{ $setting->{columns} };

    # insert new record
    if ( $c->req->param('btn_create') ) {
        my $hash;
        for my $column (@columns) {
            my $param = $c->req->param($column);
            $hash->{$column} = $param
              if ( defined $param && length($param) > 0 );
        }
        $self->call_trigger( 'create_before', $c, $hash );
        unless ( $c->stash->{create}->{error} ) {
            my $model = $c->model( $self->setting($c)->{model} )->create($hash);
            $self->call_trigger( 'create_after', $c, $model );
            return $c->res->redirect( $self->setting($c)->{default} );
        }

        # create error
        else {
            $self->call_trigger( 'input_before', $c );
        }
    }

    # for /xxx/copy/yyy
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->get_model($self, $c->req->args->[0]);
        for my $item (@columns) {
            if ( defined $model && $model->can($item) ) {
                $c->req->params->{$item} = $model->$item;
            }
        }
        $self->call_trigger( 'input_before', $c );
    }

    # initial input
    else {
        $self->call_trigger( 'input_before', $c );
    }

    $c->stash->{template} = $self->setting($c)->{template}->{prefix} . $self->setting($c)->{template}->{create};
}

=head2 read

read action.

triggers:

 $self->call_trigger( 'read_before', $c );

=cut

sub read {
    my ( $c, $self ) = @_;
    my $setting = $self->setting($c);
    my @columns = @{ $setting->{columns} };

    # prepare read form
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->get_model($self, $c->req->args->[0]);
        if ( defined $model ) {
            my $method = $columns[0];
            $model->$method;
            $c->stash->{ $self->setting($c)->{name} } = $model;
            $self->call_trigger( 'read_before', $c );
        }

        # read error
        else {
            return $c->res->redirect( $self->setting($c)->{default} );
        }
    }

    # read error
    else {
        return $c->res->redirect( $self->setting($c)->{default} );
    }

    $c->stash->{template} = $self->setting($c)->{template}->{prefix} . $self->setting($c)->{template}->{read};
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
    my $setting = $self->setting($c);
    my $primary = $setting->{primary};
    my @columns = @{ $setting->{columns} };

    # update already record
    if ( $c->req->param('btn_update') ) {
        my $model = $c->get_model($self, $c->req->param($primary));
        for my $column (@columns) {
            $model->$column( $c->req->param($column) )
              if ( $model->can($column) );
        }
        $self->call_trigger( 'update_before', $c, $model );
        unless ( $c->stash->{update}->{error} ) {
            $model->update();
            $self->call_trigger( 'update_after', $c, $model );
            return $c->res->redirect( $self->setting($c)->{default} );
        }

        # update error
        else {
            $self->call_trigger( 'input_before', $c );
        }
    }

    # prepare update form
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->get_model($self, $c->req->args->[0]);
        $c->stash->{ $self->setting($c)->{name} } = $model;
        $self->call_trigger( 'input_before', $c );
    }

    # update error
    else {
        return $c->res->redirect( $self->setting($c)->{default} );
    }

    $c->stash->{template} = $self->setting($c)->{template}->{prefix} . $self->setting($c)->{template}->{update};
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
    my $setting = $self->setting($c);

    # delete record
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->get_model($self, $c->req->args->[0]);
        $self->call_trigger( 'delete_before', $c, $model );
        unless ( $c->stash->{delete}->{error} ) {
            $model->delete();
            $self->call_trigger( 'delete_after', $c );
        }
    }

    $c->res->redirect( $self->setting($c)->{default} );
}

=head2 list

list action

triggers:

 $self->call_trigger( 'list_before', $c );

=cut

=head2 list

list action.

triggers:

 $self->call_trigger( 'list_before', $c );

=cut

sub list {
    my ( $c, $self ) = @_;
    my $setting = $self->setting($c);
    my @models  = $c->get_models($self);
    $c->stash->{ $setting->{name} . 's' } = \@models;
    $c->stash->{template} = $setting->{template}->{prefix} . $setting->{template}->{list};
    $self->call_trigger( 'list_before', $c );
}

=head1 INTERNAL METHODS

=head2 get_model($c,$self,$id)

return model from $id. this method is implemented by sub class.

=cut

sub get_model {
    die;
}

=cut

=head2 get_models($c,$self)

return all models. this method is implemented by sub class.

=cut

sub get_models {
    die;
}

=head1 SEE ALSO

Catalyst

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
