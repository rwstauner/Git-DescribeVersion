package GitDVTest;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(
	&mock_gw
	@versions
	@commits
	@counts
);
use Test::MockObject::Extends;

sub mock_gw () {
	return Test::MockObject::Extends->new( Git::Wrapper->new(".") );
}

# Should we be using version->parse->numify
# instead of specifying the expectation explicitly?

# make sub-arrays like (['v0.1', '0.001'])
our @versions = map { [(split(/\s+/))[1,2]] } split(/\n/, <<TAGS);
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
TAGS

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
