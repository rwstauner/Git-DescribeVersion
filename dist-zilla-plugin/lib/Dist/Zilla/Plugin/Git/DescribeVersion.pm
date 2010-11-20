package Dist::Zilla::Plugin::Git::DescribeVersion;
# ABSTRACT: Provide version using git-describe

# I don't know much about Dist::Zilla or Moose.
# This code copied/modified from Dist::Zilla::Plugin::Git::NextVersion.
# Thanks rjbs and jquelin!

use strict;
use warnings;
use Dist::Zilla 4 ();
use Git::DescribeVersion ();
use Moose;
use namespace::autoclean 0.09;

with 'Dist::Zilla::Role::VersionProvider';

# -- attributes

	while( my ($name, $default) = each %Git::DescribeVersion::Defaults ){
has $name => ( is => 'ro', isa=>'Str', default => $default );
	}

# -- role implementation

sub provide_version {
	my ($self) = @_;

	# override (or maybe needed to initialize)
	return $ENV{V} if exists $ENV{V};

	# less overhead to use %Defaults than MOP meta API
	my $opts = { map { $_ => $self->$_() }
		keys %Git::DescribeVersion::Defaults };

	my $new_ver = eval {
		Git::DescribeVersion->new($opts)->version;
	};

	$self->log_fatal("Could not determine version from tags: $@")
		unless defined $new_ver;

	$self->log("Git described version as $new_ver");

	$self->zilla->version("$new_ver");
}

__PACKAGE__->meta->make_immutable;
no Moose;
1;

=for Pod::Coverage
    provide_version

=head1 SYNOPSIS

In your F<dist.ini>:

	[Git::DescribeVersion]
	match_pattern  = v[0-9]*     ; this is the default

=head1 DESCRIPTION

This does the L<Dist::Zilla::Role::VersionProvider> role.
It uses L<Git::DescribeVersion> to count the number of commits
since the last tag (matching I<match_pattern>) or since the initial commit,
and uses the result as the I<version> parameter for your distribution.

The plugin accepts the same options as
L<< Git::DescribeVersion->new()|Git::DescribeVersion/new >>.
See L<Git::DescribeVersion/OPTIONS>.

You can also set the C<V> environment variable to override the new version.
This is useful if you need to bump to a specific version.  For example, if
the last tag is 0.005 and you want to jump to 1.000 you can set V = 1.000.

  $ V=1.000 dzil release

=head1 SEE ALSO

=for :list
* L<Git::DescribeVersion>
* L<Dist::Zilla>
* L<Dist::Zilla::Plugin::Git::NextVersion>

This code copied/modified from L<Dist::Zilla::Plugin::Git::NextVersion>.

Thanks I<rjbs> and I<jquelin> (and many others)!

=cut
