use inc::Module::Install;

name 'tinyurl';
all_from 'lib/tinyurl.pm';

requires Catalyst => '5.64';

catalyst;

install_script glob('script/*.pl');
auto_install;
WriteAll;
