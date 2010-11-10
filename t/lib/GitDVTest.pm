package GitDVTest;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	&expectation
	&mock_gw
	@versions
	@commits
	@counts
);
use Test::MockObject::Extends;

sub expectation ($$$) {
	my ($gv, $version, $count) = @_;
	my ($key, $val, $regexp) = @$version;

	# hack
	$gv->{version_regexp} = $regexp ||
		$Git::DescribeVersion::Defaults{version_regexp};

	my $exp = sprintf("%s%03d", $val, $count);
	#$exp = sprintf("%0.6f", $exp) if length(substr($exp, rindex($exp, '.')+1)) < 6;
	my $desc = sprintf("describe %-15s as %-15s", "$key-$count", $exp);
	return ($exp, $desc);
}

sub mock_gw () {
	return Test::MockObject::Extends->new( Git::Wrapper->new(".") );
}

# Should we be using version->parse->numify
# instead of specifying the expectation explicitly?

# make sub-arrays like (['v0.1', '0.001', 'version_regexp'])
our @versions = map { [(split(/\s+/))[1, 2, 3]] } split(/\n/, <<TAGS);
	v0.1        0.001
	v0.001      0.001
	v1.2        1.002
	v1.20       1.020
	v1.200      1.200
	v1.02       1.002
	v1.002      1.002
	v1.2.3      1.002003
	v1.02.03    1.002003
	v1.002003   1.2003
	v2.1        2.001
	v2.1234     2.1234
	ver-0.012   0.012   ver-(.+)
	ver-0.012   0.012
	ver|3.222   3.222   ver\\|(.+)
	ver|3.222   3.222
	4.1-rel1021   4.001   ([0-9.]+)-rel.+
	4.1-rel1021   4.001
	4.1-rel10.21  10.021  rel(\\S+)
	release-1.2-narf    1.002
	release-1.4.2-narf  1.004  \\w+-([0-9.]+)\\.\\d-narf
	SILLY1.4TAG   1.004
	date-12.05-ver-10.21-foo  10.021  date-[0-9.]+-ver-([0-9.]+)-\\w+
	date-12.05-ver-10.21-foo  12.005
TAGS
	#release-1.2-narf    1.     \\w+-(\\d+)\\.\\d-narf

our @commits = qw(8 12 49 99 135 999 1234);

# make sub-arrays like (['0', 'count: 0', 'size: 0'])
our @counts = map { [split(/\n/)] } split(/\n\n/, <<COUNTS);
204
count: 204
size: 816
in-pack: 0
packs: 0
size-pack: 0
prune-packable: 0
garbage: 0

1006
count: 604
size: 816
in-pack: 402

999
count: 999
in-pack: 0

322
count: 222
in-pack: 100

24
count: 24

7
in-pack: 7
COUNTS
