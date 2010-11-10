use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use GitDVTest;

plan tests => @commits * @versions;

my $mock = mock_gw;
use Git::DescribeVersion;
my $gv = Git::DescribeVersion->new(git_wrapper => $mock);

foreach my $commits ( @commits ){
	$mock->set_series('describe', map { "$$_[0]-${commits}-gdeadbeef" } @versions);
	foreach my $version ( @versions ){
		my ($exp, $desc) = expectation($gv, $version, $commits);
		is($gv->version, $exp, $desc);
	}
}
