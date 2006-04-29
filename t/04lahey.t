#-*- cperl -*-
# $Id: 04lahey.t 28 2006-04-29 16:47:22Z jquelin $
#

#------------------------------------------#
#          The LaheySpace module.          #
#------------------------------------------#

use strict;
use Test::More;
use Language::Befunge::IP;
use Language::Befunge::LaheySpace;

my $tests;
my $ip = new Language::Befunge::IP;
my $href;
BEGIN { $tests = 0 };

# Constructor.
my $ls = new Language::Befunge::LaheySpace;
isa_ok( $ls, "Language::Befunge::LaheySpace");
BEGIN { $tests += 1 };


# Clear method.
$ls->clear;
is( $ls->{xmin}, 0, "clear resets xmin" );
is( $ls->{ymin}, 0, "clear resets ymin" );
is( $ls->{xmax}, 0, "clear resets xmax" );
is( $ls->{ymax}, 0, "clear resets ymax" );
BEGIN { $tests += 4; }


# set_min/set_max methods.
$ls->clear;
$ls->set_min( -2, -3 ); # set_min
is( $ls->{xmin}, -2, "set_min sets xmin" );
is( $ls->{ymin}, -3, "set_min sets ymin" );
$ls->set_min( -1, -1 ); # can't shrink
is( $ls->{xmin}, -2, "set_min can't shrink xmin" );
is( $ls->{ymin}, -3, "set_min can't shrink ymin" );
$ls->set_max( 4, 5 );   # set_max
is( $ls->{xmax}, 4, "set_max sets xmax" );
is( $ls->{ymax}, 5, "set_max sets ymax" );
$ls->set_max( 2, 3 );   # can't shrink
is( $ls->{xmax}, 4, "set_max can't shrink xmax" );
is( $ls->{ymax}, 5, "set_max can't shrink ymax" );
BEGIN{ $tests += 8; }


# out_of_bounds method.
is( $ls->out_of_bounds(-6,  0), 1, "out_of_bounds < xmin" );
is( $ls->out_of_bounds( 0, -6), 1, "out_of_bounds < ymin" );
is( $ls->out_of_bounds( 0,  6), 1, "out_of_bounds > xmax" );
is( $ls->out_of_bounds( 6,  0), 1, "out_of_bounds > ymax" );
is( $ls->out_of_bounds( 0,  0), 0, "out_of_bounds in torus" );
BEGIN{ $tests += 5; }


# Enlarge torus.
$ls->clear;
$ls->enlarge_y( 3 );
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, 0 );
is( $ls->{xmax}, 0 );
is( $ls->{ymax}, 3 );
$ls->enlarge_x( 2 );
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, 0 );
is( $ls->{xmax}, 2 );
is( $ls->{ymax}, 3 );
$ls->enlarge_y( -5 );
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, -5 );
is( $ls->{xmax}, 2 );
is( $ls->{ymax}, 3 );
$ls->enlarge_x( -4 );
is( $ls->{xmin}, -4 );
is( $ls->{ymin}, -5 );
is( $ls->{xmax}, 2 );
is( $ls->{ymax}, 3 );
BEGIN { $tests += 16; }

# Get/Set value.
$ls->clear;
$ls->set_value( 10, 5, 65 );
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, 0 );
is( $ls->{xmax}, 10 );
is( $ls->{ymax}, 5 );
is( $ls->get_value( 10, 5 ), 65 );
is( $ls->get_value( 1, 1),   32 ); # default to space.
is( $ls->get_value( 20, 20), 32 ); # out of bounds.
BEGIN { $tests += 7; }

# Store method.
$ls->clear;
$ls->store( <<'EOF' );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foo bar baz
#  1     camel llama buffy
#  2
#  3
#  4
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, 0 );
is( $ls->{xmax}, 16 );
is( $ls->{ymax}, 1 );
is( $ls->get_value( 0, 0),  70 );
is( $ls->get_value( 12, 0), 32 ); # default to space.
is( $ls->get_value( 1, 5),  32 ); # out of bounds.
BEGIN { $tests += 7; }
$ls->store( <<'EOF', 4, 1 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1
#  0     Foo bar baz
#  1     cameFoo bar baz      
#  2         camel llama buffy
#  3
#  4
is( $ls->{xmin}, 0 );
is( $ls->{ymin}, 0 );
is( $ls->{xmax}, 20 );
is( $ls->{ymax}, 2 );
is( $ls->get_value( 0, 0),  70  ); # old values.
is( $ls->get_value( 4, 1),  70  ); # overwritten.
is( $ls->get_value( 20, 2), 121 ); # last value.
BEGIN { $tests += 7; }
my ($w, $h) = $ls->store( <<'EOF', -2, -1 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1   Foo bar baz
#  0   camel llama buffy
#  1     cameFoo bar baz      
#  2         camel llama buffy
#  3
#  4
is( $w, 17 );
is( $h, 2 );
is( $ls->{xmin}, -2 );
is( $ls->{ymin}, -1 );
is( $ls->{xmax}, 20 );
is( $ls->{ymax}, 2 );
is( $ls->get_value( -2, -1), 70  ); # new values.
is( $ls->get_value( 0, 0 ),  109 ); # overwritten.
is( $ls->get_value( 4, 1 ),  70  ); # old value.
BEGIN { $tests += 9; }
$ls->store( <<'EOF', -2, 0 );
Foo bar baz
camel llama buffy
EOF
#   5432101234567890123456789012345678
#  2
#  1   Foo bar baz
#  0   Foo bar baz       
#  1   camel llama buffy      
#  2         camel llama buffy
#  3
#  4
is( $ls->{xmin}, -2 );
is( $ls->{ymin}, -1 );
is( $ls->{xmax}, 20 );
is( $ls->{ymax}, 2 );
is( $ls->get_value( -2, 0), 70  ); # new values.
is( $ls->get_value( 12, 0 ), 32 ); # overwritten space.
BEGIN { $tests += 6; }

# Rectangle.
is( $ls->rectangle(-2,-1,3,2), "Foo\nFoo\n" );
is( $ls->rectangle(-3,4,1,1), " \n" );
is( $ls->rectangle(19,-2,2,6), "  \n  \n  \n  \nfy\n  \n" );
BEGIN { $tests += 3; }


# Move IP.
$ls->clear;   # "positive" playfield.
$ls->set_max(5, 10);
$ip->set_pos( 4, 3 );
$ip->set_dx( 1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5 );
$ls->move_ip_forward( $ip ); # wrap xmax
is( $ip->get_curx, 0 );
$ip->set_pos( 4, 3 );
$ip->set_dx( 7 );                # apply delta that overflows torus width
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 4 );
$ls->move_ip_forward( $ip ); # wrap xmax harder
is( $ip->get_curx, 4 );
$ip->set_pos( 0, 4 );
$ip->set_dx( -1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip ); # wrap xmin
is( $ip->get_curx, 5 );
$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10 );
$ls->move_ip_forward( $ip ); # wrap ymax
is( $ip->get_cury, 0 );
$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 12 );               # apply delta that overflows torus height
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 9 );
$ls->move_ip_forward( $ip ); # wrap ymax harder
is( $ip->get_cury, 9 );
$ip->set_pos( 1, 0 );
$ip->set_dx( 0 );
$ip->set_dy( -1 );
$ls->move_ip_forward( $ip ); # wrap ymin
is( $ip->get_cury, 10 );
BEGIN { $tests += 10 }
$ls->clear;   # "negative" playfield.
$ls->set_min(-1, -3);
$ls->set_max(5, 10);
$ip->set_pos( 4, 3 );
$ip->set_dx( 1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 5 );
$ls->move_ip_forward( $ip ); # wrap xmax
is( $ip->get_curx, -1 );
$ip->set_pos( -1, 4 );
$ip->set_dx( -1 );
$ip->set_dy( 0 );
$ls->move_ip_forward( $ip ); # wrap xmin
is( $ip->get_curx, 5 );
$ip->set_pos( 2, 9 );
$ip->set_dx( 0 );
$ip->set_dy( 1 );
$ls->move_ip_forward( $ip );
is( $ip->get_cury, 10 );
$ls->move_ip_forward( $ip ); # wrap ymax
is( $ip->get_cury, -3 );
$ip->set_pos( 1, -3 );
$ip->set_dx( 0 );
$ip->set_dy( -1 );
$ls->move_ip_forward( $ip ); # wrap ymin
is( $ip->get_cury, 10 );
BEGIN { $tests += 6; }
$ls->clear;   # diagonals.
$ls->set_min(-1, -2);
$ls->set_max(6, 5);
$ip->set_pos(0, 0);
$ip->set_dx(-2);
$ip->set_dy(-3);
$ls->move_ip_forward( $ip );
is( $ip->get_curx, 2 );
is( $ip->get_cury, 3 );
BEGIN { $tests += 2; }

# Label lookup
# four directions.
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
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
$href = $ls->labels_lookup;
is( scalar(keys(%$href)), 4 );
is( $href->{foo}[0], 10 );
is( $href->{foo}[1], 5 );
is( $href->{foo}[2], 1 );
is( $href->{foo}[3], 0 );
is( $href->{bar}[0], -2 );
is( $href->{bar}[1], 5 );
is( $href->{bar}[2], -1 );
is( $href->{bar}[3], 0 );
is( $href->{baz}[0], 4 );
is( $href->{baz}[1], -1 );
is( $href->{baz}[2], 0 );
is( $href->{baz}[3], -1 );
is( $href->{blah}[0], 4 );
is( $href->{blah}[1], 12 );
is( $href->{blah}[2], 0 );
is( $href->{blah}[3], 1 );
BEGIN { $tests += 17 };
# wrapping...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
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
$href = $ls->labels_lookup;
is( scalar(keys(%$href)), 4 );
is( $href->{foo}[0], -1 );
is( $href->{foo}[1], -1 );
is( $href->{foo}[2], 1 );
is( $href->{foo}[3], 0 );
is( $href->{bar}[0], 16 );
is( $href->{bar}[1], 0 );
is( $href->{bar}[2], -1 );
is( $href->{bar}[3], 0 );
is( $href->{baz}[0], 6 );
is( $href->{baz}[1], 6 );
is( $href->{baz}[2], 0 );
is( $href->{baz}[3], -1 );
is( $href->{blah}[0], 9 );
is( $href->{blah}[1], 0 );
is( $href->{blah}[2], 0 );
is( $href->{blah}[3], 1 );
BEGIN { $tests += 17 };
# garbage...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
   ;:foo is foo;1  
     ;not a label;
EOF
$href = $ls->labels_lookup;
is( scalar(keys(%$href)), 1 );
is( $href->{foo}[0], 14 );
is( $href->{foo}[1], -1 );
is( $href->{foo}[2], 1 );
is( $href->{foo}[3], 0 );
BEGIN { $tests += 5 };
# double define...
$ls->clear;
$ls->store( <<'EOF', -2, -1 );
   ;:foo is foo;1  
   2;another oof:;
EOF
eval { $href = $ls->labels_lookup; };
like( $@, qr/^Help! I found two labels 'foo' in the funge space/ );
BEGIN { $tests += 1 };

# input checking: make sure get_char() returns ASCII.
$ls->set_value(0,0, -1);
$ls->set_value(1,0,  0);
$ls->set_value(2,0,255);
$ls->set_value(3,0,256);
ok ( $ls->get_char(0,0), sprintf("<np-0x%x>", -1) );
ok ( $ls->get_char(1,0), chr(0) );
ok ( $ls->get_char(2,0), chr(0xff) );
ok ( $ls->get_char(3,0), '<np-0x100>' );
BEGIN { $tests += 4 };

BEGIN { plan tests => $tests };
