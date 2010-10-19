use strict;

use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'          => 'Mockify',
    'VERSION_FROM' => 'lib/Mockify.pm',
    'PREREQ_PM' => {
        'Devel::Symdump'     => 1.00,
        'Test::Unit'         => 0,
        'Test::Unit::TestRunner' => 0
      },
);

