#!/usr/bin/perl -w

use lib qw(t/lib);
use Test::More tests => 58;
use Config;

my $Mod_Info_VERSION = '0.23';

my @old5lib = defined $ENV{PERL5LIB} ? ($ENV{PERL5LIB}) : ();
$ENV{PERL5LIB} = join $Config{path_sep}, 'blib/lib', @old5lib;

use_ok('Module::Info');
my @expected_subs = qw(
                       new_from_file
                       new_from_module
                       new_from_loaded
                       all_installed
                       _find_all_installed
                       name               
                       version            
                       inc_dir            
                       file               
                       is_core            
                       packages_inside    
                       package_versions
                       modules_required
                       modules_used       
                       _file2mod          
                       subroutines        
                       superclasses
                       die_on_compilation_error
                       _is_macos_classic
                       _is_win95
                       _call_B
                       _call_perl
                       _get_extra_arguments
                       subroutines_called
                       dynamic_method_calls
                      );

can_ok('Module::Info', @expected_subs);

my $mod_info = Module::Info->new_from_file('lib/Module/Info.pm');
isa_ok($mod_info, 'Module::Info', 'new_from_file');

ok( !$mod_info->name,                       '    has no name' );
$mod_info->name('Module::Info');
ok( $mod_info->name,                        '    name set' );
is( $mod_info->version, $Mod_Info_VERSION,  '    version()' );
ok( !$mod_info->inc_dir,                    '    has no inc_dir' );
is( $mod_info->file, File::Spec->rel2abs('lib/Module/Info.pm'),
                                            '    file()');
ok( !$mod_info->is_core,                    '    not a core module' );

SKIP: {
    skip "Only works on 5.6.1 and up.", 8 unless $] >= 5.006001;

    @expected_subs = map "Module::Info::$_", @expected_subs;

    my @packages = $mod_info->packages_inside;
    is( @packages, 1,                   'Found a single package inside' );
    is( $packages[0], 'Module::Info',   '  and its what we want' );

    my %versions = $mod_info->package_versions;
    is( keys %versions, 1,                '1 package with package_versions()');
    is( $versions{Module::Info}, $Mod_Info_VERSION, 'version is correct');

    my %subs = $mod_info->subroutines;
    is( keys %subs, @expected_subs,    'Found all the subroutines' );
    is_deeply( [sort keys %subs], 
               [sort @expected_subs],  '   names' );
    
    my @mods = $mod_info->modules_used;
    is( @mods, 6,           'Found all modules used' );
    is_deeply( [sort @mods], [sort qw(strict File::Spec Config 
                                      Carp IPC::Open3 vars)],
                            '    the right ones' );
}


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
@core_inc = map { File::Spec->canonpath($_) }
  ($Config{installarchlib}, $Config{installprivlib});
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


# Ensure that code refs in @INC are skipped.
my @mods = Module::Info->all_installed('Module::Info', (@INC, sub { die }));
ok( @modules,       'all_installed() returned something' );
ok( !(grep { !defined $_ || !$_->isa('Module::Info') } @modules),
                    "  they're all Module::Info objects"
  );


SKIP: {
    skip "Only works on 5.6.1 and up.", 17 unless $] >= 5.006001;

    my $module = Module::Info->new_from_file('t/lib/Foo.pm');
    my @packages = $module->packages_inside;
    is( @packages, 2,       'Found two packages inside' );
    ok( eq_set(\@packages, [qw(Foo Bar)]),   "  they're right" );

    my %versions = $module->package_versions;
    is( keys %versions, 2,                '2 packages with package_versions()');
    is( $versions{Foo}, '7.254',          'version is correct');
    is( $versions{Bar}, undef,            'no version present');

    my %subs = $module->subroutines;
    is( keys %subs, 2,                          'Found two subroutine' );
    ok( exists $subs{'Foo::wibble'},            '   its right' );

    my($start, $end) = @{$subs{'Foo::wibble'}}{qw(start end)};
    print "# start $start, end $end\n";
    is( $start, 21,           '   start line' );
    is( $end,   22,           '   end line'   );

    my @mods = $module->modules_used;
    is( @mods, 7,           'modules_used' );
    is_deeply( [sort @mods], 
               [sort qw(strict vars Carp Exporter t/lib/Bar.pm t/lib/Foo.pm lib)] );

    $module->name('Foo');
    my @isa = $module->superclasses;
    is( @isa, 3,            'isa' );
    is_deeply( [sort @isa], [sort qw(This That What::Ever)] );

    my @calls = $module->subroutines_called;

    my $startline = 25;
    my @expected_calls = ({
                           line     => $startline,
                           class    => undef,
                           type     => 'function',
                           name     => 'wibble'
                          },
                          {
                           line     => $startline + 1,
                           class    => undef,
                           type     => 'symbolic function',
                           name     => undef,
                          },
                          {
                           line     => $startline + 2,
                           class    => 'Foo',
                           type     => 'class method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 3,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 5,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble',
                          },
                          {
                           line     => $startline + 7,
                           class    => 'Foo',
                           type     => 'dynamic class method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 8,
                           class    => undef,
                           type     => 'dynamic object method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 9,
                           class    => undef,
                           type     => 'dynamic object method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 10,
                           class    => 'Foo',
                           type     => 'dynamic class method',
                           name     => undef,
                          },
                          {
                           line     => $startline + 14,
                           class    => undef,
                           type     => 'object method',
                           name     => 'wibble'
                          },
                          {
                           line     => $startline + 27,
                           class    => undef,
                           type     => 'function',
                           name     => 'croak'
                          },
                         );
    is_deeply(\@calls, \@expected_calls, 'subroutines_called');
    is_deeply([$module->dynamic_method_calls],
              [grep $_->{type} =~ /dynamic/, @expected_calls]);

    $module = Module::Info->new_from_file('t/lib/Bar.pm');
    @mods   = $module->modules_used;
    is( @mods, 3, 'modules_used with complex BEGIN block' );
    is_deeply( sort @mods,
               (sort qw(Cwd Carp strict)) );
}
