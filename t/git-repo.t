# vim: set ts=2 sts=2 sw=2 expandtab smarttab:
use strict;
use warnings;
use Test::More;
use Git::DescribeVersion ();
use File::Temp qw( tempdir );

plan skip_all => '"git" command not available'
  if system("git --version") != 0;

plan tests => 3 * 2;

my $dir = tempdir( UNLINK => 1 );
chdir $dir or die "failed to chdir: $!";

my $path = 'git-dv.txt';
append($path, 'foo');

system { $_->[0] } @$_ for (
  [qw(git init)],
  [qw(git add), $path],
  [qw(git commit -m foo)],
  [qw(git tag -a -m v1 v1.001)],
);

append($path, 'bar');
system { 'git' } (qw(git commit -m bar), $path);

my $exp_version = '1.001001';

test_all();
{
  # test operations with alternate record separator (rt-71622)
  local $/ = "\n\n";
  test_all();
}

sub test_all {
  SKIP: {
    skip 'Git::Repository not available' => 1
      if ! eval { require Git::Repository };

    my $gdv = Git::DescribeVersion->new(git_repository => 1);
    is $gdv->version, $exp_version, 'tag from Git::Repository';
  }

  SKIP: {
    skip 'Git::Wrapper not available' => 1
      if ! eval { require Git::Wrapper };

    my $gdv = Git::DescribeVersion->new(git_wrapper => 1);
    is $gdv->version, $exp_version, 'tag from Git::Wrapper';
  }

  {
    my ($opt, $mod) = qw(git_backticks backticks);

    my $gdv = Git::DescribeVersion->new(git_backticks => 1);
    is $gdv->version, $exp_version, 'tag from backticks';
  }
}

sub append {
  my $path = shift;
  open(my $fh, '>>', $path)
    or die "failed to open $path: $!";
  print $fh "gdv\n";
  close $fh;
}
