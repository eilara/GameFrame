package GameFrame::Grid::Waypoints;

use Moose;
use MooseX::Types::Moose qw(Bool Num Int Str ArrayRef);
use aliased 'GameFrame::Grid::Markers';

has markers => (
    is       => 'ro',
    required => 1,
    isa      => Markers,
    weak_ref => 1,
    handles  => [qw(spacing)],
);

has waypoints => ( # waypoints specified as ASCII art
    is       => 'ro',
    required => 1,
    isa      => Str,
);

has path_color => (
    is       => 'ro',
    required => 1,
    isa      => Int,
    default  => 0xA1A1A1FF,
);

has waypoint_cells => ( # col/row of waypoints in order
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
    isa        => ArrayRef[ArrayRef[Num]],
);

has path_cells => ( # col/row of path cells in no order in particular
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
    isa        => ArrayRef[ArrayRef[Num]],
);

has points_px => ( # center of waypoints in px
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
    isa        => ArrayRef[ArrayRef[Num]],
);

has cached_path_rects => ( # [[x,y,w,h], color] rects of path cells
    is         => 'ro',
    required   => 1,
    lazy_build => 1,
    isa        => ArrayRef,
);

with 'GameFrame::Role::Paintable';

sub _build_waypoint_cells {
    my $self = shift;
    my %cells;
    $self->for_char_in_map(sub{
        my ($c, $col, $row) = @_;
        return unless $c =~ /[A-Z]/;
        $cells{$c} = [$col, $row];
    });
    return [map { $cells{$_} } sort keys %cells];
}

sub _build_path_cells {
    my $self = shift;
    my @cells;
    $self->for_char_in_map(sub{
        my ($c, $col, $row) = @_;
        push @cells, [$col, $row];
    });
    return [@cells];
}

sub _build_points_px {
    my $self = shift;
    my $s = $self->spacing;
    my $s2 = $s / 2;
    return [map {
        my ($col, $row) = @$_;
        [$col*$s + $s2, $row*$s + $s2];
    } @{$self->waypoint_cells}];
}

sub _build_cached_path_rects {
    my $self = shift;
    my $c    = $self->path_color;
    my $s    = $self->spacing;
    return [map {
        my ($cx, $cy) = @$_;
        my ($col, $row) = @$_;
        [ [$col*$s+1, $row*$s+1, $s-2, $s-2], $c ];
    } @{ $self->path_cells }];
}

# parse ASCII art
sub for_char_in_map {
    my ($self, $code) = @_;
    my @lines = grep /\S/, split /\n/, $self->waypoints;
    my $row = 0;
    for my $l (@lines) {
        my $col = 0;
        $l =~ s/\s//g;
        for my $c (split //, $l) {
            $code->($c, $col, $row) unless $c eq '.';
            $col++;
        }
        $row++;
    }
}

sub paint {
    my $self = shift;
    $self->draw_rect([@{$_->[0]}], $_->[1]) # draw path, avoid aliasing
        for @{ $self->cached_path_rects };
#    draw waypint marks    
#    $surface->draw_rect([$_->[0] - 1, $_->[1] -1, 2, 2], 0xFFFF00FF)
#        for @{ $self->points_px };
}

1;

