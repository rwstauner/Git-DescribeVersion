use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use GitDVTest;

plan tests => @counts * @versions;
my $mock = mock_gw;
$mock->set_always('describe', undef);

use Git::DescribeVersion;

foreach my $version ( @versions ){
	my $fv = $$version[0];
	my $gv = Git::DescribeVersion->new(git_wrapper => $mock, first_version => $fv);
	foreach my $count ( @counts ){
		my ($sum, @lines) = @$count;
		$mock->mock('count_objects', sub { @lines });

		my ($key, $val, $regexp) = @$version;
		# hack
		$gv->{version_regexp} = $regexp ||
			$Git::DescribeVersion::Defaults{version_regexp};
		my $exp = sprintf("%s%03d", $val, $sum);
		is($gv->version, $exp, sprintf("describe %-15s as %-15s", "$key-${sum}", $exp));
	}
}
