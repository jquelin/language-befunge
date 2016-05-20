use strict;
use warnings;

package Language::Befunge::lib::FOO;
# ABSTRACT: extension to print foo

sub new { return bless {}, shift; }

sub P {
    print "foo";
}

1;
__END__

=head1 SYNOPSIS

    P - print "foo"

=head1 DESCRIPTION

This extension is just an example of the Befunge extension mechanism
of the Language::Befunge interpreter.


=head1 FUNCTIONS

=head2 new

Create a FOO instance.


=head2 P

Output C<foo>.

