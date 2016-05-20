#!perl

use Language::Befunge::Ops;

use strict;
use warnings;

use Language::Befunge::Interpreter;
use Language::Befunge::IP;
use Language::Befunge::Ops;
use Language::Befunge::Vector;
use Test::More tests => 4;

my ($lbi, $ip, $v);


$lbi = Language::Befunge::Interpreter->new;
$ip  = Language::Befunge::IP->new;
$v   = Language::Befunge::Vector->new(1,0);
$ip->set_delta( $v );
$lbi->set_curip( $ip );

$ip->spush( 3, 0 );
$lbi->store_code( 'abcdefq' );
Language::Befunge::Ops::flow_jump_to( $lbi );
is( $ip->get_position, '(0,0)', 'flow_jump_to does not move if no arg' );
is( $ip->spop, 3, 'flow_jump_to pops only one value' );

$ip->spush( -1, 3 );
Language::Befunge::Ops::flow_jump_to( $lbi );
is( $ip->get_position, '(3,0)', 'flow_jump_to can move forward' );
Language::Befunge::Ops::flow_jump_to( $lbi );
is( $ip->get_position, '(2,0)', 'flow_jump_to can move backward' );
