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
    my ($self, $path, $params, $files) = @_;

    $params ||= {};

    my $token = $params->{token} || $self->token;
    $params->{token} = $token if $token;

    my $res;

    if ($files) {
        for my $name (keys %$files) {
            my $file = $files->{$name};

            if (ref $file) {
                $params->{$name} = [
                    undef,
                    'upload',
                    'Content-Type' => 'application/octet-stream',
                    'Content'      => $$file,
                ];
            }
            else {
                $params->{$name} = [$files->{$name}];
            }
        }

        $res = $self->ua->request(
            POST $self->api_ep . $path,
            Content_Type => 'form-data',
            Content      => [%$params],
        );
    }
    else {
        my $uri = URI->new($self->api_ep . $path);
        $uri->query_form(%$params);

        $res = $self->ua->post($uri);
    }

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

=head1 ATTENTION

THIS MODULE IS UNDER CONSTRUCTION.
INTERFACES AND RESPONCES ARE NOT STABLE.

=head1 NAME

Net::Nakamap - Perl extention to do something

=head1 VERSION

This document describes Net::Nakamap version 0.01.

=head1 SYNOPSIS

    use Net::Nakamap;

    my $nakamap = Net::Nakamap->new(
        client_id     => $client_id,
        client_secret => $client_secret,
    );

    # generate uri for authentication
    my $auth_uri = $nakamap->auth_uri();

    # get access token
    my $res   = $nakamap->auth_code({ code => $code });
    my $token = $res->{access_token};

    # GET
    my $me = $nakamap->get('/1/me', { token => $token });

    # POST
    $nakamap->post('/1/me/profile', {
        token => $token,
        name  => 'Alice',
    });

=head1 DESCRIPTION

Tiny helper for using Nakamap API.

=head1 METHODS

=over

=item $nakamap = Net::Nakamap->new(%options)

Creates a new Net::Nakamap instance.

options:

=over

=item * C<client_id>

=item * C<client_secret>

=item * C<token>

=back

=item $nakamap->auth_uri($params)

Generate uri for authentication.
Returns URI object.

params:

=over

=item * C<response_type>

=item * C<scope>

=back

=item $nakamap->auth_code($code)

Authenticate authorization code.
Returns hash including token.

=item $nakamap->get($path, $params)

=item $nakamap->post()

=back

=head1 SEE ALSO

https://github.com/nakamap/docs/wiki/Api-docs

=head1 AUTHOR

NAGATA Hiroaki <handlename> E<lt>nagata _at_ handlena _dot_ meE<gt>

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2013, NAGATA Hiroaki <handlename>. All rights reserved.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
