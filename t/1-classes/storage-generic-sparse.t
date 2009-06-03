#!perl
#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

#
# Language::Befunge::Storage tests for Generic Sparse plugin
#

use strict;
use warnings;

use Test::Exception;
use Test::More tests => 95;

use aliased 'Language::Befunge::Storage::Generic::Sparse' => 'Storage';
use Language::Befunge::Wrapping::LaheySpace;
use aliased 'Language::Befunge::Vector' => 'LBV';
use List::Util qw{ max };


# vars used within the file
my ($href, $l, $s, $str, $v);
my $str1 = 'Foobar baz';  my $lstr1 = length $str1;
my $str2 = 'camel llama'; my $lstr2 = length $str2;
my $wrap = Language::Befunge::Wrapping::LaheySpace->new();


#-- constructor

#- new()
$s = Storage->new(2, Wrapping => $wrap);
isa_ok($s, 'Language::Befunge::Storage');
isa_ok($s, 'Language::Befunge::Storage::Generic::Sparse');
is($s->min, '(0,0)', 'new() initializes storage');
is($s->max, '(0,0)', 'new() initializes storage');
is($s->get_dims, 2, 'get_dims() returns the number passed to new()');


#-- storage update

# clear()
$s = Storage->new(2, Wrapping => $wrap);
$s->store($str1, LBV->new(-2,-2));
$s->store($str1, LBV->new( 2, 2));
$s->clear;
is($s->min, '(0,0)', 'clear() reinits min bounds');
is($s->max, '(0,0)', 'clear() reinits max bounds');
is($s->get_value(LBV->new(2,2)), 32, 'clear() clears previous data');


#- store_binary()
$s = Storage->new(2, Wrapping => $wrap);

# basic store_binary(), defaulting to origin
$s->store_binary( $str1 );
#        0         1         2
#   5432101234567890123456789012345678
#  1
#  0     Foobar baz
#  1
#  2
is($s->min, '(0,0)', 'store_binary() does not grow min bounds if not needed');
is($s->max, '(9,0)', 'store_binary() grows max bounds if needed');
is($s->rectangle(LBV->new(0,0), LBV->new($lstr1,1)), $str1, 'store_binary() stores everything');
is($s->min, '(0,0)', 'rectangle() does not unnecessarily expand the array');
is($s->max, '(9,0)', 'rectangle() does not unnecessarily expand the array');
is($s->get_value(LBV->new(-1,0)), 32, 'store_binary() does not spill');
is($s->get_value(LBV->new(10,0)), 32, 'store_binary() does not spill');
is($s->min, '(0,0)', 'get_value() does not unnecessarily expand the array');
is($s->max, '(9,0)', 'get_value() does not unnecessarily expand the array');

# store_binary() with a positive offset
$s->store_binary( $str1, LBV->new(4,2) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foobar baz
#  1
#  2         Foobar baz
#  3
is($s->min,  '(0,0)', 'store_binary() does not grow min bounds if not needed');
is($s->max, '(13,2)', 'store_binary() grows max bounds if needed');
is($s->rectangle(LBV->new(4,2), LBV->new($lstr1,1)), $str1, 'store_binary() stores everything');
is($s->get_value(LBV->new( 3,2)), 32, 'store_binary() does not spill');
is($s->get_value(LBV->new(14,2)), 32, 'store_binary() does not spill');

# store_binary() with a negative offset
$s->store_binary( $str1, LBV->new(-2,-1) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1   Foobar baz
#  0     Foobar baz
#  1
#  2         Foobar baz
#  3
is($s->min, '(-2,-1)', 'store_binary() grows min bounds if needed');
is($s->max,  '(13,2)', 'store_binary() does not grow max bounds if not needed');
is($s->rectangle(LBV->new(-2,-1), LBV->new($lstr1,1)), $str1, 'store_binary() stores everything');
is($s->get_value(LBV->new(-3,-1)), 32, 'store_binary() does not spill');
is($s->get_value(LBV->new( 8,-1)), 32, 'store_binary() does not spill');

# store_binary() overwriting
$s->store_binary( $str2, LBV->new(2,0) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1   Foobar baz
#  0     Focamelbllama
#  1
#  2         Foobar baz
#  3
is($s->get_value(LBV->new(2,0)), 99, 'store_binary() overwrites non-space');
is($s->get_value(LBV->new(7,0)), 98, 'store_binary() does not overwrite with spaces');

# store_binary() returns the size inserted
$v = $s->store_binary( $str1 );
is($v, "($lstr1,1)", 'store_binary() returns the inserted size');

# store_binary() does not treat end of lines as such (crlf / lf / cr)
# \n
$str = "$str1\n$str2"; $l = length $str;
$v = $s->store_binary( $str );
is($v, "($l,1)", 'store_binary() does not treat \n as special');
# \r\n
$str = "$str1\r\n$str2"; $l = length $str;
$v = $s->store_binary( $str );
is($v, "($l,1)", 'store_binary() does not treat \r\n as special');
# \r
$str = "$str1\r$str2"; $l = length $str;
$v = $s->store_binary( $str );
is($v, "($l,1)", 'store_binary() does not treat \r as special');


#- store()
$s = Storage->new(2, Wrapping => $wrap);

# basic store(), defaulting to origin
$s->store( $str1 );
#        0         1         2
#   5432101234567890123456789012345678
#  1
#  0     Foobar baz
#  1
#  2
is($s->min, '(0,0)', 'store() does not grow min bounds if not needed');
is($s->max, '(9,0)', 'store() grows max bounds if needed');
is($s->rectangle(LBV->new(0,0), LBV->new($lstr1,1)), $str1, 'store() stores everything');
is($s->get_value(LBV->new(-1,0)), 32, 'store() does not spill');
is($s->get_value(LBV->new(10,0)), 32, 'store() does not spill');

# store() with a positive offset
$s->store( $str1, LBV->new(4,2) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foobar baz
#  1
#  2         Foobar baz
#  3
is($s->min,  '(0,0)', 'store() does not grow min bounds if not needed');
is($s->max, '(13,2)', 'store() grows max bounds if needed');
is($s->rectangle(LBV->new(4,2), LBV->new($lstr1,1)), $str1, 'store() stores everything');
is($s->get_value(LBV->new( 3,2)), 32, 'store() does not spill');
is($s->get_value(LBV->new(14,2)), 32, 'store() does not spill');

# store() with a negative offset
$s->store( $str1, LBV->new(-2,-1) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1   Foobar baz
#  0     Foobar baz
#  1
#  2         Foobar baz
#  3
is($s->min, '(-2,-1)', 'store() grows min bounds if needed');
is($s->max,  '(13,2)', 'store() does not grow max bounds if not needed');
is($s->rectangle(LBV->new(-2,-1), LBV->new($lstr1,1)), $str1, 'store() stores everything');
is($s->get_value(LBV->new(-3,-1)), 32, 'store() does not spill');
is($s->get_value(LBV->new( 8,-1)), 32, 'store() does not spill');

# store() overwriting
$s->store( $str2, LBV->new(2,0) );
#        0         1         2
#   5432101234567890123456789012345678
#  2
#  1   Foobar baz
#  0     Focamelbllama
#  1
#  2         Foobar baz
#  3
is($s->get_value(LBV->new(2,0)), 99, 'store() overwrites non-space');
is($s->get_value(LBV->new(7,0)), 98, 'store() does not overwrite with spaces');

# store() returns the size inserted
$v = $s->store( "$str1\n    $str2" );
$l = 4 + $lstr2; # 4 spaces before $str2
is($v, "($l,2)", 'store() returns the inserted size');

# store() supports various end of lines (crlf / lf / cr)
$l = max($lstr1, $lstr2);
# \n
$v = $s->store("$str1\n$str2");
is($v, "($l,2)", 'store() supports \n eol');
# \r\n
$v = $s->store( "$str1\r\n$str2" );
is($v, "($l,2)", 'store() supports \r\n eol');
# \r
$v = $s->store("$str1\r$str2");
is($v, "($l,2)", 'store() supports \r eol');


#- set_value()
$s = Storage->new(2, Wrapping => $wrap);
# set_value() grows storage
$s->set_value(LBV->new(8,4), 65);
is($s->min, '(0,0)', 'set_value() does not grow min bounds if not needed');
is($s->max, '(8,4)', 'set_value() grows max bounds if needed');
$s->set_value(LBV->new(-2,-3), 65);
is($s->min, '(-2,-3)', 'set_value() grows min bounds if needed');
is($s->max,   '(8,4)', 'set_value() does not grow max bounds if not needed');
# set_value() sets/overwrites new value
$s->clear;
$v = LBV->new(8,4);
$s->set_value($v, 65);
is($s->get_value($v), 65, 'set_value() sets a new value');
$s->set_value($v, 66);
is($s->get_value($v), 66, 'set_value() overwrites with non-space values');
$s->set_value($v, 32);
is($s->get_value($v), 32, 'set_value() overwrites even with space values');


#-- data retrieval

#- min() already tested plenty of time
#- max() already tested plenty of time

#- get_value() already tested plenty of time
# just need to test default value
$s = Storage->new(2, Wrapping => $wrap);
is($s->get_value(LBV->new(3,4)), 32, 'get_value() defaults to space');


#- get_char()
# basics
$s = Storage->new(2, Wrapping => $wrap);
$v = LBV->new(8,4);
$s->set_value($v, 65);
is($s->get_char($v), 'A', 'get_char() return correct character');
# default value
is($s->get_char(LBV->new(3,2)), ' ', 'get_char() defaults to space');
# utf8 char
$s->set_value($v, 9786); # smiley face
is($s->get_char($v), "<np-0x263a>", 'get_char() return correct character');


#- rectangle()
$s = Storage->new(2, Wrapping => $wrap);
$s->store($str1, LBV->new(-2,-2));
$s->store($str1, LBV->new(-1,-1));
$s->store($str1, LBV->new( 0, 0));
$s->store($str1, LBV->new( 1, 1));
$s->store($str1, LBV->new( 2, 2));
#        0         1         2
#   5432101234567890123456789012345678
#  2   Foobar baz
#  1    Foobar baz
#  0     Foobar baz
#  1      Foobar baz
#  2       Foobar baz
# basic usage
is($s->rectangle(LBV->new(2,-1),LBV->new(5,1)), 'bar b', 'rectangle() returns correct data');
is($s->rectangle(LBV->new(2,-1),LBV->new(9,3)), "bar baz  \nobar baz \noobar baz",
   'rectangle() returns correct data even with newlines');
is($s->rectangle(LBV->new(19,1),LBV->new(5,1)), '     ', 'rectangle() returns correct data even with spaces');
# empty row / column
is($s->rectangle(LBV->new(0,0),LBV->new(5,0)), '', 'rectangle() with no height returns empty string');
is($s->rectangle(LBV->new(0,0),LBV->new(0,5)), '', 'rectangle() with no width returns empty string');


#-- misc methods

# labels_lookup()
$s = Storage->new(2, Wrapping => $wrap);
# four directions.
$s->clear;
$s->store( <<'EOF', LBV->new(-2, -1 ));
      3
      ;
      z
      a
      b
      :
2;rab:;:foo;1
      :
      b
      l
      a
      h
      ;
      4
EOF
$href = $s->labels_lookup;
isa_ok($href, 'HASH');
is(scalar(keys(%$href)), 4,    'labels_lookup() finds everything');
is($href->{foo}[0],  '(10,5)', 'labels_lookup() finds left-right');
is($href->{bar}[0],  '(-2,5)', 'labels_lookup() finds right-left');
is($href->{bar}[1],  '(-1,0)', 'labels_lookup() deals with right-left');
is($href->{baz}[0],  '(4,-1)', 'labels_lookup() finds bottom-top');
is($href->{baz}[1],  '(0,-1)', 'labels_lookup() deals with bottom-top');
is($href->{blah}[0], '(4,12)', 'labels_lookup() finds top-bottom');
is($href->{blah}[1], '(0,1)',  'labels_lookup() deals with top-bottom');

# wrapping...
$s->clear;
$s->store( <<'EOF', LBV->new(-2, -1 ));
;1      z  ;   ;:foo
rab:;   a  4      2;
        b
        :  ;
        ;  :
           b
           l
        3  a
        ;  h
EOF
$href = $s->labels_lookup;
is(scalar(keys(%$href)), 4,     'labels_lookup() finds everything, even wrapping');
is($href->{foo}[0],  '(-1,-1)', 'labels_lookup() finds left-right');
is($href->{foo}[1],  '(1,0)',   'labels_lookup() deals with left-right');
is($href->{bar}[0],  '(16,0)',  'labels_lookup() finds right-left');
is($href->{bar}[1],  '(-1,0)',  'labels_lookup() deals with right-left');
is($href->{baz}[0],  '(6,6)',   'labels_lookup() finds bottom-top');
is($href->{baz}[1],  '(0,-1)',  'labels_lookup() deals with bottom-top');
is($href->{blah}[0], '(9,0)',   'labels_lookup() finds top-bottom');
is($href->{blah}[1], '(0,1)',   'labels_lookup() deals with top-bottom');

# garbage...
$s->clear;
$s->store( <<'EOF', LBV->new(-2, -1 ));
   ;:foo is foo;1
     ;not a label;
EOF
$href = $s->labels_lookup;
is(scalar(keys(%$href)), 1,    'labels_lookup() does not get fooled by look-alike labels');
is($href->{foo}[0], '(14,-1)', 'labels_lookup() discards comments');
is($href->{foo}[1], '(1,0)',   'labels_lookup() discards comments');

# double define...
$s->clear;
$s->store( <<'EOF', LBV->new(-2, -1 ));
   ;:foo is foo;1
   2;another oof:;
EOF
throws_ok(sub { $s->labels_lookup },
	qr/^Help! I found two labels 'foo' in the funge space/,
    'labels_lookup() chokes on double-defined labels');


# bad arguments to constructor
throws_ok(sub { Storage->new()  }, qr/^Usage/, 'new chokes on undef dimensions');
throws_ok(sub { Storage->new(0) }, qr/^Usage/, 'new chokes on zero dimensions');
throws_ok(sub { Storage->new(1) }, qr/^Usage/, 'new chokes on null Wrapping');
