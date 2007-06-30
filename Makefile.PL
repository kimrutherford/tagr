use Module::Build::Compat;
use inc::Module::Install;

name('EchoMemo');
abstract('Catalyst Application');
author('Kim Rutherford');
version_from('lib/EchoMemo.pm');
license('perl');

include('ExtUtils::AutoInstall');

requires( Catalyst => '5.60' );

catalyst_files();

install_script( glob('script/*.pl') );
auto_install();
&WriteAll;

Module::Build::Compat->run_build_pl(args => \@ARGV);
Module::Build::Compat->write_makefile();
