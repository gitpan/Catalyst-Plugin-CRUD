package tinyurl::Controller::TinyUrl;

use strict;
use warnings;
use base 'Catalyst::Controller';
use Class::Trigger;

sub default : Private {
    my ( $self, $c ) = @_;
    $c->forward( 'list' );
}

sub create : Local {
    my ( $self, $c ) = @_;
    $c->create($self);
}

__PACKAGE__->add_trigger(create_after => \&create_after);
sub create_after {
    my ( $self, $c, $model ) = @_;
    $c->stash->{'redirect_to'} = '/' . $model->id();
}

sub read : Local {
    my ( $self, $c ) = @_;
    $c->read($self);
}

sub update : Local {
    my ( $self, $c ) = @_;
    $c->update($self);
}

sub delete : Local {
    my ( $self, $c ) = @_;
    $c->delete($self);
}

sub list : Local {
    my ( $self, $c ) = @_;
    $c->list($self);
}

sub setting {
    my ( $self, $c ) = @_;
    my $hash = {
        'name'     => 'tinyurl',
        'model'    => 'CDBI::TinyUrl',
        'primary'  => 'id',
        'columns'  => [qw(long_url)],
        'default'  => '/tinyurl/default',
        'template' => {
            'prefix' => 'template/tinyurl/',
            'create' => 'create.html',
            'read'   => 'read.html',
            'update' => 'update.html',
            'delete' => 'delete.html',
            'list'   => 'list.html'
        },
    };
    return $hash;
}

1;

