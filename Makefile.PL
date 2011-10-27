use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;

name 'Test-Fake-HTTPD';
license 'perl';
all_from 'lib/Test/Fake/HTTPD.pm';

requires 'HTTP::Daemon';
requires 'HTTP::Message::PSGI';
requires 'Test::TCP';
requires 'URI';
requires 'Time::HiRes';
requires 'Scalar::Util' => 1.14;
requires 'Carp';
requires 'Exporter';

tests 't/*.t';
test_requires 'Test::More' => 0.98;
test_requires 'Test::UseAllModules';
test_requires 'Test::Flatten';
test_requires 'Test::Exception';
test_requires 'Test::TCP';
test_requires 'LWP::UserAgent';

recursive_author_tests 'xt';
auto_set_repository;
readme_pod_from 'lib/Test/Fake/HTTPD.pm';

WriteAll;
