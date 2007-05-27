#!perl
#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2007 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Module::Build;
my $builder = Module::Build->new
  ( module_name       => 'Language::Befunge',
    license           => 'perl',
    dist_author       => 'Jerome Quelin <jquelin@cpan.org>',
    dist_version_from => 'Befunge.pm',
    build_requires    => { 'Test::More'      => 0 },
    requires          => { 'Storable'        => 0 },
    recommends        => { 'Test::Exception' => 0 },
    script_files      => [ 'bin/jqbf98' ],
    pm_files          =>
      { 'Befunge.pm'               => 'lib/Language/Befunge.pm',
        'Befunge/Interpreter.pm'   => 'lib/Language/Befunge/Interpreter.pm',
        'Befunge/IP.pm'            => 'lib/Language/Befunge/IP.pm',
        'Befunge/LaheySpace.pm'    => 'lib/Language/Befunge/LaheySpace.pm',
        'Befunge/Ops.pm'           => 'lib/Language/Befunge/Ops.pm',
        'Befunge/Vector.pm'        => 'lib/Language/Befunge/Vector.pm',
        'Befunge/lib/FOO.pm'       => 'lib/Language/Befunge/lib/FOO.pm',
        'Befunge/lib/HELO.pm'      => 'lib/Language/Befunge/lib/HELO.pm',
        'Befunge/Ops/Befunge98.pm' => 'lib/Language/Befunge/Ops/Befunge98.pm',
      },
    add_to_cleanup    =>
      [ 'Language-Befunge-*', map { ( '*/' x $_ ) . '*~' } 0..4 ]
    #recursive_test_files => 1
  );
$builder->create_build_script;

