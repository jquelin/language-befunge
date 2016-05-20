use strict;
use warnings;

package Language::Befunge::lib::HELO;
# ABSTRACT: extension to print Hello world!

sub new { return bless {}, shift; }

sub P {
    print "Hello world!\n";
}

sub S {
    my (undef, $interp) = @_;
    $interp->get_curip->spush( reverse map { ord } split //, "Hello world!\n".chr(0) );
}


1;
__END__

=head1 SYNOPSIS

    P - print "Hello world!\n"
    S - store the gnirts "Hello world!\n"0 on the TOSS

=head1 DESCRIPTION

This extension is just an example of the Befunge extension mechanism
of the Language::Befunge interpreter.


=head1 FUNCTIONS

=head2 new

Create a new HELO instance.


=head2 P

Output C<Hello world!\n>.


=head2 S

Store the gnirts "Hello world!\n"0 on the TOSS.

