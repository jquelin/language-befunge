#
# This file is part of Language::Befunge.
# See README in the archive for information on copyright & licensing.
#

package Language::Befunge::Interpreter;
require 5.006;

use strict;
use warnings;

# Modules we rely upon.
use Carp;     # This module can't explode :o)
use Config;   # For the 'y' instruction.
use Language::Befunge::IP;
use Language::Befunge::LaheySpace;
use Language::Befunge::Ops::Befunge98;

# Public variables of the module.
$| = 1;


=head1 CONSTRUCTOR

=head2 new( [filename] )

Create a new Befunge interpreter. If a filename is provided, then read
and store the content of the file in the cartesian Lahey space
topology of the interpreter.

=cut
sub new {
    # Create and bless the object.
    my $class = shift;
    my $self  =
      { file     => "STDIN",
        params   => [],
        retval   => 0,
        DEBUG    => 0,
        curip    => undef,
        ips      => [],
        newips   => [],
        torus    => Language::Befunge::LaheySpace->new,
        ops      => Language::Befunge::Ops::Befunge98->get_ops_map,
        handprint => 'JQBF98', # the handprint of the interpreter.
      }; # FIXME: hard-coding befunge98
    bless $self, $class;

    # Read the file if needed.
    my $file = shift;
    defined($file) and $self->read_file( $file );

    # Return the object.
    return $self;
}



=head1 ACCESSORS

The following is a list of attributes of a Language::Befunge
object. For each of them, a method C<get_foobar> and C<set_foobar>
exists, which does what you can imagine - and if you can't, then i
wonder why you are reading this! :-)

=over 4

=item file:

the script filename (a string)

=item params:

the parameters of the script (an array reference)

=item retval:

the current return value of the interpreter (an integer)

=item DEBUG:

wether the interpreter should output debug messages (a boolean)

=item curip:

the current Instruction Pointer processed (a L::B::IP object)

=item ips:

the current set of IPs travelling in the Lahey space (an array
reference)

=item newips:

the set of IPs that B<will> travel in the Lahey space B<after> the
current tick (an array reference)

=item torus:

the current Lahey space (a L::B::LaheySpace object)

=back

=cut
BEGIN {
    my @attrs = qw[ file params retval DEBUG curip ips newips ops torus handprint ];
    foreach my $attr ( @attrs ) {
        my $code = qq[ sub get_$attr { return \$_[0]->{$attr} } ];
        $code .= qq[ sub set_$attr { \$_[0]->{$attr} = \$_[1] } ];
        eval $code;
    }
}


=head1 PUBLIC METHODS

=head2 Utilities

=over 4

=item move_curip( [regex] )

Move the current IP according to its delta on the LaheySpace topology.

If a regex ( a C<qr//> object ) is specified, then IP will move as
long as the pointed character match the supplied regex.

Example: given the code C<;foobar;> (assuming the IP points on the
first C<;>) and the regex C<qr/[^;]/>, the IP will move in order to
point on the C<r>.

=cut
sub move_curip {
    my ($self, $re) = @_;
    my $curip = $self->get_curip;
    my $torus = $self->get_torus;

    if ( defined $re ) {
        my $orig = $curip->get_position;
        # Moving as long as we did not reach the condition.
        while ( $torus->get_char($curip->get_position) =~ $re ) {
            $torus->move_ip_forward($curip);
            $self->abort("infinite loop")
                if ( $curip->get_position == $orig );
        }

        # We moved one char too far.
        $curip->dir_reverse;
        $torus->move_ip_forward($curip);
        $curip->dir_reverse;

    } else {
        # Moving one step beyond...
        $torus->move_ip_forward($curip);
    }
}


=item abort( reason )

Abort the interpreter with the given reason, as well as the current
file and coordinate of the offending instruction.

=cut
sub abort {
    my $self = shift;
    my $file = $self->get_file;
    my $v = $self->get_curip->get_position;
    croak "$file $v: ", @_;
}


=item debug( LIST )

Issue a warning if the interpreter has DEBUG enabled.

=cut
sub debug {
    my $self = shift;
    $self->get_DEBUG or return;
    warn @_;
}

=back



=head2 Code and Data Storage

=over 4

=item read_file( filename )

Read a file (given as argument) and store its code.

Side effect: clear the previous code.

=cut
sub read_file {
    my ($self, $file) = @_;

    # Fetch the code.
    my $code;
    open BF, "<$file" or croak "$!";
    {
        local $/; # slurp mode.
        $code = <BF>;
    }
    close BF;

    # Store code.
    $self->set_file( $file );
    $self->store_code( $code );
}


=item store_code( code )

Store the given code in the Lahey space.

Side effect: clear the previous code.

=cut
sub store_code {
    my ($self, $code) = @_;
    $self->debug( "Storing code\n" );
    $self->get_torus->clear;
    $self->get_torus->store( $code );
}

=back



=head2 Run methods

=over 4

=item run_code( [params]  )

Run the current code. That is, create a new Instruction Pointer and
move it around the code.

Return the exit code of the program.

=cut
sub run_code {
    my $self = shift;
    $self->set_params( [ @_ ] );

    # Cosmetics.
    $self->debug( "\n-= NEW RUN (".$self->get_file.") =-\n" );

    # Create the first Instruction Pointer.
    $self->set_ips( [ Language::Befunge::IP->new ] );
    $self->set_retval(0);

    # Loop as long as there are IPs.
    $self->next_tick while scalar @{ $self->get_ips };

    # Return the exit code.
    return $self->get_retval;
}


=item next_tick(  )

Finish the current tick and stop just before the next tick.

=cut
sub next_tick {
    my $self = shift;

    # Cosmetics.
    $self->debug( "Tick!\n" );

    # Process the set of IPs.
    $self->set_newips( [] );
    $self->process_ip while $self->set_curip( shift @{ $self->get_ips } );

    # Copy the new ips.
    $self->set_ips( $self->get_newips );
}


=item process_ip(  )

Process the current ip.

=cut
sub process_ip {
    my ($self, $continue) = @_;
    $continue = 1 unless defined $continue;
    my $ip = $self->get_curip;

    # Fetch values for this IP.
    my $v  = $ip->get_position;
    my $ord  = $self->get_torus->get_value( $v );
    my $char = $self->get_torus->get_char( $v );

    # Cosmetics.
    $self->debug( "#".$ip->get_id.":$v: $char (ord=$ord)  Stack=(@{$ip->get_toss})\n" );

    # Check if we are in string-mode.
    if ( $ip->get_string_mode ) {
        if ( $char eq '"' ) {
            # End of string-mode.
            $self->debug( "leaving string-mode\n" );
            $ip->set_string_mode(0);

        } elsif ( $char eq ' ' ) {
            # A serie of spaces, to be treated as one space.
            $self->debug( "string-mode: pushing char ' '\n" );
            $self->move_curip( qr/ / );
            $ip->spush( $ord );

        } else {
            # A banal character.
            $self->debug( "string-mode: pushing char '$char'\n" );
            $ip->spush( $ord );
        }

    } else {
        # Not in string-mode.
        if ( exists $self->get_ops->{$char} ) {
            # Regular instruction.
            my $meth = $self->get_ops->{$char};
            $meth->($self);

        } else {
            # Not a regular instruction: reflect.
            $self->debug( "the command value $ord (char='$char') is not implemented.\n");
            $ip->dir_reverse;
        }
    }

    if ($continue) {
        # Tick done for this IP, let's move it and push it in the
        # set of non-terminated IPs.
        $self->move_curip;
        push @{ $self->get_newips }, $ip unless $ip->get_end;
    }
}


=back

=cut

1;
__END__


=head1 TODO

=over 4

=item o

Write standard libraries.

=back


=head1 BUGS

Although this module comes with a full set of tests, maybe there are
subtle bugs - or maybe even I misinterpreted the Funge-98
specs. Please report them to me.

There are some bugs anyway, but they come from the specs:

=over 4

=item o

About the 18th cell pushed by the C<y> instruction: Funge specs just
tell to push onto the stack the size of the stacks, but nothing is
said about how user will retrieve the number of stacks.

=item o

About the load semantics. Once a library is loaded, the interpreter is
to put onto the TOSS the fingerprint of the just-loaded library. But
nothing is said if the fingerprint is bigger than the maximum cell
width (here, 4 bytes). This means that libraries can't have a name
bigger than C<0x80000000>, ie, more than four letters with the first
one smaller than C<P> (C<chr(80)>).

Since perl is not so rigid, one can build libraries with more than
four letters, but perl will issue a warning about non-portability of
numbers greater than C<0xffffffff>.

=back


=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 ACKNOWLEDGEMENTS

I would like to thank Chris Pressey, creator of Befunge, who gave a
whole new dimension to both coding and obfuscating.


=head1 COPYRIGHT

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=head1 SEE ALSO

=over 4

=item L<perl>

=item L<http://www.catseye.mb.ca/esoteric/befunge/>

=item L<http://dufflebunk.iwarp.com/JSFunge/spec98.html>

=back

=cut
