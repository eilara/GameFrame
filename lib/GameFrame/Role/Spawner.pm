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

# number of waves to spawn
has waves_to_spawn => (is => 'rw');

has spawn_start_time => (is => 'rw');

with qw(
    GameFrame::Role::Animated
    GameFrame::Role::Active::Container
);

sub spawn {
    my ($self, %args) = @_;
    my $waves = delete $args{waves} || "Can't spawn with no waves";
    $self->waves_to_spawn($waves);
    my $ani = $self->create_animation({
        attribute   => 'current_wave',
        proxy_class => IntProxy,
        from_to     => [1, $waves],
        %args,
    });
    $self->animation($ani);
    $self->spawn_start_time($ani->timeline->now);
    $ani->start_animation_and_wait;
}

sub current_wave {
    my ($self, $new_wave) = @_;
    my $current_wave = $self->next_child_idx;
    return $current_wave if @_ == 1;
    return if $current_wave >= $new_wave;
    for my $wave (1..($new_wave - $current_wave)) {
        my $passed = $self->waves_to_spawn == 1? 0:
                ($current_wave + $wave - 1) * 
                    $self->animation->duration / ($self->waves_to_spawn - 1);
        my $ideal_spawn_time = $self->spawn_start_time + $passed;
        $self->create_next_child(start_time => $ideal_spawn_time);
    }
}

1;

