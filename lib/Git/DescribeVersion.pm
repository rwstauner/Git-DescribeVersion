package Git::DescribeVersion;
# ABSTRACT: Use git-describe to determine a git repo's version

use strict;
use warnings;

use Git::Wrapper;
use version 0.77 ();

our %Defaults = (
	first_version 	=> 'v0.1',
	match_pattern 	=> 'v[0-9]*',
#	count_format 	=> 'v0.1.%d',
	version_regexp 	=> '^v(.+)$'
);

# TODO: attribute for returning dotted-decimal

sub new {
	my ($class, $git, $attr) = @_;
	my $self = {
		git => (ref($git) ? $git : Git::Wrapper->new($git)),
		%Defaults,
		%$attr
	};
	bless $self, $class;
}

sub version {
	my ($self) = @_;
	return $self->version_from_describe() ||
		$self->version_from_count_objects();
}

sub parse_version {
  my ($self, $prefix, $count) = @_;
  # quote 'version' to reference the module and not call the local sub
  return 'version'->parse("v$prefix.$count")->numify;
    #if $vstring =~ $version::LAX;
}

sub version_from_describe {
	my ($self) = @_;
	my ($ver) = eval {
		$self->{git}->describe(
			{match => $self->{match_pattern}, tags => 1, long => 1}
		);
	} or return undef;

	# ignore the -gSHA
	my ($tag, $count) = ($ver =~ /^(.+?)-(\d+)-(g[0-9a-f]+)$/);
	$tag =~ s/$self->{version_regexp}/$1/;

	return $self->parse_version($tag, $count);
}

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
