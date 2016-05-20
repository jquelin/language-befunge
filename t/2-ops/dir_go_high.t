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


$lbi = Language::Befunge::Interpreter->new({dims => 4}); # FIXME: custom
$ip  = Language::Befunge::IP->new(4);
$v   = Language::Befunge::Vector->new(4,4,4,4);
$ip->set_delta( $v );
$lbi->set_curip( $ip );
Language::Befunge::Ops::dir_go_high( $lbi );
is( $ip->get_delta, '(0,0,1,0)',  'dir_go_high forces IP to move upward' );
