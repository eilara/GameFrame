package GameFrame::Animation::Curve;

use Moose;

has solve_curve_cb => (is => 'ro', lazy_build => 1);

sub solve_edge_value { shift->solve_curve_cb->(pop) }

1;

__END__

