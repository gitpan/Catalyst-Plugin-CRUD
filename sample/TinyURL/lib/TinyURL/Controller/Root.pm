package TinyURL::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config->{namespace} = '';

=head1 NAME

TinyURL::Controller::Root - Root Controller for TinyURL

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 auto

必ず最初に通る

=cut

sub auto : Private {
    my ( $self, $c ) = @_;

    $c->languages( ['ja'] );
}

=head2 default

パスが見つからなかったときに通る

=cut

sub default : Private {
    my ( $self, $c ) = @_;

    if ( defined $c->req->args->[0] and $c->req->args->[0] =~ /^\d+$/ ) {
        my $id = $c->req->args->[0];
        my $model = $c->model('CDBI::TinyUrl')->retrieve($id);
        if (defined $model) {
            $c->res->redirect($model->long_url);
        } else {
            $c->forward( 'TinyUrl', 'create' );
        }
    } else {
        $c->forward( 'TinyUrl', 'create' );
    }
}

=head2 end

必ず最後に通る

=cut

sub end : Private {
    my ( $self, $c ) = @_;
    $c->stash->{template} = 'template/tinyurl/list.tt'
      unless ( exists $c->stash->{template} );
    $c->forward( $c->view('TT') ) unless $c->response->body;
}

=head1 AUTHOR

Jun Shimizu

=head1 LICENSE

This library is free software, you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

1;
