#!perl

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Test::More tests => 1;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$ip->set_string_mode(0); # force no string_mode
$lbi->set_curip( $ip );
Language::Befunge::Ops::str_enter_string_mode( $lbi );
is( $ip->get_string_mode, 1, 'str_enter_string_mode sets string_mode' );
