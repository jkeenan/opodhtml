#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

use strict;
use Carp;
use Cwd;
use File::Copy;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Pod::Html qw(pod2html);
use Pod::Html::Auxiliary qw(
    unixify
);
use Test::More tests =>  2;

my $cwd = Pod::Html::unixify(Cwd::cwd());
my $source_infile = "t/cache.pod";

{
    my $tdir = tempdir( CLEANUP => 1 );
    make_path("$tdir/alpha", "$tdir/beta", "$tdir/gamma", "$tdir/t", {
        verbose => 0,
        mode => 0755,
    });
    my $infile = "$tdir/alpha/cache.pod";
    my $outfile ="cacheout.html",
    copy $source_infile => $infile
        or croak "Unable to copy $infile";
    chdir $tdir or croak "Unable to change to $tdir";
    my $podroot_set = "..";
    my $podpath_set = join(':' => qw( alpha beta gamma ));

    my $cachefile = "pod2htmd.tmp";
    unlink $cachefile;
    is(-f $cachefile, undef, "No cache file to start");
    my %pages = ();
    my %expected_pages = ();

    my $rv = pod2html(
        "--infile=$infile",
        "--outfile=$outfile",
        "--podpath=scooby:shaggy:fred:velma:daphne",
        "--podroot=$tdir",
    );
    ok($rv, "pod2html() returned true value");

    chdir($cwd) or croak "Cannot change back to starting point";
} # end of $tdir

