#!/usr/bin/perl -w                                         # -*- perl -*-

BEGIN {
    require "t/pod2html-lib.pl";
}

use strict;
use Cwd;
use File::Spec::Functions;
use Test::More tests => 1;

my $cwd = catdir cwd(); # catdir converts path separators to that of the OS
                        # running the test
                        # XXX but why don't the other tests complain about this?

convert_n_test("htmldir5", "test --htmldir and --htmlroot 5", 
 "--podpath=t:test.lib",
 "--podroot=$cwd",
 "--htmldir=$cwd",
 "--htmlroot=/",
);

__DATA__
<?xml version="1.0" ?>
<!DOCTYPE html PUBLIC "-//W3C//DTD XHTML 1.0 Strict//EN" "http://www.w3.org/TR/xhtml1/DTD/xhtml1-strict.dtd">
<html xmlns="http://www.w3.org/1999/xhtml">
<head>
<title></title>
<meta http-equiv="content-type" content="text/html; charset=utf-8" />
<link rev="made" href="mailto:[PERLADMIN]" />
</head>

<body style="background-color: white">



<ul id="index">
  <li><a href="#NAME">NAME</a></li>
  <li><a href="#LINKS">LINKS</a></li>
</ul>

<h1 id="NAME">NAME</h1>

<p>htmldir - Test --htmldir feature</p>

<h1 id="LINKS">LINKS</h1>

<p>Normal text, a <a>link</a> to nowhere,</p>

<p>a link to <a href="../test.lib/perlvar.html">perlvar</a>,</p>

<p><a href="./htmlescp.html">htmlescp</a>,</p>

<p><a href="./feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>,</p>

<p>and another <a href="./feature.html#Another-Head-1">&quot;Another Head 1&quot; in feature</a>.</p>


</body>

</html>


