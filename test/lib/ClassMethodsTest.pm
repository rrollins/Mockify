package ClassMethodsTest;

use MockifyTestBase;

use strict;

use base qw( MockifyTestBase );

sub test_overwrite_method {
  my $self = shift;

  MyExistingClass->mock("existing_method")->returns("abc");
  $self->assert(MyExistingClass->existing_method eq "abc", "existing_method is not overriden" );
  return 1;
}

sub test_class_method_automatically_takes_on_instance_method_when_not_available {
  my $self = shift;

  my $new_instance = new MyExistingClass;
  MyExistingClass->mock("existing_method")->returns("abc");

  $self->assert_equals($new_instance->existing_method, "abc");
  return 1;
}

sub test_mocked_instance_method_takes_precedence_over_mocked_class_method {
  my $self = shift;

  my $new_instance = new MyExistingClass;
  MyExistingClass->mock("existing_method")->returns("abc");
  $new_instance->mock("existing_method")->returns("abc from instance");

   $self->assert_equals($new_instance->existing_method, "abc from instance");
  return 1;
}

sub test_method_mock_call_once_and_twice_on_class_method {
  my $self = shift;
  my $new_instance = new MyExistingClass;
  MyExistingClass->mock("existing_method")->returns("abc")->once;
  MyExistingClass->existing_method;
  eval { MyExistingClass->existing_method; };
  $self->assert(defined($@), "Can only call once");

  MyExistingClass->mock("existing_method")->returns("abc")->twice;
  MyExistingClass->existing_method;
  MyExistingClass->existing_method;
  eval { MyExistingClass->existing_method; };
  $self->assert(defined($@), "Can only call twice");
}

#sub test_other_stuff {
#    my $an_instance = new MyExistingClass;
#    MyExistingClass->mock("i_need_a_server_running")->runs(sub { 1+1; });
#
#    $an_instance->mock("another")->returns("another")->at_least_once;
#    MyExistingClass->mock("another")->runs(sub { 1+1; });
#    
#    $an_instance->mock("existing_method")->returns("mockbed_existing_method on instance")->at_most_once;
#    $an_instance->mock("existing_method")->when_passed(1,2,3)->returns("i am from instance when passed 123");
#    #
#    #MyExistingClass->mock("existing_method")->when_passed(1,2,3)->returns("package passed 1 2 3");
#    #
#    #$an_instance->mock("some_made_up_method")->returns("i am from instance")->once;
#    #MyExistingClass->mock("existing_method")->returns("mockbed_existing_method")->exactly_3_times;
#    #MyExistingClass->mock("some_made_up_method")->returns("default_value")->twice;
#    #MyExistingClass->mock("some_made_up_method")->when_passed(1,2,3)->runs(sub { "i was passed 123"; })->once;
#    
#    #print MyExistingClass->existing_method(1,2,3)."\n";
#    #print $an_instance->another(1,2,3)."\n";
#    #print MyExistingClass->another(1,2,3)."\n";
#    #print MyExistingClass->existing_method(1,2)."\n";
#    #print $an_instance->existing_method(1,2)."\n";
#    #print $an_instance->existing_method(1,2,3)."\n";
#    #print $an_instance->existing_method(1,2,3)."\n";
#    #print $an_instance->existing_method(1,2,3)."\n";
#    
#    #print MyExistingClass->some_made_up_method(1,2,3)."\n";
#    #print MyExistingClass->some_made_up_method."\n";
#    #print $an_instance->some_made_up_method."\n";
#    #print MyExistingClass->existing_method."\n";
#    
#    #MyExistingClass->mock_verify;




1;
