# -*- perl -*-
use strict;
use Data::Dump;
use Carp;
use Cwd;
use File::Copy;
use File::Spec;
use Pod::Html ();
use Pod::Html::Auxiliary qw(
    unixify
);
use lib qw( t/lib );
use Testing qw(
    initialize_testing_directory
    get_files_and_dirs
    get_basic_args
    get_expect_and_result
    identify_diff
    print_differences
);
use Test::More qw(no_plan); # tests =>  1;

my $start_dir = Pod::Html::unixify(Cwd::cwd());
my $podfile = 'feature2';
my $testname = 'misc pod-html features2';
my $templated_expected; { local $/; $templated_expected = <DATA>; }

{
    my $tdir = initialize_testing_directory($start_dir, $podfile);
    my $f = get_files_and_dirs($podfile);
Data::Dump::pp($f);

    my $constructor_args = get_basic_args($tdir, $f);
    my $extra_args = {
      backlink => 1,
      header => 1,
      podpath => '.',
      podroot => $tdir,
      norecurse => 1,
      verbose => 1,
      quiet => 1,
    };
    map { $constructor_args->{$_} = $extra_args->{$_} } keys %{$extra_args};
Data::Dump::pp($constructor_args);

    my $warn;
    $SIG{__WARN__} = sub { $warn .= $_[0] };
    ok(Pod::Html::run($constructor_args), "Pod::Html methods completed");
    like($warn,
        qr(
    	\Acaching\ directories\ for\ later\ use\n
    	Converting\ input\ file\ \S+[/\\\]]feature2\.pod\n\z	
        )x,
        "misc pod-html --verbose warnings");

    my ($expect, $result) = get_expect_and_result($f, $templated_expected);
    my ($diff, $diffopt) = identify_diff();
    if ($diff) {
        ok($expect eq $result, $testname)
            or print_differences(
                $podfile, $expect, $diff, $diffopt, $f->{outfile});
    }
    else {
        # This is fairly evil, but lets us get detailed failure modes
        # anywhere that we've failed to identify a diff program.
        is($expect, $result, $testname);
    }

    chdir $start_dir or croak "Unable to change back to starting place";
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

<body id="_podtop_">
<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" style="background-color: #cccccc; color: #000" valign="middle">
<big><strong><span class="_podblock_">&nbsp;</span></strong></big>
</td></tr>
</table>



<ul id="index">
  <li><a href="#Head-1">Head 1</a></li>
  <li><a href="#Another-Head-1">Another Head 1</a></li>
</ul>

<a href="#_podtop_"><h1 id="Head-1">Head 1</h1></a>

<p>A paragraph</p>



some html

<p>Another paragraph</p>

<a href="#_podtop_"><h1 id="Another-Head-1">Another Head 1</h1></a>

<p>some text and a link <a>crossref</a></p>

<table border="0" width="100%" cellspacing="0" cellpadding="3">
<tr><td class="_podblock_" style="background-color: #cccccc; color: #000" valign="middle">
<big><strong><span class="_podblock_">&nbsp;</span></strong></big>
</td></tr>
</table>

</body>

</html>


