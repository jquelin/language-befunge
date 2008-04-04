#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Interpreter;
use 5.010;

use strict;
use warnings;

use Carp;
use Language::Befunge::IP;
use Language::Befunge::Ops::Befunge98;
use Language::Befunge::Ops::Unefunge98;
use Language::Befunge::Ops::GenericFunge98;
use UNIVERSAL::require;

use base qw{ Class::Accessor::Fast };
__PACKAGE__->mk_accessors( qw{ storage _wrapping } );

# Public variables of the module.
$| = 1;


# -- CONSTRUCTOR


#
# my $interpreter = LBI->new( $opts )
#
# Create a new funge interpreter. One can pass some options as a hash
# reference, with the following keys:
#  - file:    the filename to read funge code from (default: blank storage)
#  - syntax:  the tunings set (default: 'befunge98')
#
# Depending on the value of syntax will change the interpreter
# internals: set of allowed ops, storage implementation, wrapping. The
# following values are recognized for 'syntax' (with in order: the
# number of dimensions, the set of operation loaded, the storage
# implementation and the wrapping implementation):
#
#  - befunge98: 2, LBO:Befunge98, LBS:2D:Sparse, LBW:LaheySpace
#
#
# If none of those values suit your needs, you can pass the value
# 'custom' and in that case you're responsible for also giving
# appropriate values for the keys 'dims', 'ops', 'storage', 'wrapping'.
# Note that those values will be ignored for all syntax values beside
# 'custom'.
#
sub new {
    my ($class, $opts) = @_;

    # default set of options.
    my $default = 'befunge98';
    $opts           //= { syntax => $default };
    $opts->{syntax} //= $default;

    # create whatever set of objects needed, depending on the wanted syntax.
    given ( $opts->{syntax} ) {
        when ('befunge98') {
            $opts->{dims}     = 2;
            $opts->{ops}      = 'Language::Befunge::Ops::Befunge98';
            $opts->{storage}  = 'Language::Befunge::Storage::2D::Sparse';
            $opts->{wrapping} = 'Language::Befunge::Wrapping::LaheySpace';
        }
        default { croak "syntax '$opts->{syntax}' not recognized." }
    }

=pod

    #my $file;
    # an odd number of arguments means a filename was passed.  (Previous
    # revs took an optional file argument; this is preserved for reverse
    # compatibility.)
    #$file = shift if(scalar @_ & 1);
    my %args = @_;
    $args{Dimensions} = 2            unless exists($args{Dimensions});
    $args{Storage}    = 'laheyspace' unless exists($args{Storage});

    if(defined($args{Syntax})) {
    	# accept values like "4Funge98"
	    if(lc($args{Syntax}) =~ /^(\d+)funge98$/) {
	    	$args{Syntax} = 'genericfunge98';
	    	$args{Dimensions} = $1;
	    }

	    # accept "Trefunge98"
	    elsif(lc($args{Syntax}) eq 'trefunge98') {
	    	# 3D-and-above Funges have the same instruction sets, for now.
	    	$args{Syntax} = 'genericfunge98';
	    	$args{Dimensions} = 3;
	    }

	    # accept "Unefunge98"
	    elsif(lc($args{Syntax}) eq 'unefunge98') {
	    	$args{Syntax} = 'unefunge98';
	    	$args{Dimensions} = 1;
	    }
    } else {
    	if($args{Dimensions} == 1) {
    		$args{Syntax} = 'unefunge98';
    	}
    	elsif($args{Dimensions} == 2) {
    		$args{Syntax} = 'befunge98';
    	}
    	else {
	    	# 3D-and-above Funges have the same instruction sets, for now.
    		$args{Syntax} = 'genericfunge98';
    	}
    }

=cut

    my $self  =
      { dimensions => $opts->{dims},
        file     => "STDIN",
        params   => [],
        retval   => 0,
        DEBUG    => 0,
        curip    => undef,
        ips      => [],
        newips   => [],
        handprint => 'JQBF98', # the handprint of the interpreter.
      };
    bless $self, $class;

=pod

    # TODO: if we're going to have multiple types of storage, we'll need a
    # registration API for them, and replace this with a hash lookup or
    # something.  Also, revisit this when wrapping is split into a separate
    # module from topology.
    if($args{Storage} eq 'laheyspace') {
    	if($args{Dimensions} == 2) {
    		# the 2D-specific LaheySpace is probably faster.
            $$self{torus} = Language::Befunge::LaheySpace->new();
    	} else {
            $$self{torus} = Language::Befunge::LaheySpace::Generic->new($args{Dimensions});
    	}
    } else {
	    die "Only laheyspace storages are supported, for the moment.\n";
    }

    $args{Syntax} = lc($args{Syntax});
    if(exists($syntaxes{$args{Syntax}})) {
        $$self{ops} = &{$syntaxes{$args{Syntax}}}();
    } else {
	    die "Supported Syntax types: " . join(", ",keys(%syntaxes));
    }

=cut

    # FIXME: taking only 2D case into account by now
    $opts->{ops}->use;
    $opts->{storage}->use;
    $opts->{wrapping}->use;
    $self->{ops} = $opts->{ops}->get_ops_map;
    $self->storage  ( $opts->{storage}->new( $opts->{dims} ) );
    $self->_wrapping( $opts->{wrapping}->new );
    #/FIXME

    # Read the file if needed.
    defined($opts->{file}) and $self->read_file( $opts->{file} );

    # Return the object.
    return $self;
}



# -- ACCESSORS

# The following is a list of attributes of a Language::Befunge
# object. For each of them, a method C<get_foobar> and C<set_foobar>
# exists, which does what you can imagine - and if you can't, then i
# wonder why you are reading this! :-)
#
# get_curip() / set_curip()
# the current Instruction Pointer processed (a L::B::IP object)
#
# get_DEBUG() / set_DEBUG()
# wether the interpreter should output debug messages (a boolean)
#
# get_dimensions() / set_dimensions()
# the number of dimensions this interpreter works in.
#
# get_file() / set_file()
# the script filename (a string)
#
# get_handprint() / set_handprint()
# the handprint of the interpreter
#
# get_ips() / set_ips()
# the current set of IPs travelling in the Lahey space (an array
# reference)
#
# get_newips() / set_newips()
# the set of IPs that B<will> travel in the Lahey space B<after> the
# current tick (an array reference)
#
# get_ops() / set_ops()
# the current supported operations set.
#
# get_params() / set_params()
# the parameters of the script (an array reference)
#
# get_retval() / set_retval()
# the current return value of the interpreter (an integer)
#
BEGIN {
    my @attrs = qw[ dimensions file params retval DEBUG curip ips newips ops handprint ];
    foreach my $attr ( @attrs ) {
        my $code = qq[ sub get_$attr { return \$_[0]->{$attr} } ];
        $code .= qq[ sub set_$attr { \$_[0]->{$attr} = \$_[1] } ];
        eval $code;
    }
}


# -- PUBLIC METHODS

# - Utilities


#
# move_ip( $ip [,regex] )
#
# Move $ip according to its delta on the storage.
#
# If a regex ( a C<qr//> object ) is specified, then $ip will move as
# long as the pointed character match the supplied regex.
#
# Example: given the code C<;foobar;> (assuming the IP points on the
# first C<;>) and the regex C<qr/[^;]/>, the IP will move in order to
# point on the C<r>.
#
sub move_ip {
    my ($self, $ip, $re) = @_;
    my $storage = $self->storage;

    if ( defined $re ) {
        my $orig = $ip->get_position;
        # moving as long as we did not reach the condition.
        while ( $storage->get_char($ip->get_position) =~ $re ) {
            $self->_move_ip_forward($ip);
            $self->abort("infinite loop")
                if $ip->get_position == $orig;
        }

        # we moved one char too far.
        $ip->dir_reverse;
        $self->_move_ip_forward($ip);
        $ip->dir_reverse;

    } else {
        # moving one step beyond...
        $self->_move_ip_forward($ip);
    }
}


#
# abort( reason )
#
# Abort the interpreter with the given reason, as well as the current
# file and coordinate of the offending instruction.
#
sub abort {
    my $self = shift;
    my $file = $self->get_file;
    my $v = $self->get_curip->get_position;
    croak "$file $v: ", @_;
}


#
# debug( LIST )
#
# Issue a warning if the interpreter has DEBUG enabled.
#
sub debug {
    my $self = shift;
    $self->get_DEBUG or return;
    warn @_;
}


# - Code and Data Storage

#
# read_file( filename )
#
# Read a file (given as argument) and store its code.
#
# Side effect: clear the previous code.
#
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


#
# store_code( code )
#
# Store the given code in the Lahey space.
#
# Side effect: clear the previous code.
#
sub store_code {
    my ($self, $code) = @_;
    $self->debug( "Storing code\n" );
    $self->storage->clear;
    $self->storage->store( $code );
}


# - Run methods


#
# run_code( [params]  )
#
# Run the current code. That is, create a new Instruction Pointer and
# move it around the code.
#
# Return the exit code of the program.
#
sub run_code {
    my $self = shift;
    $self->set_params( [ @_ ] );

    # Cosmetics.
    $self->debug( "\n-= NEW RUN (".$self->get_file.") =-\n" );

    # Create the first Instruction Pointer.
    $self->set_ips( [ Language::Befunge::IP->new($$self{dimensions}) ] );
    $self->set_retval(0);

    # Loop as long as there are IPs.
    $self->next_tick while scalar @{ $self->get_ips };

    # Return the exit code.
    return $self->get_retval;
}


#
# next_tick(  )
#
# Finish the current tick and stop just before the next tick.
#
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


#
# process_ip(  )
#
# Process the current ip.
#
sub process_ip {
    my ($self, $continue) = @_;
    $continue = 1 unless defined $continue;
    my $ip = $self->get_curip;

    # Fetch values for this IP.
    my $v  = $ip->get_position;
    my $ord  = $self->storage->get_value( $v );
    my $char = $self->storage->get_char( $v );

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
            $self->move_ip( $ip, qr/ / );
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
        $self->move_ip( $self->get_curip );
        push @{ $self->get_newips }, $ip unless $ip->get_end;
    }
}

#-- PRIVATE METHODS


#
# $lbi->_move_ip_forward( $ip );
#
# move $ip one step further, according to its velocity. if $ip gets out
# of bounds, then a wrapping is performed (according to current
# interpreter wrapping implementation) on the ip.
#
sub _move_ip_forward {
    my ($self, $ip) = @_;
    my $storage = $self->storage;

    # fetch the current position of the ip.
    my $v = $ip->get_position;
    my $d = $ip->get_delta;

    # now, let's move the ip.
    $v += $d;

    if ( $v->bounds_check($storage->min, $storage->max) ) {
        # within bounds - store new position.
        $ip->set_position( $v );
    } else {
        # wrap needed - this will update the position.
        $self->_wrapping->wrap( $storage, $ip );
    }
}


1;
__END__

=head1 CONSTRUCTOR

=head2 new( [filename, ] [ Key => Value, ... ] )

Create a new Befunge interpreter.  As an optional first argument, you
can pass it a filename to read Funge code from (default: blank
torus).  All other arguments are key=>value pairs.  The following
keys are accepted, with their default values shown:

    Dimensions => 2,
    Syntax     => 'befunge98',
    Storage    => 'laheyspace'

=head1 ACCESSORS

The following is a list of attributes of a Language::Befunge
object. For each of them, a method C<get_foobar> and C<set_foobar>
exists, which does what you can imagine - and if you can't, then i
wonder why you are reading this! :-)

=over 4

=item get_curip() / set_curip()

the current Instruction Pointer processed (a L::B::IP object)

=item get_DEBUG() / set_DEBUG()

wether the interpreter should output debug messages (a boolean)

=item get_dimensions() / set_dimensions()

the number of dimensions this interpreter works in.

=item get_file() / set_file()

the script filename (a string)

=item get_handprint() / set_handprint()

the handprint of the interpreter

=item get_ips() / set_ips()

the current set of IPs travelling in the Lahey space (an array
reference)

=item get_newips() / set_newips()

the set of IPs that B<will> travel in the Lahey space B<after> the
current tick (an array reference)

=item get_ops() / set_ops()

the current supported operations set.

=item get_params() / set_params()

the parameters of the script (an array reference)

=item get_retval() / set_retval()

the current return value of the interpreter (an integer)

=back


=head1 PUBLIC METHODS

=head2 Utilities

=over 4

=item move_ip( $ip [, $regex] )

Move the C<$ip> according to its delta on the storage.

If C<$regex> ( a C<qr//> object ) is specified, then C<$ip> will move as
long as the pointed character match the supplied regex.

Example: given the code C<;foobar;> (assuming the IP points on the
first C<;>) and the regex C<qr/[^;]/>, the IP will move in order to
point on the C<r>.


=item abort( reason )

Abort the interpreter with the given reason, as well as the current
file and coordinate of the offending instruction.


=item debug( LIST )

Issue a warning if the interpreter has DEBUG enabled.


=back



=head2 Code and Data Storage

=over 4

=item read_file( filename )

Read a file (given as argument) and store its code.

Side effect: clear the previous code.


=item store_code( code )

Store the given code in the Lahey space.

Side effect: clear the previous code.


=back



=head2 Run methods

=over 4

=item run_code( [params]  )

Run the current code. That is, create a new Instruction Pointer and
move it around the code.

Return the exit code of the program.


=item next_tick(  )

Finish the current tick and stop just before the next tick.


=item process_ip(  )

Process the current ip.


=back


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


=head1 ACKNOWLEDGEMENTS

I would like to thank Chris Pressey, creator of Befunge, who gave a
whole new dimension to both coding and obfuscating.


=head1 SEE ALSO

L<Language::Befunge>


=head1 AUTHOR

Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut

