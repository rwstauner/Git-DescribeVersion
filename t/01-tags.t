use strict;
use warnings;
use Test::More;

use FindBin;
use lib "$FindBin::Bin/lib";
use GitDVTest;

my @tags = @versions;
plan tests => @commits * @tags;

my $mock = mock_gw;
use Git::DescribeVersion;
my $gv = Git::DescribeVersion->new(git_wrapper => $mock);

foreach my $commits ( @commits ){
	$mock->set_series('describe', map { "$$_[0]-${commits}-gdeadbeef" } @tags);
	foreach my $tag ( @tags ){
		my ($key, $val) = @$tag;
		my $exp = sprintf("%s%03d", $val, $commits);
		is($gv->version, $exp, sprintf("describe %-15s as %-15s", "$key-${commits}", $exp));
	}
}
