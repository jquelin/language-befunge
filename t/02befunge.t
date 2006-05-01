#-*- cperl -*-
# $Id: 02befunge.t 41 2006-05-01 17:23:21Z jquelin $
#

#-----------------------------------#
#          Exported funcs.          #
#-----------------------------------#

use strict;
use Language::Befunge;
use POSIX qw! tmpnam !;
use Test::More;

# Vars.
my ($file, $fh);
my $tests;
my $out;
my $bef = Language::Befunge->new;
BEGIN { $tests = 0 };

# In order to see what happens...
sub sel () {
    $file = tmpnam();
    open OUT, ">$file" or die $!;
    $fh = select OUT;
}
sub slurp () {
    select $fh;
    close OUT;
    open OUT, "<$file" or die $!;
    my $content;
    {
        local $/;
        $content = <OUT>;
    }
    close OUT;
    unlink $file;
    return $content;
}

# Basic constructor.
sel;
$bef = Language::Befunge->new( "t/q.bf" );
$bef->run_code;
$out = slurp;
is( $out, "" );
BEGIN { $tests += 1 };

# debug tests.
{
    my $warning;
    local $SIG{__WARN__} = sub { $warning = "@_" };
    $bef = Language::Befunge->new;

    $warning = "";
    $bef->debug( "foo\n" );
    is( $warning, "", "DEBUG is off by default" );

    $warning = "";
    $bef->set_DEBUG(1);
    $bef->debug( "bar\n" );
    is( $warning, "bar\n", "debug warns properly when DEBUG is on" );

    $warning = "";
    $bef->set_DEBUG(0);
    $bef->debug( "baz\n" );
    is( $warning, "",      "debug does not warn when DEBUG is off" );
}
BEGIN { $tests += 3 };


# useless tests for unused accessor - in order for coverage to be complete.
$bef->set_torus( );


# Basic reading.
$bef = Language::Befunge->new;
sel;
$bef->read_file( "t/q.bf" );
$bef->run_code;
$out = slurp;
is( $out, "" );
BEGIN { $tests += 1 };

# Reading a non existent file.
eval { $bef->read_file( "/dev/a_file_that_is_not_likely_to_exist" ); };
like( $@, qr/line/, "reading a non-existent file barfs" );
BEGIN { $tests += 1 };

# Basic storing.
sel;
$bef->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
$bef->run_code;
$out = slurp;
is( $out, "" );
BEGIN { $tests += 1 };

# Interpreter must treat non-characters as if they were an 'r' instruction.
sel;
$bef->store_code( <<'END_OF_CODE' );
01-b0p#q1.2 q
END_OF_CODE
$bef->run_code;
$out = slurp;
is( $out, "1 2 " );
BEGIN { $tests += 1 };

# Interpreter must treat non-commands as if they were an 'r' instruction.
sel;
$bef->store_code( <<'END_OF_CODE' );
01+b0p#q1.2 q
END_OF_CODE
$bef->run_code;
$out = slurp;
is( $out, "1 2 " );
BEGIN { $tests += 1 };

BEGIN { plan tests => $tests };
