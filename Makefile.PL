use inc::Module::Install;
use Module::Install::AuthorTests;
use Module::Install::Repository;
use Module::Install::ReadmePodFromPod;

name 'Test-Fake-HTTPD';
license 'perl';
all_from 'lib/Test/Fake/HTTPD.pm';

# requires '';

tests 't/*.t';
test_requires 'Test::More';
test_requires 'Test::UseAllModules';

recursive_author_tests 'xt';
auto_set_repository;
readme_pod_from 'lib/Test/Fake/HTTPD.pm';

WriteAll;
