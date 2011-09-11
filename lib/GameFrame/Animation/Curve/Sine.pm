package GameFrame::Animation::Curve::Sine;

use Moose;
use Scalar::Util qw(weaken);
use Math::Trig;
use Math::Vector::Real;

# TODO support nD

has [qw(amp freq)] => (is => 'rw', required => 1);
has normal => (is => 'rw');

extends 'GameFrame::Animation::Curve::Linear';

sub BUILD {
    my $self = shift;
    $self->freq( $self->freq * pi * 2 );
    my $delta = $self->to - $self->from;
    my $normal = V(-1*$delta->[1], $delta->[0]);
    $normal->[1] = 1 if 
        ($normal->[0] == 0 and $normal->[1] == 0);
    $normal /= abs($normal);
    $self->normal($normal);
}

sub compute_curve_length {
    my $self = shift;
    my $delta = $self->to - $self->from;
    return 2*abs($delta); # upper limit on length
}

sub solve_edge_value { shift->solve_curve_cb->(pop) }

sub _build_solve_curve_cb {
    my $self = shift;
    weaken $self;
    return sub {
        my $elapsed = shift;
        my $from    = $self->from;
        my $delta   = $self->to - $from;
        my $sine    = sin($elapsed * $self->freq) * $self->amp;
        my $value   = $from + $elapsed * $delta + $sine * $self->normal;
        return $value;
    };
}

1;

__END__

/*
Copyright (c) 2009 Drew Cummins

Permission is hereby granted, free of charge, to any person
obtaining a copy of this software and associated documentation
files (the "Software"), to deal in the Software without
restriction, including without limitation the rights to use,
copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the
Software is furnished to do so, subject to the following
conditions:

The above copyright notice and this permission notice shall be
included in all copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES
OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT
HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY,
WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING
FROM, OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR
OTHER DEALINGS IN THE SOFTWARE.
*/
