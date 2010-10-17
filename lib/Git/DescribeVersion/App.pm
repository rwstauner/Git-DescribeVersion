package Git::DescribeVersion::App;
# ABSTRACT: Provide a simple way to run Git::DescribeVersion as an app

use strict;
use warnings;
use Git::DescribeVersion ();

# simple: enable `perl -MGit::DescribeVersion::App -e run`
sub import {
	*main::run = \&run;
}

sub run {
	my $opts = {};
	foreach my $opt ( keys %Git::DescribeVersion::Defaults ){
		my $eopt = "\UGIT_DV_$opt";
		$opts->{$opt} = $ENV{$eopt} if exists($ENV{$eopt});
	}

	print Git::DescribeVersion->new('.', $opts)->version, "\n";
}

1;

=head1 SYNOPSIS

Print out the version from L<Git::DescribeVersion> in one line:

	perl -MGit::DescribeVersion::App -e run

=cut
