use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use GitDVTest;

my @tests = (
	#[1,           2, '1',        'v1',           {}],
	[1.2,         3, '1.002',    'v1.2',         {}],

	[undef,   undef, '0.001',    'v0.1',         {}],

	[undef,   undef, '2.001',    'v2.1',         {first_version => '2.1'}],
	[undef,   undef, '2.001002', 'v2.1.2',       {first_version => '2.1.2'}],

	[undef,       3, '2.001',    'v2.1',         {first_version => '2.1'}],
	[undef,       3, '2.010',    'v2.10',        {first_version => '2.10'}],

	[undef,       4, '2.001003', 'v2.1.3',       {first_version => '2.1.3'}],

	[3.4,     undef, '3.004',    'v3.4',         {}],
	['v3.4',  undef, '3.004',    'v3.4',         {}],
	['3.4.4', undef, '3.004004', 'v3.4.4',       {}],
	['3.4.4',    52, '3.004004', 'v3.4.4',       {}],

	[undef,   undef, undef,         undef,       {first_version => undef}],

	['x',       'y', undef,         undef,       {}],
	[' ',     '201', undef,         undef,       {}],
	['4',     'ppp', undef,         undef,       {}],
);

plan tests => @tests * (3 + 1) + 1; # tests * (formats + isa) + require_ok

my $mod = 'Git::DescribeVersion';
require_ok($mod);

foreach my $test ( @tests ){
	my ($prefix, $count, $dec, $dot, $opts) = @$test;
	my $gdv = $mod->new($opts);
	isa_ok($gdv, $mod);
test_expectations($gdv, [$prefix, $dec, $dot], $count, sub {
	my ($exp, $desc) = @_;
	diag("warning expected:") if !defined $exp;
	is($gdv->parse_version($prefix, $count), $exp, $desc);
});
}
