package GameFrame::Util::Vectors;

use strict;
use warnings;
use Math::Vector::Real;
use Math::Trig;
use base 'Exporter';

our @EXPORT = qw(pi V VP angle_between);

# polar vector: angle and distance
sub VP {
    my ($angle, $dist) = @_;
    return V( 
        $dist * cos($angle),
        $dist * sin($angle),
    );

}

sub angle_between {
    my ($v1, $v2) = @_;
    my ($dx, $dy) = @{ $v2 - $v1 };
    # $to is too close to compute angle
    return undef if abs($dx) < 0.5 and abs($dy) < 0.5;
    return atan2($dy, $dx);
}

1;

