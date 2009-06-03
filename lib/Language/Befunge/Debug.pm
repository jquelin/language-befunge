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



#
# debug( LIST )
#
# Issue a warning if the interpreter is in debug mode.
#
sub debug {}

my (%orig, %redef);
sub enable {
    %redef = ( debug => sub { warn @_; } );
    _redef();
}

sub disable {
    %redef = ( debug => sub {} );
    _redef();
}

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
            *{$ns . $sub} = $redef{$sub} if exists ${$ns}{$sub} && \&{ ${$ns}{$sub} } == $orig{$sub};
        }
    }
}





1;

__END__


=item get_DEBUG() / set_DEBUG()

wether the interpreter should output debug messages (a boolean)
