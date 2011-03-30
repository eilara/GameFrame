package GameFrame::ResourceManager;

use strict;
use warnings;
use base 'Exporter';
use FindBin qw($Bin);
our @EXPORT = qw(image_resource);

my $Resource_Path = "$Bin/resources";
sub Set_Path($) { $Resource_Path = shift }

sub image_resource($) {
    my $name = shift;
    return "$Resource_Path/images/$name.png";
}

1;
