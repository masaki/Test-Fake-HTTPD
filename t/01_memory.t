use Test::More;
use Test::Memory::Cycle;

use Test::Fake::HTTPD;

my $httpd = run_http_server {
    my $req = shift;
    [ 200, [ 'Content-Type' => 'text/plain' ], [ 'Hello World' ] ];
};

memory_cycle_ok $httpd;
memory_cycle_ok $httpd->{server};

done_testing;
