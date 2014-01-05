# -*- perl -*-
use strict;
use Data::Dump;
use Carp;
use Cwd;
use File::Copy;
use File::Spec;
use File::Spec::Unix;
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
my $podfile = 'poderr';
my $testname = 'pod error section';
my $templated_expected; { local $/; $templated_expected = <DATA>; }

{
    my $tdir = initialize_testing_directory($start_dir, $podfile);
    my $f = get_files_and_dirs($podfile);
Data::Dump::pp($f);

    my $constructor_args = get_basic_args($tdir, $f);
    my $extra_args = { poderrors => 1 };
    map { $constructor_args->{$_} = $extra_args->{$_} } keys %{$extra_args};
Data::Dump::pp($constructor_args);

    ok(Pod::Html::run($constructor_args), "Pod::Html methods completed");

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

<body>



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#POD-ERRORS">POD ERRORS</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>Test POD ERROR section</p>

<ul>

<p>This text is not allowed</p>

<p>*</p>

<p>The wiz item.</p>

<p>*</p>

<p>The waz item.</p>

</ul>

<h1 id="POD-ERRORS">POD ERRORS</h1>

<p>Hey! <b>The above document had some coding errors, which are explained below:</b></p>

<dl>

<dt id="Around-line-5">Around line 5:</dt>
<dd>

<p>You can&#39;t have =items (as at line 9) unless the first thing after the =over is an =item</p>

</dd>
</dl>


</body>

</html>


