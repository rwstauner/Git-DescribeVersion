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

use version 0.77 ();

our %Defaults = (
	first_version 	=> 'v0.1',
	match_pattern 	=> 'v[0-9]*',
	format 			=> 'decimal',
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

	$self->{directory} = $opts{directory} || '.';
	# accept a Git::Repository or Git::Wrapper object (or command to exec)
	# or a simple '1' (true value) to indicate which one is desired
	foreach my $mod ( qw(git_repository git_wrapper git_backticks) ){
		if( $opts{$mod} ){
			$self->{git} = $mod;
			# if it's just a true value leave it blank so we create later
			$self->{$mod} = $opts{$mod}
				unless $opts{$mod} eq '1';
		}
	}
	bless $self, $class;
}

=method git

A method to wrap the git commands.
Attempts to use L<Git::Repository> or L<Git::Wrapper>.
Falls back to using backticks.

=cut

# NOTE: the git* subs are called in list context

sub git {
	my ($self) = @_;
	unless( $self->{git} ){
		# Git::Repository is easier to install than Git::Wrapper
		if( eval 'require Git::Repository; 1' ){
			$self->{git} = 'git_repository';
		}
		elsif( eval 'require Git::Wrapper; 1' ){
			$self->{git} = 'git_wrapper';
		}
		else {
			$self->{git} = 'git_backticks';
		}
	}
	goto &{$self->{git}};
}

sub git_backticks {
	my ($self, $command, @args) = @_;
	warn("'directory' attribute not supported when using backticks.\n" .
		"Consider installing Git::Repository or Git::Wrapper.\n")
			if $self->{directory} && $self->{directory} ne '.';

	my $exec = join(' ',
		map { quotemeta }
			# the external app to run
			($self->{git_backticks} ||= 'git'),
			$command,
			map { ref $_ ? @$_ : $_ } @args
	);

	return (`$exec`);
}

sub git_repository {
	my ($self, $command, @args) = @_;
	(
		$self->{git_repository} ||=
			Git::Repository->new(work_tree => $self->{directory})
	)
		->run($command,
			map { ref $_ ? @$_ : $_ } @args
		);
}

sub git_wrapper {
	my ($self, $command, @args) = @_;
	$command =~ tr/-/_/;
	(
		$self->{git_wrapper} ||=
			Git::Wrapper->new($self->{directory})
	)
		->$command({
			map { ($$_[0] =~ /^-{0,2}(.+)$/, $$_[1]) }
				map { ref $_ ? $_ : [$_ => 1] } @args
		});
}


=method parse_version

A method to take the version parts found and return the end result.

Uses the L<version|version> module to parse.

=cut

sub parse_version {
	my ($self, $prefix, $count) = @_;

	# This is unlikely as it should mean that both git commands
	# returned unexpected output.  If it does happen, don't die
	# trying to parse it, default to first_version.
	$prefix = $self->{first_version}
		unless defined $prefix;
	$count  = 0
		unless defined $count;

	# If still undef (first_version explicitly set to undef)
	# don't die trying to parse it, just return nothing.
	unless( defined $prefix ){
		warn("Version could not be determined.\n");
		return;
	}

	# s//$1/ requires the regexp to be anchored.
	# Doing a match and then assigning to $1 does not.
	if( $self->{version_regexp} && $prefix =~ /$self->{version_regexp}/ ){
		$prefix = $1;
	}

	my $vstring = "v$prefix.$count";

	# quote 'version' to reference the module and not call the local sub
	my $vobject = eval {
		'version'->parse($vstring)
			#if version::is_lax($vstring); # version 0.82
	};

	# Don't die if it's not parseable, just return nothing.
	if( my $error = $@ || !$vobject ){
		$error = $self->prepare_warning($error);
		warn("Version '$vstring' not a valid version string.\n$error");
		return;
	}

	my $format = $self->{format} =~ /dot|normal|v|string/ ? 'normal' : 'numify';
	my $version = $vobject->$format;
	$version =~ s/^v// if $self->{format} =~ /no.?v/;
	return $version;
}

# normalize error message

sub prepare_warning {
	my ($self, $error) = @_;
	return '' unless $error;
	$error =~ s/ at \S+?\.pm line \d+\.?\s*$//;
	chomp($error);
	return $error . "\n";
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

	git describe --match "${match_pattern}" --tags --long

If no matching tags are found (or some other error occurs)
it will return undef.

=cut

sub version_from_describe {
	my ($self) = @_;
	my ($ver) = eval {
		$self->git('describe',
			['--match' => $self->{match_pattern}], qw(--tags --long)
		);
	};
	# usually you'll expect a tag to be found, so warn if it isn't
	if( my $error = $@ ){
		$error = $self->prepare_warning($error);
		warn("git-describe: $error");
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
	my @counts = $self->git(qw(count-objects -v));
	my $count = 0;
	local $_;
	foreach (@counts){
		/(count|in-pack): (\d+)/ and $count += $2;
	}
	return $self->parse_version($self->{first_version}, $count);
}

1;

=for Pod::Coverage git_backticks git_repository git_wrapper prepare_warning

=for stopwords repo's todo

=head1 OPTIONS

These options can be passed to L</new>:

=head2 directory

Directory in which git should operate.  Defaults to ".".

=head2 first_version

If the repository has no tags at all, this version
is used as the first version for the distribution.

Then git objects will be counted
and appended to create a version like C<v0.1.5>.

If set to C<undef> then L</version> will return undef
if L</version_from_describe> cannot determine a value.

Defaults to C<< v0.1 >>.

=head2 format

Specify the output format for the version number.

I had trouble determining the most reasonable names
for the formats so a few variations are possible.

=for :list
* I<dotted>, I<normal>, I<v-string> or I<v>
for values like C<< v1.2.3 >>.
* I<no-vstring> (or I<no-v> or I<no_v>)
to discard the opening I<v> for values like C<< 1.2.3 >>.
* I<decimal>
for values like C<< 1.002003 >>.

Defaults to I<decimal> for compatibility.

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
* Allow for more complex regexps (multiple groups) if there is a need.
* Options for raising errors versus swallowing them?
* Consider a dynamic installation to test C<`git --version`>.

=head1 SEE ALSO

=for :list
* L<Git::DescribeVersion::App>
* L<Dist::Zilla::Plugin::Git::DescribeVersion>
* L<Git::Repository> or L<Git::Wrapper>
* L<http://www.git-scm.com>
* L<version>

=cut
