#
# This file is part of Language::Befunge.
# Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.
#
# This program is free software; you can redistribute it and/or modify
# it under the same terms as Perl itself.
#
#

package Language::Befunge::Storage::Generic::AoA;
require 5.006;
use strict;
use warnings;
use Carp;
use Language::Befunge::Vector;
use Language::Befunge::IP;
use base 'Language::Befunge::Storage';

# -- CONSTRUCTOR


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
    $$self{torus} = [32];
    $$self{torus} = [$$self{torus}] for(1..$$self{nd});
}


#
# expand( vector )
#
# Expand the torus to include the provided point.
#
sub expand {
    my ($self, $v) = @_;
    my $nd = $$self{nd};
    my ($min, $max) = ($$self{min}, $$self{max});

    # if we have nothing to do, skip out early.
    return 0 if $v->bounds_check($min,$max);

    sub _expand_helper {
        my ($d, $v, $torus, $min, $max) = @_;
        my $oldmin = $min->get_component($d); # left end of old array
        my $oldmax = $max->get_component($d); # right end of old array
        my $doff = 0; # prepend this many elements
        $doff = $oldmin - $v->get_component($d) if $v->get_component($d) < $oldmin;
        my $newmin = $oldmin; # left end of new array
        my $newmax = $oldmax; # right end of new array
        $newmin = $v->get_component($d) if $v->get_component($d) < $newmin;
        $newmax = $v->get_component($d) if $v->get_component($d) > $newmax;
        my $append  = $v->get_component($d) - $max->get_component($d);
        $append = 0 if $append < 0; # append this many elements
        my $wholerow = 0;
        # if a higher-level dimension has been expanded where we are, we
        # have to create a new row out of whole cloth.
        for(my $i = $v->get_dims()-1; $i > $d; $i--) {
            $wholerow = 1 if $v->get_component($i) < $min->get_component($i);
            $wholerow = 1 if $v->get_component($i) > $max->get_component($i);
        }
        my @newrow;
        my $o = $v->get_component($d);
        if($d > 0) {
            # handle the nodes we have to create from whole cloth
            for(my $i = 0; $i < $doff; $i++) {
                $v->set_component($d,$i+$newmin);
                push(@newrow,_expand_helper($d-1,$v,undef,$min,$max));
            }
            # handle the nodes we're expanding from existing data
            for(my $i = 0; $i <= ($oldmax-$oldmin); $i++) {
                $v->set_component($d,$i+$oldmin);
                push(@newrow,_expand_helper($d-1,$v,$$torus[$i],$min,$max));
            }
            # handle more nodes we're creating from whole cloth
            for(my $i = $oldmax + 1; $i < $newmax + 1; $i++) {
                $v->set_component($d,$i);
                push(@newrow,_expand_helper($d-1,$v,undef,$min,$max));
            }
        } else {
            for(my $i = $newmin; $i <= $newmax; $i++) {
                if(!$wholerow && ($i >= ($newmin+$doff) && (($i-($newmin+$doff)) <= ($oldmax-$oldmin)))) {
                    # newmin = -3
                    # oldmin = -1
                    #   doff = 2
                    # lhs offset -3-2-1 0 1 2 3 4 5 6 7 8
                    # data        . . a b c d e f g h i j
                    # array index . . 0 1 2 3 4 5 6 7 8 9
                    my $newdata = $$torus[$i-$oldmin];
                    push(@newrow,$newdata);
                } else {
                    push(@newrow,32);
                }
            }
        }
        $v->set_component($d,$o);
        return \@newrow;
    }
    $$self{torus} = _expand_helper($nd - 1, $v, $$self{torus}, $min, $max);
    for(my $d = $$self{nd} - 1; $d > -1; $d--) {
        my $n = $v->get_component($d);
        my $min = $$self{min}->get_component($d);
        my $max = $$self{max}->get_component($d);
        $$self{min}->set_component($d,$n) if $n < $min;
        $$self{max}->set_component($d,$n) if $n > $max;
    }
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
# separated by newlines.  Planes are separated by form feeds.  A complete list of
# separators follows:
#
#     Axis    Delimiter
#     X       (none)
#     Y       \n
#     Z       \f
#     4       \0
#
# The new-line and form-feed delimiters are in the Funge98 spec.  However, there
# is no standardized separator for dimensions above Z.  Currently, dimensions 4
# and above use \0, \0\0, \0\0\0, etc.  These are dangerously ambiguous, but are
# the only way I can think of to retain reverse compatibility.  Suggestions for
# better delimiters are welcome.  (Using XML would be really ugly, I'd prefer not
# to.)
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
    my $val;

    if ($v->bounds_check($$self{min}, $$self{max})) {
        # for each dimension, go one level deeper into the array.
        $val = $$self{torus};
        for(my $d = $$self{nd} - 1; defined($val) && ($d > -1); $d--) {
            $val = $$val[$v->get_component($d) - $$self{min}->get_component($d)];
        }
    }
    return $val if defined $val;
    return 32;  # Default to space.
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
    # for each dimension, go one level deeper into the array.
    my $line = $$self{torus};
    for(my $d = $$self{nd} - 1; ($d > 0); $d--) {
        my $i = $v->get_component($d) - $$self{min}->get_component($d);
        $line = $$line[$i];
    }
    $$line[$v->get_component(0) - $$self{min}->get_component(0)] = $val;
}


#
# my $str = rectangle( start, size )
#
# Return a string containing the data/code in the specified rectangle.
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
    my $nd = $$self{nd};
    my @directions = ();
    foreach my $dimension (0..$nd-1) {
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


1;
__END__

=head1 NAME

Language::Befunge::Storage::Generic::AoA - a generic N-dimensional LaheySpace.


=head1 SYNOPSIS

    # create a 3-dimensional LaheySpace.
    my $torus = Language::Befunge::Storage::Generic::AoA->new(3);
    $torus->clear();
    $torus->store(<<"EOF");
    12345
    67890
    \fabcde
    fghij
    EOF

Note you usually don't need to use this module directly.
B<Language::Befunge::Interpreter> uses it internally, for non-2-dimensional
storage.  For 2-dimensional storage, B<Language::Befunge::Storage::2D> is used
instead, because it is more efficient.


=head1 DESCRIPTION

This module implements an N-dimensional storage space, as an array of arrays.


=head1 CONSTRUCTOR

=head2 new( dimensions )

Creates a new Lahey Space.


=head1 PUBLIC METHODS

=head2 clear(  )

Clear the torus.


=head2 expand( vector )

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


=head2 rectangle( start, size )

Return a string containing the data/code in the specified rectangle.


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

L<Language::Befunge::LaheySpace>, L<Language::Befunge>.


=head1 AUTHOR

Mark Glines, E<lt>infinoid@cpan.orgE<gt>
Jerome Quelin, E<lt>jquelin@cpan.orgE<gt>

Development is discussed on E<lt>language-befunge@mongueurs.netE<gt>


=head1 COPYRIGHT & LICENSE

Copyright (c) 2001-2008 Jerome Quelin, all rights reserved.

This program is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.


=cut
