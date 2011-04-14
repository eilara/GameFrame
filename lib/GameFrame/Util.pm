package GameFrame::Util;

use strict;
use warnings;
use base 'Exporter';

our @EXPORT_OK = qw(
    distance
    is_in_rect
);

# TODO: move to rectangular
sub is_in_rect {
    my ($x, $y, $left, $top, $w, $h) = @_;
    return
        ($x >= $left && $x <= $left + $w) &&
        ($y >= $top  && $y <= $top + $h);
}

sub distance {
    my ($x1, $y1, $x2, $y2) = @_;
    return sqrt( ($x1 - $x2)**2 + ($y1 - $y2)**2 );
}

1;

