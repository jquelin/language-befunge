#!perl

use strict;
use warnings;

use Test::More tests => 15;

BEGIN { use_ok( 'Language::Befunge' ); }
diag( "Testing Language::Befunge $Language::Befunge::VERSION, Perl $], $^X" );
BEGIN { use_ok( 'Language::Befunge::Debug' ); }
BEGIN { use_ok( 'Language::Befunge::Interpreter' ); }
BEGIN { use_ok( 'Language::Befunge::IP' ); }
BEGIN { use_ok( 'Language::Befunge::Ops' ); }
BEGIN { use_ok( 'Language::Befunge::Ops::Befunge98' ); }
BEGIN { use_ok( 'Language::Befunge::Ops::GenericFunge98' ); }
BEGIN { use_ok( 'Language::Befunge::Ops::Unefunge98' ); }
BEGIN { use_ok( 'Language::Befunge::Storage' ); }
BEGIN { use_ok( 'Language::Befunge::Storage::2D::Sparse' ); }
BEGIN { use_ok( 'Language::Befunge::Storage::Generic::AoA' ); }
BEGIN { use_ok( 'Language::Befunge::Storage::Generic::Sparse' ); }
BEGIN { use_ok( 'Language::Befunge::Storage::Generic::Vec' ); }
BEGIN { use_ok( 'Language::Befunge::Vector' ); }
BEGIN { use_ok( 'Language::Befunge::Wrapping::LaheySpace' ); }

exit;
