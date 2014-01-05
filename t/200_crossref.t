#!/usr/bin/perl -w                                         # -*- perl -*-
use strict;
use Data::Dump;
use Carp;
use Cwd;
require Config;
use File::Copy;
use File::Path qw( make_path );
use File::Spec;
use File::Spec::Unix;
use File::Temp qw( tempdir );
use Pod::Html ();
use Pod::Html::Auxiliary qw(
    unixify
);
use lib qw( t/lib );
use Test::More qw(no_plan); # tests =>  1;

my $start_dir = Pod::Html::unixify(Cwd::cwd());
my $testname = 'cross references';
{
    my $tdir = tempdir( CLEANUP => 1 );
    chdir $tdir or croak "Unable to change to tempdir";
    make_test_dir($start_dir);
    my $podfile = 'crossref';
    copy "$start_dir/t/$podfile.pod" => "$tdir/t/"
        or croak "Unable to copy $podfile.pod";

    my $f = get_files_and_dirs($podfile);
Data::Dump::pp($f);

    my $constructor_args = {
        infile      => $f->{infile},
        outfile     => $f->{outfile},
#        podpath         => 't',
        htmlroot    => '/',
#        podroot         => $cwd,
        podpath     => join(':' => (
                        File::Spec::Unix->catdir($f->{relcwd}, 't'),
                        File::Spec::Unix->catdir($f->{relcwd}, 'testdir/test.lib'),
                       ) ),
        podroot     => File::Spec::Unix->catpath($f->{volume}, '/', ''),
        quiet       => 1,
    };
Data::Dump::pp($constructor_args);

    ok(Pod::Html::run($constructor_args), "Pod::Html methods completed");

    $f->{cwd} =~ s|\/$||;
    my ($expect, $result);
    {
        local $/;
        $expect = <DATA>;
        $expect =~ s/\[PERLADMIN\]/$Config::Config{perladmin}/;
        $expect =~ s/\[RELCURRENTWORKINGDIRECTORY\]/$f->{relcwd}/g;
        $expect =~ s/\[ABSCURRENTWORKINGDIRECTORY\]/$f->{cwd}/g;
        if (ord("A") == 193) { # EBCDIC.
            $expect =~ s/item_mat_3c_21_3e/item_mat_4c_5a_6e/;
        }
        open my $IN, $f->{outfile} or die "cannot open $f->{outfile}: $!";
        $result = <$IN>;
        close $IN or die "cannot close $f->{outfile}: $!";
    }
    my ($diff, $diffopt) = identify_diff();
    if ($diff) {
        ok($expect eq $result, $testname) or do {
            my $expectfile = "${podfile}_expected.tmp";
print STDERR "expectfile: $expectfile\n";
            open my $TMP, ">", $expectfile
                or die "Unable to open for writing: $!";
            print $TMP $expect;
            close $TMP or die "Unable to close after writing: $!";
            open my $DIFF_FH, "$diff $diffopt $expectfile $f->{outfile} |"
                or die "Unable to open to diff: $!";
            print STDERR "# $_" while <$DIFF_FH>;
            close $DIFF_FH;
            unlink $expectfile;
        };
    }
    else {
        # This is fairly evil, but lets us get detailed failure modes
        # anywhere that we've failed to identify a diff program.
        is($expect, $result, $testname);
    }

    pass($0);

    chdir $start_dir or croak "Unable to change back to starting place";
}

sub get_files_and_dirs {
    my $podfile = shift;
    croak "Must provide stem of basename of pod file" unless $podfile;
    my $cwd = unixify( Cwd::cwd() );
    my ($vol, $dir) = File::Spec->splitpath($cwd, 1);
    my @dirs = File::Spec->splitdir($dir);
    shift @dirs if $dirs[0] eq '';
    my $relcwd = join '/', @dirs;

    my $new_dir  = File::Spec->catdir($dir, "t");
    my $infile   = File::Spec->catpath($vol, $new_dir, "$podfile.pod");
    my $outfile  = File::Spec->catpath($vol, $new_dir, "$podfile.html");
    return {
        volume      => $vol,
        cwd         => $cwd,
        relcwd      => $relcwd,
        infile      => $infile,
        outfile     => $outfile,
    };
}

sub identify_diff {
    my $diff = '/bin/diff';
    -x $diff or $diff = '/usr/bin/diff';
    -x $diff or $diff = undef;
    my $diffopt = $diff ? $^O =~ m/(linux|darwin)/ ? '-u' : '-c'
                        : '';
    $diff = 'fc/n' if $^O =~ /^MSWin/;
    $diff = 'differences' if $^O eq 'VMS';
    return ($diff, $diffopt);
}

sub make_test_dir {
    my ($start_dir) = @_;
    make_path('testdir/test.lib', 't', {
        verbose => 0,
        mode => 0755,
    });
    copy("$start_dir/testdir/perlpodspec-copy.pod", 'testdir/test.lib/podspec-copy.pod')
        or croak "Could not copy perlpodspec-copy";
    copy("$start_dir/testdir/perlvar-copy.pod", 'testdir/test.lib/var-copy.pod')
        or croak "Could not copy perlvar-copy!";
    return 1;
}


__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body>



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#LINKS">LINKS</a></li>
  <li><a href="#TARGETS">TARGETS</a>
    <ul>
      <li><a href="#section1">section1</a></li>
    </ul>
  </li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmlcrossref - Test HTML cross reference links</p>

<h1 id="LINKS">LINKS</h1>

<p><a href="#section1">&quot;section1&quot;</a></p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/t/htmllink.html#section-2">&quot;section 2&quot; in htmllink</a></p>

<p><a href="#item1">&quot;item1&quot;</a></p>

<p><a href="#non-existant-section">&quot;non existant section&quot;</a></p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/testdir/test.lib/var-copy.html">var-copy</a></p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/testdir/test.lib/var-copy.html#pod">&quot;$&quot;&quot; in var-copy</a></p>

<p><code>var-copy</code></p>

<p><code>var-copy/$&quot;</code></p>

<p><a href="/[RELCURRENTWORKINGDIRECTORY]/testdir/test.lib/podspec-copy.html#First">&quot;First:&quot; in podspec-copy</a></p>

<p><code>podspec-copy/First:</code></p>

<p><a>notperldoc</a></p>

<h1 id="TARGETS">TARGETS</h1>

<h2 id="section1">section1</h2>

<p>This is section one.</p>

<dl>

<dt id="item1">item1  </dt>
<dd>

<p>This is item one.</p>

</dd>
</dl>


</body>

</html>


