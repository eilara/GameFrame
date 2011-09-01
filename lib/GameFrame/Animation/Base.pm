package GameFrame::Animation::Base;

use Moose;
use Scalar::Util qw(weaken);
use GameFrame::MooseX;
use aliased 'GameFrame::Animation::Timeline';
use aliased 'GameFrame::Animation::CycleLimit';

compose_from Timeline,
    inject => sub {
        my $self = shift;
        weaken $self;
        return (
            cycle_limit => $self->_build_cycle_limit,
            provider    => $self,
            $self->_suggest_timer_sleep,
        );
    },        
    has => {handles => {
        _start_animation            => 'start',
        restart_animation           => 'restart',
        stop_animation              => 'stop',
        pause_animation             => 'pause',
        resume_animation            => 'resume',
        is_animation_started        => 'is_timer_active',
        wait_for_animation_complete => 'wait_for_animation_complete',
        is_reversed_dir             => 'is_reversed_dir',
    }};

with 'GameFrame::Role::Animation';

sub start_animation { shift->_start_animation(@_) }

sub _suggest_timer_sleep { () }

1;


