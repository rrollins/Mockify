
package Mockify::Mock;
use Carp qw(carp croak);


use strict;

sub new {
  my $class = shift;
  my $manager = shift;
  my $method_name  = shift;
  my $parent = shift;

  return bless({
    manager => $manager,
    method_name => $method_name,
    parent => $parent,
  }, ref($class) || $class);
}

sub args_key { my $self = shift; return join("#,#", @_); } # TODO rewrite this
sub method_name { my $self = shift; return $self->{method_name}; }
sub manager { my $self = shift; return $self->{manager}; }
sub parent { my $self = shift; return $self->{parent}; }
sub package { my $self = shift; return $self->manager->package; }
sub method {
  my $self = shift;
  my ($instance, @args) = @_; 
  my $m = $self->{method} || return;
  return sub {
    $self->{run_count}++;
    die("$instance attempted to run ".$self->method_name
        ." ".$self->run_count." times"
        ." but the limit is ".$self->at_most) if($self->at_most && $self->run_count > $self->at_most);
    &$m(@_);
  };  
}

sub run_count { my $self = shift; return $self->{run_count} || 0; }
sub reset_counts { my $self = shift; $self->{run_count} = 0; }

sub runs {
  my $self  = shift;
  my $sub = shift;

  $self->{method} = $sub;
  return $self;
}

sub returns {
  my $self  = shift;
  my $value = shift;

  $self->runs(sub { $value; }); 
  return $self;
}

sub n_times { my $self = shift; my $n = shift; $self->at_least($n); $self->at_most($n); }

sub at_least { 
  my $self = shift; 
  my $at_least = shift;
  if($at_least) {
    $self->{at_least} = $at_least;
    $self->reset_counts;
  }
  return $self->{at_least};
}


sub at_most {
  my $self = shift;
  my $at_most = shift;
  if($at_most) {
    $self->{at_most} = $at_most;
    $self->reset_counts;
  }
  return $self->{at_most};
}

sub register_mock_when_passed {
  my $self = shift;
  my $mock = shift;
  my @args = @_;
  my $key = $self->args_key(@args);
  $self->{mock_when_passed}{$key} = $mock;
}

sub get_mock_when_passed {
  my $self = shift;
  my @args = @_;

  my $key = $self->args_key(@args);
  return $self->{mock_when_passed}{$key} || ($self->method ? $self : undef);
}

sub when_passed {
  my $self = shift;
  my @args = @_;

  my $mock = $self;
  if($self->parent) {
    return $self->parent->when_passed(@args);
  } else {
    $mock = new Mockify::Mock($self->manager, $self->method_name, $self);
    $self->register_mock_when_passed($mock, @args);
  }

  return $mock;
}

sub child_mocks {
  my $self = shift;
  return values %{$self->{mock_when_passed}};
}

sub verify {
  my $self = shift;
  die("Ran ".$self->method_name." ".$self->run_count." times"
      ." but expected ".$self->at_least) if($self->at_least && $self->run_count < $self->at_least);
  foreach my $child_mock ($self->child_mocks) { $child_mock->verify; }
}

our $AUTOLOAD;
sub AUTOLOAD {
  my $self = shift;
  my $name = $AUTOLOAD;
  $name =~ s/.*://;   # strip fully-qualified portion

  my ($at_least, $at_most, $n);

  if($name =~ /^at_least_([\w_]+)$/)   { $at_least = 1; $name = "$1"; }
  elsif($name =~ /^at_most_([\w_]+)$/) { $at_most = 1;  $name = "$1"; }

  if   ($name eq 'once') { $n = 1; }
  elsif($name eq 'twice') { $n = 2; }
  elsif($name =~ /^exactly_(\d+)_?times?$/) { $n = "$1"; }

  if   ($at_least) { return $self->at_least($n);}
  elsif($at_most)  { return $self->at_most($n); }
  else             { return $self->n_times($n); }
}







package Mockify;
use Carp qw(carp croak);
use Devel::Symdump;

our $VERSION = 1;

use strict;

sub setup {
  my $class = shift;
  for my $p (Devel::Symdump->rnew->packages) { $class->mockify($p); }
}

sub new {
  my $class = shift;
  my $package = shift;
  return bless({
    mocks => {},
    package => $package,
  }, ref($class) || $class);
}

sub package { my $self = shift; return $self->{package}; }

sub mock_method_names {
  my $self = shift;
  return keys %{$self->{mocks}};
}

sub get_mock {
  my $self = shift;
  my $method_name = shift;
  my $instance = shift;
  my @args = @_;
  my $mock = $self->{mocks}{$method_name}{$instance} ||= new Mockify::Mock($self, $method_name);
  return $mock->get_mock_when_passed(@args) || $mock;
}

sub each_mock {
  my $self = shift;
  my $run_me = shift;

  foreach my $method_name ($self->mock_method_names) {
    foreach my $mock (values %{$self->{mocks}{$method_name}}) { &$run_me($mock); }
  }
}

sub original_method_for {
  my $self = shift;
  my $method_name = shift;
  my $method = shift;

  $self->{original_method_for}{$method_name} = $method if $method;
  return $self->{original_method_for}{$method_name};
}


sub mockify {
  my $class = shift;
  my $package = shift;
  no strict 'refs';
  no warnings 'redefine';

  ${$package.'::_mock_manager'} = new Mockify($package);
  *{$package.'::mock_verify'} = sub { ${$package.'::_mock_manager'}->verify($class); };
  *{$package.'::mock'} = sub {
    my $instance = shift;
    my $method_name = pop;
    my $manager = ${$package.'::_mock_manager'};

    # Save our original method
    if($package->can($method_name) && !$manager->original_method_for($method_name)) {
      my $original_method = \&{$package.'::'.$method_name};
      $manager->original_method_for($method_name, $original_method);
    }

    *{$package.'::'.$method_name} = sub {
      my ($self, @args) = @_;

      # look up the mock, if we can't find one then just call the original
      # method
      my $mock = $manager->get_mock($method_name, $self, @args);
      if(ref($self) && !defined($mock->method(@_))) {
        $mock = $manager->get_mock($method_name, ref($self), @args);
      }

      if($mock && (my $mock_method = $mock->method(@_))) {
        return $mock_method->(@_);
      }

      my $original_method = $manager->original_method_for($method_name);
      croak("Can't locate object method \"$method_name\""
        ." via package \"$package\"") unless $original_method;
      return $original_method->(@_);
    };

    return $manager->get_mock($method_name, $instance);
  };
}

sub verify {
  my $self = shift;
  my $instance = shift;

  $self->each_mock(sub {
    my $self = shift;
    $self->verify;
  });
}

1;
