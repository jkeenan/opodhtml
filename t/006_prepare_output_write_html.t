# -*- perl -*-

BEGIN {
    die "Run me from outside the t/ directory, please" unless -d 't';
}

# test the directory cache
# XXX test --flush and %Pages being loaded/used for cross references

use strict;
use Carp;
use Cwd;
use File::Copy;
use File::Path qw( make_path );
use File::Temp qw( tempdir );
use Pod::Html ();
use Pod::Html::Auxiliary qw(
    unixify
);
use Test::More tests =>  7;

my ($options, $p2h, $rv);
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

    $options = {
        infile => $infile,
        outfile  => $outfile,
        podpath => "scooby:shaggy:fred:velma:daphne",
        podroot => $tdir,
    };
    $p2h = Pod::Html->new();
    $p2h->process_options( $options );
    $p2h->cleanup_elements();
    $rv = $p2h->generate_pages_cache();
    ok(defined($rv),
        "generate_pages_cache() returned defined value, indicating full run");
    
    my $parser = $p2h->prepare_parser();
    ok($parser, "prepare_parser() returned true value");
    isa_ok($parser, 'Pod::Simple::XHTML');
    ok($p2h->prepare_html_components($parser),
        "prepare_html_components() returned true value");
    
    my $output = $p2h->prepare_output($parser);
    ok(defined $output, "prepare_output() returned defined value");

    my $rv = $p2h->write_html($output);
    ok($rv, "write_html() returned true value");

    chdir($cwd) or croak "Cannot change back to starting point";
} # end of $tdir

