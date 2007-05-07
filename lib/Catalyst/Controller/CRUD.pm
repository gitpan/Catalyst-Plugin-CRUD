package Catalyst::Controller::CRUD;

use strict;
use warnings;

our $VERSION = '0.17';

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
    my ( $this, $c, $self ) = @_;
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
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        if ( defined $model ) {
            for my $item (@columns) {
                if ( $model->can($item) ) {
                    $c->req->params->{$item} = $model->$item;
                }
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
    my ( $this, $c, $self ) = @_;
    my $setting = $self->setting($c);
    my @columns = @{ $setting->{columns} };

    # prepare read form
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        if ( defined $model ) {
            $c->stash->{ $self->setting($c)->{name} } = $this->model_to_hashref($model);
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
    my ( $this, $c, $self ) = @_;
    my $setting = $self->setting($c);
    my $primary = $setting->{primary};
    my @columns = @{ $setting->{columns} };

    # update already record
    if ( $c->req->param('btn_update') ) {
        my $model = $this->get_model($c, $self, $c->req->param($primary));
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
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        $c->stash->{ $self->setting($c)->{name} } = $this->model_to_hashref($model);
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
    my ( $this, $c, $self ) = @_;
    my $setting = $self->setting($c);

    # delete record
    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $this->get_model($c, $self, $c->req->args->[0]);
        $self->call_trigger( 'delete_before', $c, $model );
        unless ( $c->stash->{delete}->{error} ) {
            $model->disable(1);
            $model->update();
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

sub list {
    my ( $this, $c, $self ) = @_;
    my $setting = $self->setting($c);
    $c->stash->{ $setting->{name} . 's' } = $this->get_models($c, $self);
    $c->stash->{template} = $setting->{template}->{prefix} . $setting->{template}->{list};
    $self->call_trigger( 'list_before', $c );
}

=head1 INTERNAL METHODS

=head2 model_to_hashref($this,$model)

translate model object to hash reference

=cut

sub model_to_hashref {
    die 'this method must be overriden in the subclass.';
}

=head2 get_model($this,$c,$self,$id)

return model from $id. this method is implemented by sub class.

=cut

sub get_model {
    die 'this method must be overriden in the subclass.';
}

=cut

=head2 get_models($this,$c,$self)

return all models. this method is implemented by sub class.

=cut

sub get_models {
    die 'this method must be overriden in the subclass.';
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
