package GameFrame::Role::HealthBar;

# shows a bar with health ratio of a living thing

use Moose::Role;
use MooseX::Types::Moose qw(Num ArrayRef);
use Math::Vector::Real;
use GameFrame::Types qw(Vector2D);

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Living
);

# xy offset of health bar from top left xy of positionable
# even if it is centered => 1
has health_bar => (
    is      => 'rw',
    isa     => Vector2D,
    coerce  => 1,
    default => sub { V(0, -20, 22, 2) },
);

after paint => sub {
    my $self = shift;
    my $hp_ratio = $self->hp_ratio;
    my $bar = $self->health_bar;
    my $xy = $self->xy_vec;
    my $x = $bar->[0] + $xy->[0];
    my $y = $bar->[1] + $xy->[1];
    my ($w, $h) = ($bar->[2], $bar->[3]);
    # draw black border
    $self->draw_rect([$x, $y, $w, $h + 2], 0x000000FF);
    # draw red background
    $self->draw_rect([$x+1, $y+1, $w-2, $h], 0x9F0000FF);
    # green for health
    $self->draw_rect([$x+1, $y+1, $hp_ratio*($w-2), $h], 0x009F00FF);
};

1;
