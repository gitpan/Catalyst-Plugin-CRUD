package Catalyst::Controller::CRUD::DBIC;

use strict;
use warnings;
use base qw(Catalyst::Controller::CRUD);

our $VERSION = '0.16';

=head1 NAME

Catalyst::Controller::CRUD::DBIC - CRUD (create/read/update/delete) Controller for DBIx::Class

=head1 SYNOPSIS

  # MyApp/lib/MyApp.pm
  package MyApp;
  
  use Catalyst qw/-Debug MakeText CRUD::DBIC/;
  
  1;
  
  # MyApp/lib/MyApp/Controller/User.pm
  package MyApp::Controller::User;
  
  use base 'Catalyst::Controller';
  use Class::Trigger;
  
  sub setting {
      my ( $self, $c ) = @_;
      my $hash = {
          'name'     => 'user',
          'type'     => 'DBIC',
          'model'    => 'DBIC::UserMaster',
          'primary'  => 'id',
          'columns'  => [qw(name phone mail)],
          'default'  => '/user/list',
          'template' => {
              'prefix' => 'template/user/',
              'create' => 'create.tt',
              'read'   => 'read.tt',
              'update' => 'update.tt',
              'list'   => 'list.tt'
          },
      };
      return $hash;
  }
  
  sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
  }
  
  1;

  <!-- MyApp/root/template/user/create.tt -->
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

This module provides CRUD (create/read/update/delete) action using with DBIx::Class.

 create: insert new record
 read:   find record
 update: update record
 delete: delete record
 list:   find all records

=head2 EXPORT

None by default.

=head1 METHODS

=head2 create

create action.

=head2 read

read action.

=head2 update

update action.

=head2 delete

delete action.

=head2 list

list action.

=head1 INTERNAL METHODS

=head2 model_to_hashref

translate model object to hash reference

=cut

sub model_to_hashref {
    my ( $this, $model ) = @_;

    # see http://search.cpan.org/dist/DBIx-Class-AsFdat/lib/DBIx/Class/AsFdat.pm
    my $hash;
    for my $column ($model->result_source->columns) {
        $hash->{$column} = $model->$column;

        # inflate the datetime
        if (blessed $hash->{$column} and $hash->{$column}->isa('DateTime')) {
            for my $type (qw(year month day hour minute second)) {
                $hash->{"${column}_$type"}  = $hash->{$column}->$type;
            }
        }
    }
    return $hash;
}

=head2 get_model

return model from $id.

=cut

sub get_model {
    my ( $this, $c, $self, $id ) = @_;
    my $setting = $self->setting($c);
    my $primary = $setting->{primary};
    my $model   = $c->model( $self->setting($c)->{model} )->find( $primary => $id );
    return $model;
}

=cut

=head2 get_models

return all models.

=cut

sub get_models {
    my ( $this, $c, $self ) = @_;
    my $setting = $self->setting($c);
    my $primary = $setting->{primary};
    my @models  = $c->model( $setting->{model} )->search( { disable => 0 }, { order_by => $primary } );
    my @result;
    foreach (@models) {
        push(@result, $this->model_to_hash($_));
    }
    return \@result;
}

=head1 SEE ALSO

Catalyst::Controller::CRUD, Class::DBI, DBIx::Class

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
