package Bar;

use Cwd;

BEGIN {
    cwd();
}

sub my_croak {
    require Carp;
    Carp::croak(cwd, @_);
}

1;
