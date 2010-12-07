use strict;
use warnings;
use Test::More;

my @tests = (
	[1,           2, '1.002000',    {}],
	[1.2,         3, '1.002003',    {}],
	[undef,   undef, '0.001000',    {}],
	[undef,   undef, '2.001000',    {first_version => '2.1'}],
	[undef,   undef, '2.001002000', {first_version => '2.1.2'}],
	[undef,       3, '2.001003',    {first_version => '2.1'}],
	[undef,       4, '2.001003004', {first_version => '2.1.3'}],
	[3.4,     undef, '3.004000',    {first_version => '2.1.3'}],
	['3.4.4', undef, '3.004004000', {}],
	[undef,   undef, undef,         {first_version => undef}],
);

# TODO: handle and test bad strings

plan tests => @tests * 2 + 1; # tests * (is + isa) + require_ok

my $mod = 'Git::DescribeVersion';
require_ok($mod);

foreach my $test ( @tests ){
	my ($prefix, $count, $exp, $opts) = @$test;
	my $gdv = $mod->new($opts);
	isa_ok($gdv, $mod);
	# TODO: test stderr ?
	diag("warning expected:") if !defined $exp;
	is($gdv->parse_version($prefix, $count), $exp, 'parse_version');
}
