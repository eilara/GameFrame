package GameFrame::Role::HealthBar;

# shows a bar with health ratio of a living thing

use Moose::Role;
use MooseX::Types::Moose qw(Num ArrayRef);

requires 'w'; # need width to size the health bar

with qw(
    GameFrame::Role::Paintable
    GameFrame::Role::Living
);

# xy offset of health bar from top left xy of positionable
# even if it is centered => 1
has health_bar_offset => (
    is       => 'ro',
    isa      => ArrayRef[Num],
    default  => sub { [0, -20] },
);

after paint => sub {
    my ($self, $surface) = @_;
    my $hp_ratio = $self->hp_ratio;
    my @offset = @{ $self->health_bar_offset };
    my ($x, $y) = ($self->x + $offset[0], $self->y + $offset[1]);
    my $w = $self->w;
    # draw black border
    $surface->draw_rect([$x  , $y  , $w  , 4], 0x0);
    # draw red background
    $surface->draw_rect([$x+1, $y+1, $w-2, 2], 0x9F0000FF);
    # green for health
    $surface->draw_rect([$x+1, $y+1, $hp_ratio*($w-2), 2], 0x009F00FF);
};

1;
