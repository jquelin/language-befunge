#!perl

# -- numbers

use strict;
use warnings;

use Test::More tests => 34;
use Test::Output;

use Language::Befunge;
my $bef = Language::Befunge->new;


# empty stack
$bef->store_code( ',q' );
stdout_is { $bef->run_code } chr(0), 'empty stack, string output';
$bef->store_code( '.q' );
stdout_is { $bef->run_code } '0 ', 'empty stack, numeral output';


# all nums in order
foreach my $c ( 0 .. 9, 'a' .. 'f' ) {
    my $n = hex $c;
    $bef->store_code( "$c,q" );
    stdout_is { $bef->run_code } chr($n), "$c, string output";
    $bef->store_code( "$c.q" );
    stdout_is { $bef->run_code } "$n ",   "$c, numeral output";
}

