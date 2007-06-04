package Catalyst::Controller::CRUD;

use strict;
use warnings;

our $VERSION = '0.19';

=head1 NAME

Catalyst::Controller::CRUD - CRUD (create/read/update/delete) Controller for Catalyst

=head1 SYNOPSIS

  package MyApp::Controller::Foo;
  
  use base qw(Catalyst::Controller);
  use Catalyst::Controller::CRUD::CDBI;
  
  sub create : Local {
    my ($self, $c) = @_;
    Catalyst::Controller::CRUD::CDBI->create($c, $self);
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

Create action.

If there is $c->stash->{create}->{error}, then it does not insert new recoed.

Triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'create_check', $c, $hash );
 $self->call_trigger( 'create_after', $c, $model );

=cut

sub create {
    my ( $this, $c, $self ) = @_;

    # insert new record
    if ( $c->req->param('btn_create') ) {
        $this->_do_create($c, $self);
    }

    # prepare for xxx/create/yyy
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        $this->_prepare_copy($c, $self);
    }

    # prepare create form
    else {
        $self->call_trigger( 'input_before', $c );
    }

    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . $c->action->name . $suffix;
}

=head2 read

Read action.

=cut

sub read {
    my ( $this, $c, $self ) = @_;

    # prepare read form
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        if ( defined $model ) {
            $c->stash->{ $self->setting($c)->{name} } = $model->toHashRef;
        }

        # read error
        else {
            $c->res->redirect( $self->setting($c)->{default} );
        }
    }

    # read error
    else {
        $c->res->redirect( $self->setting($c)->{default} );
    }

    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . $c->action->name . $suffix;
}

=head2 update

Update action.

If there is $c->stash->{update}->{error}, then it does not update already recoed.

Triggers:

 $self->call_trigger( 'input_before', $c );
 $self->call_trigger( 'update_check', $c, $model );
 $self->call_trigger( 'update_after', $c, $model );

=cut

sub update {
    my ( $this, $c, $self ) = @_;

    # update already record
    if ( $c->req->param('btn_update') ) {
        $this->_do_update($c,$self);
    }

    # prepare update form
    elsif ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        $c->stash->{ $self->setting($c)->{name} } = $model->toHashRef;
        $self->call_trigger( 'input_before', $c );
    }

    # update error
    else {
        return $c->res->redirect( $self->setting($c)->{default} );
    }

    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . $c->action->name . $suffix;
}

=head2 delete

Delete action.

If there is $c->stash->{delete}->{error}, then it does not delete recoed.

Triggers:

 $self->call_trigger( 'delete_check', $c, $model );
 $self->call_trigger( 'delete_after', $c, $model );

=cut

sub delete {
    my ( $this, $c, $self ) = @_;

    # delete record
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        $self->call_trigger( 'delete_check', $c, $model );
        unless ( $c->stash->{delete}->{error} ) {
            $model->disable(1);
            $model->update();
            $self->call_trigger( 'delete_after', $c, $model );
        }
    }

    $c->res->redirect( $self->setting($c)->{default} );
}

=head2 list

List action.

=cut

sub list {
    my ( $this, $c, $self ) = @_;

    $c->stash->{ $self->setting($c)->{name} . 's' } = $this->get_models($c, $self);

    my $prefix = $self->setting($c)->{template}->{prefix};
    my $suffix = $self->setting($c)->{template}->{suffix} ? $self->setting($c)->{template}->{suffix} : '.tt';
    $c->stash->{template} = $prefix . $c->action->name . $suffix;
}

=head1 INTERFACE METHODS

=head2 get_model($this,$c,$self,$id)

This method returns model object having $id.
This method must be implemented by sub class.

=cut

sub get_model {
    die 'this method must be overriden in the subclass.';
}

=head2 get_models($this,$c,$self)

This method returns model objects.
This method must be implemented by sub class.

=cut

sub get_models {
    die 'this method must be overriden in the subclass.';
}

=head1 INTERNAL METHODS

=head2 _do_create($this,$c,$self)

Insert new record.

=cut

sub _do_create {
    my ( $this, $c, $self ) = @_;

    my @columns = @{ $self->setting($c)->{columns} };
    my $hash;
    for my $column (@columns) {
        my $param = $c->req->param($column);
        $hash->{$column} = $param
            if ( defined $param );
    }

    $self->call_trigger( 'create_check', $c, $hash );

    # create error
    if ( $c->stash->{create}->{error} ) {
        $self->call_trigger( 'input_before', $c );
    }

    # insert new record
    else {
        if ( scalar(keys %{$hash}) ) {
            my $model = $c->model( $self->setting($c)->{model} )->create($hash);
            $self->call_trigger( 'create_after', $c, $model );
        }
        $c->res->redirect( $self->setting($c)->{default} );
    }
}

=head2 _prepare_copy($this,$c,$self)

Prepare for /xxx/create/yyy.

=cut

sub _prepare_copy {
    my ( $this, $c, $self ) = @_;

    my $model = $this->get_model($c, $self, $c->req->args->[0]);
    return unless defined $model;

    my @columns = @{ $self->setting($c)->{columns} };
    for my $item (@columns) {
        if ( $model->can($item) ) {
            $c->req->params->{$item} = $model->$item;
        }
    }
    $self->call_trigger( 'input_before', $c );
}

=head2 _do_update($this,$c,$self)

Update already record.

=cut

sub _do_update {
    my ( $this, $c, $self ) = @_;

    my $model = $this->get_model($c, $self, $c->req->param($self->setting($c)->{primary}));
    return unless defined $model;

    my @columns = @{ $self->setting($c)->{columns} };
    for my $column (@columns) {
        $model->$column( $c->req->param($column) )
            if ( $model->can($column) );
    }

    $self->call_trigger( 'update_check', $c, $model );

    # update error
    if ( $c->stash->{update}->{error} ) {
        $c->stash->{ $self->setting($c)->{name} } = $model->toHashRef;
        $self->call_trigger( 'input_before', $c );
    }

    # update already record
    else {
        $model->update();
        $self->call_trigger( 'update_after', $c, $model );
        $c->res->redirect( $self->setting($c)->{default} );
    }
}

=head1 SEE ALSO

Catalyst, Catalyst::Plugin::CRUD

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
