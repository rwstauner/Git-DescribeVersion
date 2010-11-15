package Git::DescribeVersion::App;
# ABSTRACT: run Git::DescribeVersion as one-line script

use strict;
use warnings;
use Git::DescribeVersion ();

# simple: enable `perl -MGit::DescribeVersion::App -e run`
sub import {
	*main::run = \&run;
}

sub run {
	my %env;
	my %args = ref($_[0]) ? %{$_[0]} : @_;
	foreach my $opt ( keys %Git::DescribeVersion::Defaults ){
		# look for $ENV{GIT_DV_OPTION}
		my $eopt = "\UGIT_DV_$opt";
		$env{$opt} = $ENV{$eopt} if exists($ENV{$eopt});
	}

	print Git::DescribeVersion->new({%env, %args})->version, "\n";
}

1;

=head1 SYNOPSIS

Print out the version from L<Git::DescribeVersion> in one line:

	perl -MGit::DescribeVersion::App -e run

Arguments can be passed in a hash or hashref just like the constructor:

	perl -MGit::DescribeVersion::App -e 'run(match_pattern => "rev-*")'

Or can be environment variables spelled like I<GIT_DV_OPTION>:

	export GIT_DV_MATCH_PATTERN="rev-*"
	perl -MGit::DescribeVersion::App -e run

This (hopefully) makes it easy for you to write
the alias, function, Makefile or script that does exactly what you want.

If not, feel free to send me suggestions (or patches)
that you think would make it simpler or more powerful.

=method run

Convenience method for writing one-liners.

Exported to main package.

Accepts arguments in a hash or hashref
which are passed to the constructor.

Also looks for arguments in %ENV.

See L</SYNOPSIS>.

=cut
