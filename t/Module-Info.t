#!/usr/bin/perl -w

use lib qw(t/lib);
use Test::More tests => 30;
use Config;

my $Mod_Info_VERSION = 0.04;

use_ok('Module::Info');
can_ok('Module::Info', qw(new_from_file new_from_module all_installed
                          name version inc_dir file is_core
                          packages_inside modules_used
                         ));

my $mod_info = Module::Info->new_from_file('lib/Module/Info.pm');
isa_ok($mod_info, 'Module::Info', 'new_from_file');

ok( !$mod_info->name,                       '    has no name' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->inc_dir,                    '    has no inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


$mod_info = Module::Info->new_from_module('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


# Grab the core version of Text::Soundex and hope it hasn't been
# deleted.
@core_inc = ($Config{installarchlib}, $Config{installprivlib});
$mod_info = Module::Info->new_from_module('Text::Soundex', @core_inc);
is( $mod_info->name, 'Text::Soundex',       '    name()' );

# dunno what the version will be, 5.004's had none.

ok( grep($mod_info->inc_dir eq $_, @core_inc),       '    inc_dir()' );
is( $mod_info->file, 
    File::Spec->catfile( $mod_info->inc_dir, 'Text', 'Soundex.pm' ),
                                            '    file()');
ok( $mod_info->is_core,                     '    core module' );


$mod_info = Module::Info->new_from_loaded('Module::Info');
isa_ok($mod_info, 'Module::Info', 'new_from_module');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
is( $mod_info->inc_dir, File::Spec->rel2abs('blib/lib'),
                                            '    inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('blib/lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );


@modules = Module::Info->all_installed('Module::Info');
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );

# I have no idea how many I'm going to get, so I'll only play with the 
# first one.  It's the current one.
$mod_info = $modules[0];
isa_ok($mod_info, 'Module::Info', 'all_installed');

is( $mod_info->name, 'Module::Info',        '    name()' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->is_core,                    '    not a core module' );
