
{
    app_args => [
        size               => [640, 480],
        title              => 'Perl SDL GameFrame Example',
        bg_color           => 0x0,
        resources          => "$Bin/resources",
        layer_manager_args => [layers => [qw(path top)]],
    ],

    markers_args => [
        spacing            => 80,
    ],

    crawler_args => [
        image              => 'arrow',
        layer              => 'top',
        is_visible         => 0,
        v                  => 250,
    ],

    waypoints_args => [
        layer              => 'path',
        waypoints          => <<'END_OF_MAP',
                              ...A....
                              G######H
                              #..#...#
                              #..BC..#
                              #...D..#
                              F###E..I
END_OF_MAP
    ],
}

