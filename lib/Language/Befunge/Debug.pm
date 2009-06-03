#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2009 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Debug;

use 5.010;
use strict;
use warnings;

use base qw{ Exporter };
our @EXPORT = qw{ debug };


# -- public subs

sub debug {}

my %redef;
sub enable {
    %redef = ( debug => sub { warn @_; } );
    _redef();
}

sub disable {
    %redef = ( debug => sub {} );
    _redef();
}


# -- private subs

#
# _redef()
#
# recursively walk the symbol table, and replace subs named after %redef
# keys with the matching value of %redef.
#
# this is not really clean, but since the sub debug() is exported in
# other modules, replacing the sub in *this* module is not enough: other
# modules still refer to their local copy.
#
# also, calling sub with full name Language::Befunge::Debug::debug() has
# performance issues (10%-15%) compared to using an exported sub...
#
my %orig; # original subs
sub _redef {
    my $parent = shift;
    if ( not defined $parent ) {
        $parent = '::';
        foreach my $sub ( keys %redef ) {
            $orig{ $sub } = \&$sub;
        }
    }
    no strict   'refs';
    no warnings 'redefine';
    foreach my $ns ( grep /^\w+::/, keys %{$parent} ) {
        $ns = $parent . $ns;
        _redef($ns) unless $ns eq '::main::';
        foreach my $sub (keys %redef) {
            next                                       # before replacing, check that...
                unless exists ${$ns}{$sub}             # named sub exist...
                && \&{ ${$ns}{$sub} } == $orig{$sub};  # ... and refer to the one we want to replace
            *{$ns . $sub} = $redef{$sub};
        }
    }
}





1;

__END__


=item get_DEBUG() / set_DEBUG()

wether the interpreter should output debug messages (a boolean)
