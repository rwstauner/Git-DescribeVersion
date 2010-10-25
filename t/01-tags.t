use strict;
use warnings;
use Test::More;
use Test::MockObject::Extends;

# make sub-arrays like (['v0.1', '0.001'])
my @tags = map { [(split(/\s+/))[1,2]] } split(/\n/, <<TAGS);
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
TAGS

my @commits = qw(8 12 135);
plan tests => @commits * @tags;

my $mod = 'Git::Wrapper';
my $mock = Test::MockObject::Extends->new( $mod->new(".") );
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
