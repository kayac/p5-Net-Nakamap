package Net::Nakamap;
use 5.008_001;
use HTTP::Request::Common;
use JSON::XS;
use LWP::UserAgent;
use Mouse;

our $VERSION = '0.01';

has ua => (
    is      => 'rw',
    lazy    => 1,
    default => sub {
        return LWP::UserAgent->new(),
    },
);

has client_id     => ( is => 'rw', isa => 'Str' );
has client_secret => ( is => 'rw', isa => 'Str' );

has token => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);

has auth_ep => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'https://nakamap.com' },
);

has api_ep => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { 'https://thanks.nakamap.com' },
);

has last_error => (
    is      => 'rw',
    isa     => 'Str',
    lazy    => 1,
    default => sub { '' },
);

sub auth_uri {
    my ($self, $params) = @_;

    my $uri = URI->new($self->auth_ep . '/dialog/oauth');
    $uri->query_form(
        client_id     => $self->client_id,
        response_type => $params->{response_type},
        scope         => $params->{scope},
        ($params->{redirect_uri} ? (redirect_uri  => $params->{redirect_uri}) : ()),
    );

    return $uri;
}

sub auth_code {
    my ($self, $params) = @_;

    my $uri = URI->new($self->api_ep . '/oauth/access_token');
    $uri->query_form(
        client_id     => $self->client_id,
        client_secret => $self->client_secret,
        grant_type    => 'authorization_code',
        code          => $params->{code},
        ($params->{redirect_uri} ? (redirect_uri => $params->{redirect_uri}) : ()),
    );

    my $res = $self->ua->post($uri);

    if ($res->is_success) {
        return decode_json($res->content);
    }
    else {
        $self->last_error($res->content);
        return undef;
    }
}

sub get {
    my ($self, $path, $params) = @_;

    $params ||= {};

    my $token = $params->{token} || $self->token;

    my $uri = URI->new($self->api_ep . $path);
    $uri->query_form(
        ( $token ? ( token => $token ) : () ),
        %$params,
    );

    my $res = $self->ua->get($uri);

    if ($res->is_success) {
        return decode_json($res->content);
    }
    else {
        $self->last_error($res->content);
        return undef;
    }
}

sub post {
    my ($self, $path, $params) = @_;

    $params ||= {};

    my $token = $params->{token} || $self->token;

    my $uri = URI->new($self->api_ep . $path);
    $uri->query_form(
        ( $token ? ( token => $token ) : () ),
        %$params,
    );

    my $res = $self->ua->post($uri);

    if ($res->is_success) {
        return decode_json($res->content);
    }
    else {
        $self->last_error($res->content);
        return undef;
    }
}

__PACKAGE__->meta->make_immutable();

__END__

=head1 NAME

Net::Nakamap - Perl extention to do something

=head1 VERSION

This document describes Net::Nakamap version 0.01.

=head1 SYNOPSIS

    use Net::Nakamap;

=head1 DESCRIPTION

# TODO

=head1 INTERFACE

=head2 Functions

=head3 C<< hello() >>

# TODO

=head1 DEPENDENCIES

Perl 5.8.1 or later.

=head1 BUGS

All complex software has bugs lurking in it, and this module is no
exception. If you find a bug please either email me, or add the bug
to cpan-RT.

=head1 SEE ALSO

L<perl>

=head1 AUTHOR

NAGATA Hiroaki <handlename> E<lt>nagata _at_ handlena _dot_ meE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, NAGATA Hiroaki <handlename>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
