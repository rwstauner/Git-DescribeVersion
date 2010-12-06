use strict;
use warnings;
use Test::More;
use Git::DescribeVersion ();

# development || dzil test
-d '.git' || -d '../../.git'
	or plan skip_all => 'Skipping tests that require a real git repo';

my $opts = {
	'describe' => {
		# this tag actually exists in this repo
		match_pattern => 'v0.1',
	},
	'count objects' => {
		# this tag does not exist (which will fall through count-objects)
		match_pattern => 'none',
	}
};

my $gdv;
my @tests = (
	[qw(git_repository Git::Repository)],
	[qw(git_wrapper    Git::Wrapper   )],
	[qw(git_backticks)]
);

plan tests => @tests * 3 - 1; # 3 each but no require_ok() on last one

my $git_describe_warning = 'fatal: No names found, cannot describe anything.';
# I tried testing STDERR for the warning but it breaks with Git::Wrapper...
# Git::Repository fixes this on its own
# (see top of Git::Repository::Command source code)
# but it wasn't worth messing with it for this test.
diag("${\ scalar @tests } warnings of '$git_describe_warning' expected.");

foreach my $test ( @tests ){
	my ($opt, $mod) = @$test;
	if( $mod ){
		require_ok($mod)
	}
	else {
		$mod = $opt;
	}

	foreach my $command ( keys %$opts ){
		$gdv = Git::DescribeVersion->new(%{ $opts->{$command} }, $opt => 1);
		like($gdv->version, qr/0.001\d{3,}/, "$mod $command");
	}
}
