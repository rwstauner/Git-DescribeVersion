use Test::More tests => 2;

BEGIN {
	our $mod = 'Git::DescribeVersion';
	use_ok( $mod );
}

diag( "Testing $mod ${$mod . '::VERSION'}, Perl $], $^X" );

# Test constructor as suggested in Kwalitee Checklist
# (http://qa.perl.org/phalanx/kwalitee.html).
# Also smoke test for sensible default arguments (perlmodstyle).

my $obj = $mod->new();
isa_ok($obj, $mod, 'default constructor');
