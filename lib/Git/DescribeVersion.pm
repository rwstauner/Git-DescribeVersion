package Git::DescribeVersion;
# ABSTRACT: Use git-describe to determine a git repo's version

use strict;
use warnings;

use Git::Wrapper;
use version 0.77 ();

our %Defaults = (
	match_pattern 	=> 'v[0-9]*',
	version_regexp 	=> '^(v.+)$'
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
	return $self->version_from_describe();
}

sub parse_version {
  my ($self, $prefix, $count) = @_;
  # quote 'version' to reference the module and not call the local sub
  return 'version'->parse("$prefix.$count")->numify;
    #if $vstring =~ $version::LAX;
}

sub version_from_describe {
	my ($self) = @_;
	my ($ver) = eval {
		$self->{git}->describe({match => $self->{match_pattern}, tags => 1, long => 1})
	} or return undef;

	# ignore the -gSHA
	my ($tag, $count) = ($ver =~ /^(.+?)-(\d+)-(g[0-9a-f]+)$/);
	$tag =~ s/$self->{version_regexp}/$1/;

	return $self->parse_version($tag, $count);
}

1;
