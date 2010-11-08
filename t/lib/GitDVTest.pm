package GitDVTest;
use strict;
use Exporter;
our @ISA = qw(Exporter);
our @EXPORT = qw(@versions @commits);

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
