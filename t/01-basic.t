#!perl

use 5.010;
use strict;
use warnings;

use Perinci::Access::Schemeless::Hash;
use Test::More 0.98;

my $pa = Perinci::Access::Schemeless::Hash->new(hash => {
    '/'              => [{v=>1.1, 'x.i'=>1}],
    '/Foo/'          => [{v=>1.1, 'x.i'=>2}],
    '/Foo/Bar/'      => [{v=>1.1, 'x.i'=>3}],
    '/Foo/Bar/func1' => [{v=>1.1, summary=>"function 1", args=>{}}],
    '/Foo/Bar/func2' => [{v=>1.1, summary=>"function 2", args=>{}}],
    '/Foo/Bar/Sub/'  => [{v=>1.1, 'i.x'=>4}],
    '/Foo/Baz/'      => [{v=>1.1, 'x.i'=>5}],
    '/Foo/Baz/func3' => [{v=>1.1, summary=>"function 3", args=>{a=>{schema=>["int",{},{}]}}}],
});

test_request(
    name   => "list 1",
    argv   => [list => "/"],
    result => [qw(Foo/)],
);
test_request(
    name   => "list detail 1",
    argv   => [list => "/", {detail=>1}],
    result => [
        {uri => "Foo/", type=>"package"},
    ],
);
test_request(
    name   => "list 2",
    argv   => [list => "/Foo/"],
    result => [qw(Bar/ Baz/)],
);
test_request(
    name   => "list 3",
    argv   => [list => "/Baz/"],
    status => 404,
);

test_request(
    name   => "meta 1",
    argv   => [meta => "/"],
    result => {v=>1.1, 'x.i'=>1},
);
test_request(
    name   => "meta 2",
    argv   => [meta => "/Foo/Bar/func1"],
    result => {v=>1.1, summary=>"function 1", args=>{}},
);
test_request(
    name   => "meta 3",
    argv   => [meta => "/Baz/"],
    status => 404,
);

test_request(
    name   => "child_metas 1",
    argv   => [child_metas => "/Foo/Bar/"],
    result => {
        'Sub/'  => {v=>1.1, 'i.x'=>4},
        'func1' => {v=>1.1, summary=>"function 1", args=>{}},
        'func2' => {v=>1.1, summary=>"function 2", args=>{}},
    },
);

DONE_TESTING:
done_testing;

sub test_request {
    my %args = @_;
    my $name = $args{name} // join(" ", @{ $args{argv} });
    subtest $name => sub {
        my $res = $pa->request(@{ $args{argv} });
        my $exp_status = $args{status} // 200;
        is($res->[0], $exp_status, "status")
            or diag explain $res;
        return unless $exp_status == 200;

        if (exists $args{result}) {
            is_deeply($res->[2], $args{result}, "result")
                or diag explain $res;
        }
    };
}
