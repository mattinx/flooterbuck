#------------------------------------------------------------------------
# eBay auction status request
#
# Dave Brown
#
# $Id: fcol.pm,v 1.5 2002/08/03 13:31:24 dagbrown Exp $
#------------------------------------------------------------------------
package fcol;
use strict;


=head1 NAME

fcol.pm - generate a fcol from a big long url

=head1 PREREQUISITES

LWP::Simple, URI::Escape, POSIX

=head1 PARAMETERS

UTL

=head1 PUBLIC INTERFACE

sigsegv, fcol <url>

=head1 DESCRIPTION

This allows you to generate a "fcol" from a great big long url.

=head1 AUTHOR

Dave Brown <dagbrown@csclub.uwaterloo.ca>

=cut

#------------------------------------------------------------------------
# Startup
#
# Check that LWP is available, so we don't waste our time
# generating error messages later on.
#------------------------------------------------------------------------
my $no_fcol;
my $no_posix;

BEGIN {
    foreach my $lib qw(LWP::Simple URI::Escape) {
        eval qq{
            use $lib;
        };
        $no_fcol++ if ($@);
    }
    eval qq/use POSIX;/;
    $no_posix++ if ($@);
}

#------------------------------------------------------------------------
# fcol_create
#
# Given a long URL, return the fcol version.
#------------------------------------------------------------------------
sub fcol_create($) {
    my $longurl=shift;

    my $fcol=LWP::Simple::get('http://fcol.org/bot?'.uri_escape($longurl));

    chomp $fcol;
    return "Your fcol is $fcol";
}

#------------------------------------------------------------------------
# fcol_getdata
#
# Tear apart the line fed to the infobot, check its syntax,
# and feed the URL into fcol_create.
#------------------------------------------------------------------------
sub fcol_getdata($) {
    my $line=shift;

    if($line =~ /fcol\s+(\w+:\S+)/i) {
        return fcol_create($1);
    }
}

#------------------------------------------------------------------------
# fcol::get
#
# This handles the forking (or not) stuff.
#------------------------------------------------------------------------
sub fcol::get($$) {
    if($no_fcol) {
        &main::status("Sorry, fcol.pm requires LWP and couldn't find it");
        return "";
    }

    my($line,$callback)=@_;
    $SIG{CHLD}="IGNORE";
    my $pid=eval { fork(); };         # Don't worry if OS isn't forking
    return 'NOREPLY' if $pid;
    $callback->(&fcol_getdata($line));
    if (defined($pid))                # child exits, non-forking OS returns
    {
        exit 0 if ($no_posix);
        POSIX::_exit(0);
    }
}

#------------------------------------------------------------------------
# This is the main interface to infobot
#------------------------------------------------------------------------

sub scan(&$$) {
    my ($callback, $message, $who)=@_;

    if ( $message =~ /^\s*(?:fcol|tinyurl|shrivel)\s+(\w+:\S+)/i ) {
        &main::status("fcol small-URL creation");
        fcol::get($message,$callback);
        return 1;
    }
}

"fcol";