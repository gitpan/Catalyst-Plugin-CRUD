package Catalyst::Controller::CRUD::CDBI;

use strict;
use warnings;
use base qw(Catalyst::Controller::CRUD);

our $VERSION = '0.19';

=head1 NAME

Catalyst::Controller::CRUD::CDBI - Implementation for Catalyst::Controller::CRUD

=head1 SYNOPSIS

=head2 MyApp/lib/MyApp.pm

  package MyApp;
  
  use Catalyst qw/-Debug I18N CRUD Static::Simple/;
  
  1;
  
=head2 MyApp/lib/MyApp/Controller/User.pm

  package MyApp::Controller::User;
  
  use base 'Catalyst::Controller';
  use Class::Trigger;
  
  sub setting {
      my ( $self, $c ) = @_;
      my $hash = {
          'name'     => 'user',
          'type'     => 'CDBI',
          'model'    => 'CDBI::UserMaster',
          'primary'  => 'id',
          'columns'  => [qw(name phone mail)],
          'default'  => '/user/list',
          'template' => {
              'prefix' => 'template/user/',
              'suffix' => '.tt'
          },
      };
      return $hash;
  }
  
  sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
  }
  
  1;

=head1 DESCRIPTION

This module implements Class::DBI depend interfaces for Catalyst::Controller::CRUD.

 - get_model
 - get_models

=head2 EXPORT

None by default.

=head1 METHODS

=head2 get_model($this,$c,$self,$id)

This method returns model object having $id.

=cut

sub get_model {
    my ( $this, $c, $self, $id ) = @_;
    my $setting = $self->setting($c);
    my $primary = $setting->{primary};
    my $model   = $c->model( $self->setting($c)->{model} )->retrieve( $primary => $id );
    return $model;
}

=head2 get_models($this,$c,$self)

This method returns model objects.

Triggers:

 $self->call_trigger( 'list_where_make_phrase', $c, $where );
 $self->call_trigger( 'list_order_make_phrase', $c, $order );

=cut

sub get_models {
    my ( $this, $c, $self ) = @_;

    my $where = { disable => 0 };
    $self->call_trigger( 'list_where_make_phrase', $c, $where );

    my $order = { order_by => $self->setting($c)->{primary} };
    $self->call_trigger( 'list_order_make_phrase', $c, $order );

    my @models  = $c->model( $self->setting($c)->{model} )->search_where( $where, $order );
    my @result;
    foreach (@models) {
        push(@result, $_->toHashRef);
    }
    return \@result;
}

=head1 SEE ALSO

Catalyst::Controller::CRUD, Class::DBI

=head1 AUTHOR

Jun Shimizu, E<lt>bayside@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2006,2007 by Jun Shimizu

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.2 or,
at your option, any later version of Perl 5 you may have available.

=cut

1;
