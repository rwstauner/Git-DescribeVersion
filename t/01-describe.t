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
		my ($key, $val, $regexp) = @$version;
		# hack
		$gv->{version_regexp} = $regexp ||
			$Git::DescribeVersion::Defaults{version_regexp};
		my $exp = sprintf("%s%03d", $val, $commits);
		is($gv->version, $exp, sprintf("describe %-15s as %-15s", "$key-${commits}", $exp));
	}
}
