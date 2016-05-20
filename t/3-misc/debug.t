#!perl

use strict;
use warnings;

use Language::Befunge::Debug;

use Test::More tests => 3;
use Test::Output;


# debug tests.
stderr_is { debug( "foo\n" ) } '',      'debug disabled by default';
Language::Befunge::Debug::enable();
stderr_is { debug( "bar\n" ) } "bar\n", 'debug warns properly when debug is enabled';
Language::Befunge::Debug::disable();
stderr_is { debug( "baz\n" ) } '',      'debug does not warn when debug is disabled';
