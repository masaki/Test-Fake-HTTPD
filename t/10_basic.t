use Test::More;
use Test::Flatten;
use Test::Exception;
use Test::TCP qw(wait_port);
use LWP::UserAgent;

BEGIN {
    *describe = *it = \&subtest;
}

use Test::Fake::HTTPD;

describe 'run_http_server' => sub {
    my $httpd = run_http_server {
        my $req = shift;
        [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
    };

    it 'should return a port number of running' => sub {
        ok($httpd->port and $httpd->port > 0);
    };

    it 'should connect to server' => sub {
        lives_ok { wait_port($httpd->port) };
    };

    it 'should receive correct response' => sub {
        my $res = LWP::UserAgent->new->get('http://127.0.0.1:'.$httpd->port);
        is $res->code => 200;
        is $res->header('Content-Type') => 'text/plain';
        is $res->content => 'Hello World';
    };
};

done_testing;
