use strict;
use warnings;
use Test::More;
eval "use Test::Output";
plan skip_all => "Test::Output required for testing STDOUT"
	if $@;

use FindBin;
use lib "$FindBin::Bin/lib";
use GitDVTest;

plan tests => @commits * @versions * 2;

my $mock = mock_gw;
use Git::DescribeVersion;
my $gv = {git_wrapper => $mock};

use Git::DescribeVersion::App;

foreach my $commits ( @commits ){
	$mock->set_series('describe', map { ("$$_[0]-${commits}-gdeadbeef") x 2 } @versions);
	foreach my $version ( @versions ){
		my ($exp, $desc) = expectation($gv, $version, $commits);
		stdout_is(sub{ run($gv) }, "$exp\n", $desc);
		stdout_is(sub{ Git::DescribeVersion::App->run($gv) }, "$exp\n", $desc);
	}
}
