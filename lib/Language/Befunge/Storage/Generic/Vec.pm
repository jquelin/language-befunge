#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Storage::Generic::Vec;
require 5.006;
use strict;
use warnings;
no warnings 'portable'; # "Bit vector size > 32 non-portable" warnings on x64
use Carp;
use Language::Befunge::Vector;
use Language::Befunge::IP;
use base qw{ Language::Befunge::Storage };
use Config;

my $cell_size_in_bytes = $Config{ivsize};
my $cell_size_in_bits  = $cell_size_in_bytes * 8;
# -- CONSTRUCTOR


# try to load speed-up LBSGVXS
eval 'use Language::Befunge::Storage::Generic::Vec::XS';
if ( defined $Language::Befunge::Storage::Generic::Vec::XS::VERSION ) {
    my $xsversion = $Language::Befunge::Vector::XS::VERSION;
    my @subs = qw[
        get_value _get_value set_value _set_value _offset __offset _is_xs expand _expand
    ];
    foreach my $sub ( @subs ) {
        no strict 'refs';
        no warnings 'redefine';
        my $lbsgvxs_sub = "Language::Befunge::Storage::Generic::Vec::XS::$sub";
        *$sub = \&$lbsgvxs_sub;
    }
}


#
# new( dimensions )
#
# Creates a new Lahey Space.
#
sub new {
    my $package = shift;
    my $dimensions = shift;
    my %args = @_;
    my $usage = "Usage: $package->new(\$dimensions, Wrapping => \$wrapping)";
    croak $usage unless defined $dimensions;
    croak $usage unless $dimensions > 0;
    croak $usage unless exists $args{Wrapping};
    my $self  = {
        nd  => $dimensions,
        wrapping => $args{Wrapping},
    };
    bless $self, $package;
    $self->clear();
    return $self;
}


# -- PUBLIC METHODS

#
# clear(  )
#
# Clear the torus.
#
sub clear {
    my $self = shift;
    $$self{min} = Language::Befunge::Vector->new_zeroes($$self{nd});
    $$self{max} = Language::Befunge::Vector->new_zeroes($$self{nd});
    $$self{torus} = chr(0) x $cell_size_in_bytes;
    $self->set_value($$self{min}, 32);
}


#
# expand( v )
#
# Expand the torus to include the provided point.
#
sub expand {
    my ($self, $point) = @_;
    my ($old_min, $old_max) = ($$self{min}, $$self{max});
    return if $point->bounds_check($$self{min}, $$self{max});

    $point = $point->copy();
    my $nd = $$self{nd};

    my ($new_min, $new_max) = ($old_min->copy, $old_max->copy);
    foreach my $d (0..$nd-1) {
        $new_min->set_component($d, $point->get_component($d))
            if $new_min->get_component($d) > $point->get_component($d);
        $new_max->set_component($d, $point->get_component($d))
            if $new_max->get_component($d) < $point->get_component($d);
    }
    my $old_size = $old_max - $old_min;
    my $new_size = $new_max - $new_min;

    # if we have nothing to do, skip out early.
    return if $old_size == $new_size;

    # figure out the new storage size
    my $storage_size = $self->_offset($new_max, $new_min, $new_max) + 1;

    # figure out what a space looks like on this architecture.
    # Note: vec() is always big-endian, but the XS module is host-endian.
    # So we have to use an indirect approach.
    my $old_value = $self->get_value($self->min);
    $self->set_value($self->min, 32);
    my $new_value = vec($$self{torus}, 0, $cell_size_in_bits);
    $self->set_value($self->min, $old_value);
    # allocate new storage
    my $new_torus = " " x $cell_size_in_bytes;
    vec($new_torus, 0, $cell_size_in_bits) = $new_value;
    $new_torus x= $storage_size;
    for(my $v = $new_min->copy; defined($v); $v = $v->rasterize($new_min, $new_max)) {
        if($v->bounds_check($old_min, $old_max)) {
            my $length     = $old_max->get_component(0) - $v->get_component(0);
            my $old_offset = $self->_offset($v);
            my $new_offset = $self->_offset($v, $new_min, $new_max);
            vec(   $new_torus   , $new_offset, $cell_size_in_bits)
             = vec($$self{torus}, $old_offset, $cell_size_in_bits);
        }
    }
    $$self{min} = $new_min;
    $$self{max} = $new_max;
    $$self{torus} = $new_torus;
}


#
# store( code, [vector] )
#
# Store the given code at the specified vector.  If the coordinates
# are omitted, then the code is stored at the origin (0, 0).
#
# Return the size of the code inserted, as a vector.
#
# The code is a string, representing a block of Funge code.  Rows are
# separated by newlines.  Planes are separated by form feeds.  A complete list
# of separators follows:
#
#     Axis    Delimiter
#     X       (none)
#     Y       \n
#     Z       \f
#     4       \0
#
# The new-line and form-feed delimiters are in the Funge98 spec.  However,
# there is no standardized separator for dimensions above Z.  Currently,
# dimensions 4 and above use \0, \0\0, \0\0\0, etc.  These are dangerously
# ambiguous, but are the only way I can think of to retain reverse
# compatibility.  Suggestions for better delimiters are welcome.  (Using XML
# would be really ugly, I'd prefer not to.)
#
# This function actually enumerates the input twice: once to determine the max
# (so we only have to call expand() once), and once to do the actual storing.
#
sub store {
    my ($self, $code, $base) = @_;
    my $nd = $$self{nd};
    $base = Language::Befunge::Vector->new_zeroes($$self{nd}) unless defined $base;

    # support for any eol convention
    $code =~ s/\r\n/\n/g;
    $code =~ s/\r/\n/g;

    # The torus is a tree of arrays of numbers.
    # The tree is N levels deep, where N is the number of dimensions.
    # Each number is the ordinal value of the character held in this cell.

    my @separators = ("", "\n", "\f");
    push(@separators, "\0"x($_-3)) for (4..$nd); # , "\0", "\0\0", "\0\0\0"...
    my @sizes = map { 0 } (1..$nd);
    sub _code_split_helper {
        my ($d, $code, $sep, $sizes) = @_;
        my $rv = [split($$sep[$d], $code)];
        $rv = [ map { _code_split_helper($d-1,$_,$sep,$sizes) } (@$rv) ]
            if $d > 0;
        $$sizes[$d] = scalar @$rv if scalar @$rv > $$sizes[$d];
        return $rv;
    }
    my $coderef = _code_split_helper($nd - 1, $code, \@separators, \@sizes);

    # Figure out the rectangle size and the end-coordinate (max).
    my $size = Language::Befunge::Vector->new(@sizes);
    my $max  = Language::Befunge::Vector->new(map { $_ - 1 } (@sizes));
    $max += $base;

    # Enlarge torus to make sure our new values will fit.
    $self->expand( $base );
    $self->expand( $max );

    # Store code.
    TOP: for(my $v = $base->copy; defined($v); $v = $v->rasterize($base, $max)) {
        my $cv = $v - $base;
        my $code = $coderef;
        foreach my $ent (reverse $cv->get_all_components()) {
            next TOP unless exists $$code[$ent];
            $code = $$code[$ent];
        }
        next TOP if $code eq ' ';
        $self->set_value($v, ord($code));
    }

    return $size;
}


#
# store_binary( code, [vector] )
#
# Store the given code at the specified coordinates. If the coordinates
# are omitted, then the code is stored at the Origin(0, 0) coordinates.
#
# Return the size of the code inserted, as a vector.
#
# This is binary insertion, that is, EOL and FF sequences are stored in
# Funge-space instead of causing the dimension counters to be reset and
# incremented.  The data is stored all in one row.
#
sub store_binary {
    my ($self, $code, $base) = @_;
    my $nd = $$self{nd};
    $base = Language::Befunge::Vector->new_zeroes($$self{nd})
        unless defined $base;

    # The torus is a tree of arrays of numbers.
    # The tree is N levels deep, where N is the number of dimensions.
    # Each number is the ordinal value of the character held in this cell.

    my @sizes = length($code);
    push(@sizes,1) for(2..$nd);

    # Figure out the min, max, and size
    my $size = Language::Befunge::Vector->new(@sizes);
    my $max  = Language::Befunge::Vector->new(map { $_ - 1 } (@sizes));
    $max += $base;

    # Enlarge torus to make sure our new values will fit.
    $self->expand( $base );
    $self->expand( $max );

    # Store code.
    for(my $v = $base->copy; defined($v); $v = $v->rasterize($base, $max)) {
        my $char = substr($code, 0, 1, "");
        next if $char eq " ";
        $self->set_value($v, ord($char));
    }
    return $size;
}


#
# get_char( vector )
#
# Return the character stored in the torus at the specified location. If
# the value is not between 0 and 255 (inclusive), get_char will return a
# string that looks like "<np-0x4500>".
#
# B</!\> As in Funge, code and data share the same playfield, the
# character returned can be either an instruction B<or> raw data.  No
# guarantee is made that the return value is printable.
#
sub get_char {
    my $self = shift;
    my $v = shift;
    my $ord = $self->get_value($v);
    # reject invalid ascii
    return sprintf("<np-0x%x>",$ord) if ($ord < 0 || $ord > 255);
    return chr($ord);
}


#
# my $val = get_value( vector )
#
# Return the number stored in the torus at the specified location. If
# the value hasn't yet been set, it defaults to the ordinal value of a
# space (ie, #32).
#
# B</!\> As in Funge, code and data share the same playfield, the
# number returned can be either an instruction B<or> a data (or even
# both... Eh, that's Funge! :o) ).
#
sub get_value {
    my ($self, $v) = @_;
    my $val = 32;

    if ($v->bounds_check($$self{min}, $$self{max})) {
        my $off = $self->_offset($v);
        $val = vec($$self{torus}, $off, $cell_size_in_bits);
    }
    return $self->_u32_to_s32($val);
}


#
# set_value( vector, value )
#
# Write the supplied value in the torus at the specified location.
#
# B</!\> As in Funge, code and data share the same playfield, the
# number stored can be either an instruction B<or> a data (or even
# both... Eh, that's Funge! :o) ).
#
sub set_value {
    my ($self, $v, $val) = @_;

    # Ensure we can set the value.
    $self->expand($v);
    my $off = $self->_offset($v);
    vec($$self{torus}, $off, $cell_size_in_bits) = $self->_s32_to_u32($val);
}


#
# my $str = rectangle( start, size )
#
# Return a string containing the data/code in the specified rectangle.
#
# Note that for useful data to be returned, the "size" vector must contain at
# least a "1" for each component.  After all, a world of 10 width, 10 length
# but zero height would contain 0 planes.  So, if any components of the
# "size" vector do contain a 0, "" is returned.
#
sub rectangle {
    my ($self, $v1, $v2) = @_;
    my $nd = $$self{nd};

    # Fetch the data.
    my $data = "";
    my $min = $v1;
    foreach my $d (0..$nd-1) {
        # each dimension must >= 1, otherwise the rectangle will be empty.
        return "" unless $v2->get_component($d);
        # ... but we need to offset by -1, to calculate $max
        $v2->set_component($d, $v2->get_component($d) - 1);
    }
    my $max = $v1 + $v2;
    # No separator is used for the first dimension, for obvious reasons.
    # Funge98 specifies lf/cr/crlf for a second-dimension separator.
    # Funge98 specifies a form feed for a third-dimension separator.
    # Funge98 doesn't specify what dimensions 4 and above should use.
    # We use increasingly long strings of null bytes.
    # (4d uses 1 null byte, 5d uses 2, 6d uses 3, etc)
    my @separators = "";
    push(@separators,"\n") if $nd > 1;
    push(@separators,"\f") if $nd > 2;
    push(@separators,"\0"x($_-3)) for (4..$nd); # , "\0", "\0\0", "\0\0\0"...
    my $prev = $min->copy;
    for(my $v = $min->copy; defined($v); $v = $v->rasterize($min, $max)) {
        foreach my $d (0..$$self{nd}-1) {
            $data .= $separators[$d]
                if $prev->get_component($d) != $v->get_component($d);
        }
        $prev = $v;
        $data .= $self->get_char($v);
    }
    return $data;
}


#
# my %labels = labels_lookup(  )
#
# Parse the Lahey space to find sequences such as C<;:(\w[^\s;])[^;]*;>
# and return a hash reference whose keys are the labels and the values
# an anonymous array with two vectors: a vector describing the absolute
# position of the character B<just after> the trailing C<;>, and a
# vector describing the velocity that lead to this label.
#
# This method will only look in the cardinal directions; west, east,
# north, south, up, down and so forth.
#
# This allow to define some labels in the source code, to be used by
# C<Inline::Befunge> (and maybe some extensions).
#
sub labels_lookup {
    my $self = shift;
    my $labels = {};

    my ($min, $max) = ($$self{min}, $$self{max});
    $max = $max->copy;
    my $nd = $$self{nd};
    my @directions = ();
    foreach my $dimension (0..$nd-1) {
        # for the loop below, $max actually needs to be the point *after* the
        # greatest point ever written to; otherwise the last column is skipped.
        $max->set_component($dimension, $max->get_component($dimension)+1);

        # build the array of (non-diagonal) vectors
        my $v1 = Language::Befunge::Vector->new_zeroes($nd);
        my $v2 = $v1->copy;
        $v1->set_component($dimension,-1);
        push(@directions,$v1);
        $v2->set_component($dimension, 1);
        push(@directions,$v2);
    }
    
    R: for(my $this = $min->copy; defined($this); $this = $this->rasterize($min, $max)) {
        V: for my $v (@directions) {
            next R unless $self->get_char($this) eq ";";
            my ($label, $loc) = $self->_labels_try( $this, $v );
            next V unless defined($label);

            # How exciting, we found a label!
            croak "Help! I found two labels '$label' in the funge space"
                if exists $labels->{$label};
            $$labels{$label} = [$loc, $v];
        }
    }

    return $labels;
}


#
# my $vector = min()
#
# Returns a Vector object, pointing at the beginning of the torus.
# If nothing has been stored to a negative offset, this Vector will
# point at the origin (0,0).
#
sub min {
    my $self = shift;
    return $$self{min}->copy;
}


#
# my $vector = max()
#
# Returns a Vector object, pointing at the end of the torus.
# This is usually the largest position which has been written to.
#
sub max {
    my $self = shift;
    return $$self{max}->copy;
}


# -- PRIVATE METHODS

#
# _offset(v [, min, max])
#
# Return the offset (within the torus bitstring) of the vector.  If min and max
# are provided, return the offset within a hypothetical torus which has those
# dimensions.
#
sub _offset {
    my ($self, $v, $min, $max) = @_;
    my $nd = $$self{nd};
    my $off_by_1 = Language::Befunge::Vector->new(map { 1 } (1..$nd));
    $min = $$self{min} unless defined $min;
    $max = $$self{max} unless defined $max;
    my $tsize = $max + $off_by_1 - $min;
    my $toff  = $v - $min;
    my $rv = 0;
    my $levsize = 1;
    foreach my $d (0..$nd-1) {
        $rv += $toff->get_component($d) * $levsize;
        $levsize *= $tsize->get_component($d);
    }
    return $rv;
}


#
# _labels_try( $start, $delta )
#
# Try in the specified direction if the funge space matches a label
# definition. Return undef if it wasn't a label definition, or the name
# of the label if it was a valid label.
#
# called internally by labels_lookup().
#
sub _labels_try {
    my ($self, $start, $delta) = @_;
    my $comment = "";
    my $wrapping = $$self{wrapping};
    my $ip = Language::Befunge::IP->new($$self{nd});
    my $min = $self->min;
    my $max = $self->max;
    $ip->set_position($start->copy);
    $ip->set_delta($delta);

    # don't affect the parent
    #$vector = $vector->copy();
    # Fetch the whole comment stuff.
    do {
        # Calculate the next cell coordinates.
        my $v = $ip->get_position;
        my $d = $ip->get_delta;

        # now, let's move the ip.
        $v += $d;

        if ( $v->bounds_check($min, $max) ) {
            $ip->set_position( $v );
        } else {
            $wrapping->wrap( $self, $ip );
        }
        
        $comment .= $self->get_char($ip->get_position());
    } while ( $comment !~ /;.$/ );

    # Check if the comment matches the pattern.
    $comment =~ /^:(\w[^\s;]*)[^;]*;.$/;
    return undef unless defined $1;
    return undef unless length  $1;
    return ($1, $ip->get_position());
}


sub _s32_to_u32 {
    my ($self, $value) = @_;
    $value = 0xffffffff + ($value+1)
        if $value < 0;
    return $value;
}

sub _u32_to_s32 {
    my ($self, $value) = @_;
    $value = -2147483648 + ($value & 0x7fffffff)
        if($value & 0x80000000);
    return $value;
}

sub _is_xs { 0 }

1;
__END__

=head1 NAME

Language::Befunge::LaheySpace::Generic - a generic N-dimensional LaheySpace.


=head1 SYNOPSIS

    # create a 3-dimensional LaheySpace.
    my $torus = Language::Befunge::LaheySpace::Generic->new(3);
    $torus->clear();
    $torus->store(<<"EOF");
    12345
    67890
    \fabcde
    fghij
    EOF

Note you usually don't need to use this module directly.
B<Language::Befunge::Interpreter> can optionally use it.  If you are
considering using it, you should really install
L<Language::Befunge::Storage::Generic::Vec::XS> too, as this module is
dreadfully slow without it.  If you cannot install that, you should
use L<Language::Befunge::Storage::Generic::AoA> instead, it will perform
better.


=head1 DESCRIPTION

This module implements a traditional Lahey space.


=head1 CONSTRUCTOR

=head2 new( dimensions )

Creates a new Lahey Space.


=head1 PUBLIC METHODS

=head2 clear(  )

Clear the torus.


=head2 expand( v )

Expand the torus to include the provided point.


=head2 store( code, [vector] )

Store the given code at the specified vector.  If the coordinates
are omitted, then the code is stored at the origin (0, 0).

Return the size of the code inserted, as a vector.

The code is a string, representing a block of Funge code.  Rows are
separated by newlines.  Planes are separated by form feeds.  A complete list of
separators follows:

    Axis    Delimiter
    X       (none)
    Y       \n
    Z       \f
    4       \0

The new-line and form-feed delimiters are in the Funge98 spec.  However, there
is no standardized separator for dimensions above Z.  Currently, dimensions 4
and above use \0, \0\0, \0\0\0, etc.  These are dangerously ambiguous, but are
the only way I can think of to retain reverse compatibility.  Suggestions for
better delimiters are welcome.  (Using XML would be really ugly, I'd prefer not
to.)


=head2 store_binary( code, [vectir] )

Store the given code at the specified coordinates. If the coordinates
are omitted, then the code is stored at the Origin(0, 0) coordinates.

Return the size of the code inserted, as a vector.

This is binary insertion, that is, EOL and FF sequences are stored in
Funge-space instead of causing the dimension counters to be reset and
incremented.  The data is stored all in one row.


=head2 get_char( vector )


Return the character stored in the torus at the specified location. If
the value is not between 0 and 255 (inclusive), get_char will return a
string that looks like "<np-0x4500>".

B</!\> As in Funge, code and data share the same playfield, the
character returned can be either an instruction B<or> raw data.  No
guarantee is made that the return value is printable.


=head2 get_value( vector )

Return the number stored in the torus at the specified location. If
the value hasn't yet been set, it defaults to the ordinal value of a
space (ie, #32).

B</!\> As in Funge, code and data share the same playfield, the
number returned can be either an instruction B<or> a data (or even
both... Eh, that's Funge! :o) ).


=head2 set_value( vector, value )

Write the supplied value in the torus at the specified location.

B</!\> As in Funge, code and data share the same playfield, the
number stored can be either an instruction B<or> a data (or even
both... Eh, that's Funge! :o) ).


=head2 move_ip_forward( ip )

Move the given ip forward, according to its delta.


=head2 wrap( position, delta )

Handle LaheySpace wrapping, if necessary.


=head2 rectangle( start, size )

Return a string containing the data/code in the specified rectangle.

Note that for useful data to be returned, the "size" vector must contain at
least a "1" for each component.  After all, a world of 10 width, 10 length
but zero height would contain 0 planes.  So, if any components of the
"size" vector do contain a 0, "" is returned.


=head2 labels_lookup(  )

Parse the Lahey space to find sequences such as C<;:(\w[^\s;])[^;]*;>
and return a hash reference whose keys are the labels and the values
an anonymous array with two vectors: a vector describing the absolute
position of the character B<just after> the trailing C<;>, and a
vector describing the velocity that lead to this label.

This method will only look in the cardinal directions; west, east,
north, south, up, down and so forth.

This allow to define some labels in the source code, to be used by
C<Inline::Befunge> (and maybe some extensions).

=cut


=head2 min()

Returns a Vector object, pointing at the beginning of the torus.
If nothing has been stored to a negative offset, this Vector will
point at the origin (0,0).


=head2 max()

Returns a Vector object, pointing at the end of the torus.
This is usually the largest position which has been written to.


=head1 PRIVATE METHODS

=head2 _labels_try( start, delta )

Try in the specified direction if the funge space matches a label
definition. Return undef if it wasn't a label definition, or the name
of the label if it was a valid label.


=head1 BUGS

None known.  Please inform me if you find one.


=head1 SEE ALSO

L<Language::Befunge::Storage::Generic::Vec::XS>, L<Language::Befunge>.


=head1 AUTHOR

Mark Glines, E<lt>infinoid@cpan.orgE<gt>
Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
