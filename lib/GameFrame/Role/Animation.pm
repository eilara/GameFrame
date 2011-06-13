package GameFrame::Role::Animation;

use Moose::Role;

requires qw(
    start_animation
    restart_animation
    stop_animation
    pause_animation
    resume_animation
    is_animation_started
    wait_for_animation_complete
);

1;


