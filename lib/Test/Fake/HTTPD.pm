package Test::Fake::HTTPD;

use 5.008_001;
use strict;
use warnings;
use HTTP::Daemon;
use HTTP::Message::PSGI qw(res_from_psgi);
use Test::TCP qw(wait_port);
use URI;
use Time::HiRes ();
use Scalar::Util qw(blessed weaken);
use Carp qw(croak);
use Exporter qw(import);

our $VERSION = '0.01';
$VERSION = eval $VERSION;

our @EXPORT = qw(run_http_server);

sub run_http_server (&) {
    my $app = shift;
    __PACKAGE__->new->run($app);
}

sub new {
    my ($class, %args) = @_;
    bless { timeout => 5, listen => 5, %args }, $class;
}

sub run {
    my ($self, $app) = @_;

    $self->{server} = Test::TCP->new(
        code => sub {
            my $port = shift;

            my $d;
            for (1..10) {
                $d = HTTP::Daemon->new(
                    LocalAddr => '127.0.0.1',
                    LocalPort => $port,
                    Timeout   => $self->{timeout},
                    Proto     => 'tcp',
                    Listen    => $self->{listen},
                    ($self->_is_win32 ? () : (ReuseAddr => 1)),
                ) and last;
                Time::HiRes::sleep(0.1);
            }
            croak("Can't accepted on 127.0.0.1:$port") unless $d;

            while (my $c = $d->accept) {
                while (my $req = $c->get_request) {
                    my $res = $self->_to_http_res($app->($req));
                    $c->send_response($res);
                }
                $c->close;
                undef $c;
            }
        },
        ($self->{port} ? (port => $self->{port}) : ()),
    );

    weaken($self);
    $self;
}

sub port {
    my $self = shift;
    return $self->endpoint->port;
}

sub host_port {
    my $self = shift;
    return $self->endpoint->host_port;
}

sub endpoint {
    my $self = shift;
    my $url = sprintf 'http://127.0.0.1:%d', $self->{server} ? $self->{server}->port : 0;
    return URI->new($url);
}

sub _is_win32 { $^O eq 'MSWin32' }

sub _is_psgi_res {
    my ($self, $res) = @_;
    return unless ref $res eq 'ARRAY';
    return unless @$res == 3;
    return unless $res->[0] && $res->[0] =~ /^\d{3}$/;
    return unless ref $res->[1] eq 'ARRAY' || ref $res->[1] eq 'HASH';
    return 1;
}

sub _to_http_res {
    my ($self, $res) = @_;

    my $http_res;
    if (blessed($res) and $res->isa('HTTP::Response')) {
        $http_res = $res;
    }
    elsif (blessed($res) and $res->isa('Plack::Response')) {
        $http_res = res_from_psgi($res->finalize);
    }
    elsif ($self->_is_psgi_res($res)) {
        $http_res = res_from_psgi($res);
    }

    croak(sprintf '%s: response must be HTTP::Response or Plack::Response or PSGI', __PACKAGE__)
        unless $http_res;

    return $http_res;
}

1;

=head1 NAME

Test::Fake::HTTPD - a fake HTTP server

=head1 SYNOPSIS

DSL-style

    use Test::Fake::HTTPD;

    my $httpd = run_http_server {
        my $req = shift;
        # ...

        # 1. HTTP::Response ok
        return $http_response;
        # 2. Plack::Response ok
        return $plack_response;
        # 3. PSGI response ok
        return [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    printf "You can connect to your server at 127.0.0.1:%d.\n", $httpd->port;

    print $httpd->host_port; # "127.0.0.1:nnn"
    print $httpd->endpoint;  # "http://127.0.0.1:nnn"

    # Stop http server automatically at destruction time.

OO-style

    use Test::Fake::HTTPD;

    my $httpd = Test::Fake::HTTPD->new(%args);
    $httpd->run(sub {
        my $req = shift;
        # ...
        [ 200, [ 'Content-Type', 'text/plain' ], [ 'Hello World' ] ];
    });

    # Stop http server automatically at destruction time.

=head1 DESCRIPTION

Test::Fake::HTTPD is a fake HTTP server module for testing.

=head1 METHODS

=over 4

=item new( %args )

Returns a new instance.

  my $httpd = Test::Fake::HTTPD->new(%args);

=item run( $app_coderef )

Starts this HTTP server.

  $httpd->run(sub { ... });

=item port

Returns a port number of running.

  $httpd->port;

=item host_port

Returns a URI host_port of running. ("127.0.0.1:nnn")

  $httpd->host_port;

=item endpoint

Returns an endpoint URI of running. ("http://127.0.0.1:nnn" URI object)

  $httpd->endpoint;

=back

=head1 FUNCTIONS

=over 4

=item run_http_server

Starts HTTP server and returns the guard instance.

  my $httpd = run_http_server {
      my $req = shift;
      # ...
      return $http_or_plack_or_psgi_res;
  };

=back

=head1 AUTHOR

NAKAGAWA Masaki E<lt>masaki@cpan.orgE<gt>

=head1 THANKS TO

xaicron

=head1 LICENSE

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 SEE ALSO

L<Test::TCP>, L<HTTP::Daemon>, L<HTTP::Message::PSGI>

=cut
