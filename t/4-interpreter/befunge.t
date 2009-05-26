#!perl
#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

use strict;
use warnings;

use Language::Befunge;

use Test::More tests => 10;
use Test::Output;

my $bef;


# basic constructor.
$bef = Language::Befunge->new( {file => "t/_resources/q.bf"} );
stdout_is { $bef->run_code } '', 'constructor works';


# debug tests.
stderr_is { $bef->debug( "foo\n" ) } '',      'DEBUG is off by default';
$bef->set_DEBUG(1);
stderr_is { $bef->debug( "bar\n" ) } "bar\n", 'debug warns properly when DEBUG is on';
$bef->set_DEBUG(0);
stderr_is { $bef->debug( "baz\n" ) } '',      'debug does not warn when DEBUG is off';


# basic reading.
$bef = Language::Befunge->new;
$bef->read_file( 't/_resources/q.bf' );
stdout_is { $bef->run_code } '', 'basic reading';


# reading a non existent file.
eval { $bef->read_file( '/dev/a_file_that_is_not_likely_to_exist' ); };
like( $@, qr/line/, 'reading a non-existent file barfs' );


# basic storing.
$bef->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
stdout_is { $bef->run_code } '', 'basic storing';


# interpreter must treat non-characters as if they were an 'r' instruction.
$bef->store_code( <<'END_OF_CODE' );
01-b0p#q1.2 q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'non-chars treated as "r" instruction';


# interpreter must treat non-commands as if they were an 'r' instruction.
$bef->store_code( <<'END_OF_CODE' );
01+b0p#q1.2 q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'non-commands treated as "r" instruction';


# befunge interpreter treats high/low instructions as unknown characters.
$bef->store_code( <<"END_OF_CODE" );
1#q.2h3.q
END_OF_CODE
stdout_is { $bef->run_code } '1 2 ', 'high/low treated as "r" instruction';

