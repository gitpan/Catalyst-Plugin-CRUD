package Catalyst::Plugin::CRUD::CDBI;

use strict;
use warnings;
use base qw(Catalyst::Plugin::CRUD);

our $VERSION = '0.01';

=head1 NAME

Catalyst::Plugin::CRUD::CDBI - CRUD (create/read/update/delete) Plugin for Class::DBI

=head1 SYNOPSIS

  # MyApp/lib/MyApp.pm
  package MyApp;
  
  use Catalyst qw/-Debug CRUD::CDBI/;
  
  1;
  
  # MyApp/lib/MyApp/Controller/User.pm
  package MyApp::Controller::User;
  
  use base 'Catalyst::Controller';
  use Class::Trigger;
  
  sub config {
      my ( $self, $c ) = @_;
      my $hash = {
          'name'     => 'user',
          'model'    => 'CDBI::UserMaster',
          'primary'  => 'id',
          'columns'  => [qw(name phone mail)],
          'default'  => '/user/list',
          'template' => {
              'prefix' => 'template/user/',
              'create' => 'create.html',
              'read'   => 'read.html',
              'update' => 'update.html',
              'delete' => 'delete.html',
              'list'   => 'list.html'
          },
      };
      return $hash;
  }
  
  sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
  }
  
  1;

  <!-- MyApp/root/template/user/create.html -->
  <html>
  <body>
  <h1>Create New User</h1>
  <form name="user" method="post" action="/user/create">
  <table>
    <tr>
      <td>User Name</td><td><input  type="text" name="name"  value="[% c.req.param('name') %]"></td>
    </tr>
    <tr>
      <td>User Phone</td><td><input type="text" name="phone" value="[% c.req.param('phone') %]"></td>
    </tr>
    <tr>
      <td>User Email</td><td><input type="text" name="mail"  value="[% c.req.param('mail') %]"></td>
    </tr>
  </table>
  </form>
  </body>
  </html>

=head1 DESCRIPTION

This module provides CRUD (create/read/update/delete) action using with Class::DBI.

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
    my $config  = $self->config($c);
    my @columns = @{ $config->{columns} };

    if ( length( $c->req->param( $columns[0] ) ) > 0 ) {
        my $hash;
        for my $column (@columns) {
            my $param = $c->req->param($column);
            $hash->{$column} = $param if ( length($param) > 0 );
        }
        $self->call_trigger( 'create_before', $c, $hash );
        unless ( $c->stash->{create}->{error} ) {
            my $model = $c->model( $config->{model} )->create($hash);
            $self->call_trigger( 'create_after', $c, $model );
            return $c->res->redirect( $config->{default} );
        }
    }

    else {
        $self->call_trigger( 'input_before', $c );
    }

    $c->stash->{template} = $config->{template}->{prefix} . $config->{template}->{create};
}

=head2 read

read action.

triggers:

 $self->call_trigger( 'read_before', $c );

=cut

sub read {
    my ( $c, $self ) = @_;
    my $config  = $self->config($c);
    my $primary = $config->{primary};
    my @columns = @{ $config->{columns} };

    if ( $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->model( $config->{model} )->retrieve( $primary => $c->req->args->[0] );
        my $method = $columns[0];
        $model->$method;
        $c->stash->{ $config->{name} } = $model;
    }

    else {
        $c->res->redirect( $config->{default} );
    }

    $c->stash->{template} = $config->{template}->{prefix} . $config->{template}->{read};

    $self->call_trigger( 'read_before', $c );
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
    my $config  = $self->config($c);
    my $primary = $config->{primary};
    my @columns = @{ $config->{columns} };

    if ( $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->model( $config->{model} )->retrieve( $primary => $c->req->args->[0] );
        $c->stash->{ $config->{name} } = $model;
        $self->call_trigger( 'input_before', $c );
    }

    elsif ( $c->req->param($primary) =~ /^\d+$/ ) {
        my $model = $c->model( $config->{model} )->retrieve( $primary => $c->req->param($primary) );
        for my $column (@columns) {
            $model->$column( $c->req->param($column) ) if ( $model->can($column) );
        }
        $self->call_trigger( 'update_before', $c, $model );
        unless ( $c->stash->{update}->{error} ) {
            $model->update();
            $self->call_trigger( 'update_after', $c, $model );
            return $c->res->redirect( $config->{default} );
        }
    }

    else {
        return $c->res->redirect( $config->{default} );
    }

    $c->stash->{template} = $config->{template}->{prefix} . $config->{template}->{update};
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
    my $config  = $self->config($c);
    my $primary = $config->{primary};

    if ( $c->req->args->[0] =~ /^\d+$/ ) {
        my $model = $c->model( $config->{model} )->retrieve( $primary => $c->req->args->[0] );
        $self->call_trigger( 'delete_before', $c, $model );
        unless ( $c->stash->{delete}->{error} ) {
            $model->delete();
            $self->call_trigger( 'delete_after', $c );
        }
    }

    $c->res->redirect( $config->{default} );
}

=head2 list

list action.

triggers:

 $self->call_trigger( 'list_before', $c );

=cut

sub list {
    my ( $c, $self ) = @_;
    my $config  = $self->config($c);
    my $primary = $config->{primary};
    my @models  = $c->model( $config->{model} )->search_where( { disable => 0 }, { order_by => $primary } );
    $c->stash->{ $config->{name} . 's' } = \@models;
    $c->stash->{template} = $config->{template}->{prefix} . $config->{template}->{list};
    $self->call_trigger( 'list_before', $c );
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
