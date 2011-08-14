package GameFrame::Role::Spawner;

use Moose::Role;
use aliased 'GameFrame::Animation::Proxy::Int' => 'IntProxy';
use aliased 'GameFrame::Role::Animation';

has animation => (
    is       => 'rw',
    does     => Animation,
    weak_ref => 1,
    handles  => Animation,
);

with qw(
    GameFrame::Role::Animated
    GameFrame::Role::Active::Container
);

sub spawn {
    my ($self, %args) = @_;
    my $waves = delete $args{waves} || "Can't spawn with no waves";
    my $ani = $self->create_animation({
        attribute   => 'current_wave',
        proxy_class => IntProxy,
        from_to     => [1, $waves],
        %args,
    });
    $self->animation($ani);
    $ani->start_animation_and_wait;
}

sub current_wave {
    my ($self, $new_wave) = @_;
    my $current_wave = $self->next_child_idx;
    return $current_wave if @_ == 1;
    return if $current_wave >= $new_wave;
    $self->create_next_child for 1..($new_wave - $current_wave);
}

1;

