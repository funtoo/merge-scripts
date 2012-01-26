# Copyright 1999-2009 Gentoo Foundation
# Distributed under the terms of the GNU General Public License v2

# This file contains a custom OS package to provide information on the
# installation structure on Gentoo. It is based on the Debian OS equivalent
# that is built into Logitech Media Server.

package Slim::Utils::OS::Custom;

use strict;
use File::Spec::Functions qw(:ALL);
use FindBin qw($Bin);
use Config;

use base qw(Slim::Utils::OS::Linux);

sub initDetails {
	my $class = shift;

	$class->{osDetails} = $class->SUPER::initDetails();

	$class->{osDetails}->{isGentoo} = 1 ;

	# Make sure we can find any CPAN modules packaged with Squeezebox Server.
	unshift @INC, '/usr/share/logitechmediaserver/CPAN';

	# Make sure plugin files are found.
	push @INC, '/var/lib/logitechmediaserver';
	
	return $class->{osDetails};
}

=head2 dirsFor( $dir )

Return OS Specific directories.

Argument $dir is a string to indicate which of the Squeezebox Server directories we
need information for.

=cut

sub dirsFor {
	my ($class, $dir) = @_;

	my @dirs = ();
	
	if ($dir =~ /^(?:oldprefs|updates)$/) {

		push @dirs, $class->SUPER::dirsFor($dir);

	} elsif ($dir =~ /^(?:Firmware|Graphics|HTML|IR|MySQL|SQL|lib|Bin)$/) {

		push @dirs, "/usr/share/logitechmediaserver/$dir";

	} elsif ($dir eq 'Plugins') {
			
		push @dirs, $class->SUPER::dirsFor($dir);
		push @dirs, "/var/lib/logitechmediaserver/Plugins", "/usr/lib/" . $Config{'package'} . "/vendor_perl/" . $Config{'version'} . "/Slim/Plugin";
		
	} elsif ($dir =~ /^(?:strings|revision)$/) {

		push @dirs, "/usr/share/logitechmediaserver";

	} elsif ($dir eq 'libpath') {

		push @dirs, "/usr/lib/logitechmediaserver";

	# Because we use the system MySQL, we need to point to the right
	# directory for the errmsg. files. Default to english.
	} elsif ($dir eq 'mysql-language') {

		push @dirs, "/usr/share/mysql/english";

	} elsif ($dir =~ /^(?:types|convert)$/) {

		push @dirs, "/etc/logitechmediaserver";

	} elsif ($dir =~ /^(?:prefs)$/) {

		push @dirs, $::prefsdir || "/var/lib/logitechmediaserver/prefs";

	} elsif ($dir eq 'log') {

		push @dirs, $::logdir || "/var/log/logitechmediaserver";

	} elsif ($dir eq 'cache') {

		push @dirs, $::cachedir || "/var/lib/logitechmediaserver/cache";

	} elsif ($dir =~ /^(?:music|playlists)$/) {

		push @dirs, '';

	} else {

		warn "dirsFor: Didn't find a match request: [$dir]\n";
	}

	return wantarray() ? @dirs : $dirs[0];
}

# Bug 9488, always decode on Ubuntu/Debian
sub decodeExternalHelperPath {
	return Slim::Utils::Unicode::utf8decode_locale($_[1]);
}

sub scanner {
	return '/usr/sbin/logitechmediaserver-scanner';
}


1;




1;

__END__
