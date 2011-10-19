# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use Git::DescribeVersion ();
use File::Temp qw( tempdir );

plan skip_all => '"git" command not available'
  if system("git --version") != 0;

plan tests => 3;

my $dir = tempdir( UNLINK => 1 );
chdir $dir or die "failed to chdir: $!";

my $path = 'git-dv.txt';
{
  open(my $fh, '>', $path)
    or die "failed to open $path: $!";
  print $fh "gdv\n";
  close $fh;
}
system { $_->[0] } @$_ for (
  [qw(git init)],
  [qw(git add), $path],
  [qw(git commit -m foo)],
  [qw(git tag v1.000)],
);

my $exp_version = '1.000000';

test_all();

sub test_all {
  SKIP: {
    skip 1 => 'Git::Repository not available'
      if ! eval { require Git::Repository };

    my $gdv = Git::DescribeVersion->new(git_repository => Git::Repository->new(work_tree => "."));
    is $gdv->version, $exp_version, 'tag from Git::Repository';
  }

  SKIP: {
    skip 1 => 'Git::Wraper not available'
      if ! eval { require Git::Wrapper };

    my $gdv = Git::DescribeVersion->new(git_wrapper => Git::Wrapper->new("."));
    is $gdv->version, $exp_version, 'tag from Git::Wrapper';
  }

  {
    my ($opt, $mod) = qw(git_backticks backticks);

    my $gdv = Git::DescribeVersion->new(git_backticks => 'git');
    is $gdv->version, $exp_version, 'tag from backticks';
  }
}
