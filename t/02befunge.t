#-*- cperl -*-
# $Id: 02befunge.t 2 2003-02-22 10:17:10Z jquelin $
#

#-----------------------------------#
#          Exported funcs.          #
#-----------------------------------#

use strict;
use Language::Befunge;
use POSIX qw! tmpnam !;
use Test;

# Vars.
my ($file, $fh);
my $tests;
my $out;
my $bef = new Language::Befunge;
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
$bef = new Language::Befunge( "t/q.bf" );
$bef->run_code;
$out = slurp;
ok( $out, "" );
BEGIN { $tests += 1 };

# Basic reading.
$bef = new Language::Befunge;
sel;
$bef->read_file( "t/q.bf" );
$bef->run_code;
$out = slurp;
ok( $out, "" );
BEGIN { $tests += 1 };

# Reading a non existent file.
eval { $bef->read_file( "/dev/a_file_that_is_not_likely_to_exist" ); };
ok( $@, qr/line/ );
BEGIN { $tests += 1 };

# Basic storing.
sel;
$bef->store_code( <<'END_OF_CODE' );
q
END_OF_CODE
$bef->run_code;
$out = slurp;
ok( $out, "" );
BEGIN { $tests += 1 };

BEGIN { plan tests => $tests };
