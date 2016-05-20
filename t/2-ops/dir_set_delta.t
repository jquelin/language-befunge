#!perl

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Language::Befunge::Vector;
use Test::More tests => 1;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(4,4);
$ip->set_delta( $v );
$ip->spush( 2, 3 );
$lbi->set_curip( $ip );
Language::Befunge::Ops::dir_set_delta( $lbi );
is( $ip->get_delta, '(2,3)', 'dir_set_delta set delta after values from the stack' );
