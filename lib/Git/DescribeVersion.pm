package Git::DescribeVersion;
# ABSTRACT: Use git-describe to show a repo's version

=head1 SYNOPSIS

	use Git::DescribeVersion ();
	Git::DescribeVersion->new({opt => 'value'})->version();

Or this one-liner:

	perl -MGit::DescribeVersion::App -e run

See L<Git::DescribeVersion::App> for more examples of that usage.

=cut

use strict;
use warnings;

use Git::Wrapper;
use version 0.77 ();

our %Defaults = (
	first_version 	=> 'v0.1',
	match_pattern 	=> 'v[0-9]*',
#	count_format 	=> 'v0.1.%d',
	version_regexp 	=> '([0-9._]+)'
);

=method new

The constructor accepts a hash or hashref of options:

	Git::DescribeVersion->new({opt => 'value'});
	Git::DescribeVersion->new(opt1 => 'v1', opt2 => 'v2');

See L</OPTIONS> for an explanation of the available options.

=cut

sub new {
	my $class = shift;
	# accept a hash or hashref
	my %opts = ref($_[0]) ? %{$_[0]} : @_;
	my $self = {
		%Defaults,
		# restrict accepted arguments
		map { $_ => $opts{$_} } grep { exists($opts{$_}) } keys %Defaults
	};
	# accept a Git::Wrapper object or initialize one with 'directory'
	$self->{git} ||= $opts{git_wrapper} ||
		Git::Wrapper->new($opts{directory} || '.');
	bless $self, $class;
}

=method parse_version

A method to take the version parts found and return the end result.

Uses the L<version|version> module to parse.

=cut

sub parse_version {
	my ($self, $prefix, $count) = @_;

	# s//$1/ requires the regexp to be anchored.
	# Doing a match and then assigning to $1 does not.
	if( $self->{version_regexp} && $prefix =~ /$self->{version_regexp}/ ){
		$prefix = $1;
	}

	# quote 'version' to reference the module and not call the local sub
	return 'version'->parse("v$prefix.$count")->numify;
		#if $vstring =~ $version::LAX;
}

=method version

The C<version> method is the main method of the class.
It attempts to return the repository version.

It will first use L</version_from_describe>.

If that fails it will try to simulate
the functionality with L</version_from_count_objects>
and will start the count from the L</first_version> option.

=cut

sub version {
	my ($self) = @_;
	return $self->version_from_describe() ||
		$self->version_from_count_objects();
}

=method version_from_describe

Use C<git-describe> to count the number of commits since the last
tag matching L</match_pattern>.

It effectively calls

	git describe --tags --long --match "${match_pattern}"

If no matching tags are found (or some other error occurs)
it will return undef.

=cut

sub version_from_describe {
	my ($self) = @_;
	my ($ver) = eval {
		$self->{git}->describe(
			{match => $self->{match_pattern}, tags => 1, long => 1}
		);
	};
	# usually you'll expect a tag to be found, so warn if it isn't
	if( my $error = $@ ){
		chomp($error);
		warn("git-describe: $error\n");
	}

	# return nothing so we know to move on to count-objects
	return unless $ver;

	# ignore the -gSHA
	my ($tag, $count) = ($ver =~ /^(.+?)-(\d+)-(g[0-9a-f]+)$/);

	return $self->parse_version($tag, $count);
}

=method version_from_count_objects

Use C<git-count-objects> to count the number of commit objects
in the repository.  It then appends this count to L</first_version>.

It effectively calls

	git count-objects -v

and sums up the counts for 'count' and 'in-pack'.

=cut

sub version_from_count_objects {
	my ($self) = @_;
	my @counts = $self->{git}->count_objects({v => 1});
	my $count = 0;
	local $_;
	foreach (@counts){
		/(count|in-pack): (\d+)/ and $count += $2;
	}
	return $self->parse_version($self->{first_version}, $count);
}

1;

=head1 OPTIONS

These options can be passed to L</new>:

=head2 directory

Directory in which git should operate.  Defaults to ".".

=head2 first_version

If the repository has no tags at all, this version
is used as the first version for the distribution.

Then git objects will be counted
and appended to create a version like C<v0.1.5>.

Defaults to C<< v0.1 >>.

=head2 version_regexp

Regular expression that matches a tag containing
a version.  It must capture the version into C<$1>.

Defaults to C<< ([0-9._]+) >>
which will simply capture the first dotted-decimal found.
This matches tags like C<v0.1>, C<rev-1.2>
and even C<release-2.0-skippy>.

=head2 match_pattern

A shell-glob-style pattern to match tags.
This is passed to C<git-describe> to help it
find the right tag from which to count commits.

Defaults to C<< v[0-9]* >>.

=head1 HISTORY / RATIONALE

This module started out as a line in a Makefile:

	VERSION = $(shell (cd $(srcdir); \
		git describe --match 'v[0-9].[0-9]' --tags --long | \
		grep -Eo 'v[0-9]+\.[0-9]+-[0-9]+' | tr - . | cut -c 2-))

As soon as I wanted it in another Makefile
(in another repository) I knew I had a problem.

Then when I started learning L<Dist::Zilla>
I found L<Dist::Zilla::Plugin::Git::NextVersion>
but missed the functionality I was used to with C<git-describe>.

I started by forking L<Dist::Zilla::Plugin::Git> on github,
but realized that if I wrote the logic into a L<Dist::Zilla> plugin
it wouldn't be available to my git repositories that weren't Perl distributions.

So I wanted to extract the functionality to a module,
make a separate L<Dist::Zilla::Role::VerionProvider> plugin,
and include a quick version that could be run with a minimal
command line statement (so that I could put I<that> in my Makefiles).

=head1 TODO

=for :list
* An attribute for specifying the output as floating point or dotted decimal.
* Allow for more complex regexps (multiple groups) if there is a need.
* Options for raising errors versus swallowing them?

=head1 SEE ALSO

=for :list
* L<Git::DescribeVersion::App>
* L<Dist::Zilla::Plugin::Git::DescribeVersion>
* L<Git::Wrapper>
* L<http://www.git-scm.com>
* L<version>

=cut
