package Bar;

use Cwd;

BEGIN {
    cwd();
}

BEGIN {
    $x = 1;
    $x = 2;
    require strict;
}

sub my_croak {
    require Carp;
    Carp::croak(cwd, @_);
}

1;
