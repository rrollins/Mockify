package MockifyTestBase;

use Mockify;

use base qw( Test::Unit::TestCase );

use strict;



sub new {
    my $class = shift;
    $class = ref($class) || $class;
    my $self = $class->SUPER::new(@_);

    return $self;
}



sub set_up {
    my $self = shift;
    Mockify->setup;

}



use Devel::Symdump;
sub suite {
    my $self = shift;

    my $suite = empty_new Test::Unit::TestSuite;
    my $symdump = new Devel::Symdump(ref($self) || $self);
    foreach my $method ( map{
                            $_ =~ s@.*::test@test@g; $_;
                         } grep { /^.*::test.*/ } $symdump->functions ) {
        $suite->add_test($self->new($method));
    }

    return $suite;
}

package MyExistingClass;
use strict;

sub new { my $c = shift; return bless({}, ref($c) || $c); }
sub existing_method { return join(",", @_); }



1;

