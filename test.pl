#!perl -w

use strict;
use lib q(test/lib);

use ClassMethodsTest;

use Test::Unit::TestRunner;
use Test::Unit::TestSuite;
use Test::Unit::HarnessUnit;

use vars qw( @TESTS );

@TESTS = qw(
  ClassMethodsTest
);

foreach my $test_class (@TESTS) {
  Test::Unit::TestRunner->new
                   ->do_run($test_class->new("test")->suite);
}

print "\n";
