#!/usr/bin/env perl
#
# $Id$

use warnings;
use strict;

use Config;
use Getopt::Long;
use File::Temp;
use File::Spec;
use File::Basename;
use File::Compare qw(compare_text);

my $usage = "Usage: $0 [<OPTIONS>]

OPTIONS
  -o <dir>:  Store results in desired folder instead of a temporary one.
  -i <dir>:  Directory where expected value files exist
  -w:        Write expected values instead of comparing
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};
my $set_test = 0;

GetOptions(
  "o=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected directory name, got $opt_value"
      unless (-d $opt_value || mkdir($opt_value));
    $outdir = File::Spec->canonpath($opt_value);
  },
  "i=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing directory, got $opt_value"
      unless (-d $opt_value);
    $indir = File::Spec->canonpath($opt_value);
  },
  "w" => \$set_test
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub run_test {
  my ($name, $cmd, $exp) = @_;
  print "   Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = $set_test ? $exp : File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  print $act_fh `$cmd`;
  # die "$name error: $!" if $?;
  close($act_fh);
  unless($set_test) {
    if (compare_text($exp, $act)) {
      print "   $name failed\n";
      system "diff", $exp, $act;
      die;
    } else {
      print "   $name passed\n";
    }
  } else {
    print "   Wrote $name to $act\n";
  }
}

my $prefix = "$perl slatreport.pl";

run_test("slat_rttm_out", "$prefix -i $indir/slat.rttm -o $outdir/slat.rttm.out.test -t LEXEME -s lex | $perl -ne \"print unless /PNG:/\"", "slat.rttm.out");

# system("./slatreport.pl -i ../test_suite/slat.rttm -o ../test_suite/slat.rttm.out.test -t LEXEME -s lex | grep -v 'PNG:' > ../test_suite/slat.rttm.out.test");

# unlink("../test_suite/slat.rttm.out.test.SPLbDistribution.10.png");
# unlink("../test_suite/slat.rttm.out.test.SPLmDistribution.10.png");
# unlink("../test_suite/slat.rttm.out.test.SPLeDistribution.10.png");

# my $diff = `diff ../test_suite/slat.rttm.out ../test_suite/slat.rttm.out.test`;

# if($diff ne "")
# {
# 	print "Slat Test Failed.\n";
# 	print "$diff\n";
# 	exit(1);
# }
# else
# {
# 	print "Slat Test OK.\n";
# 	unlink("../test_suite/slat.rttm.out.test");
# 	exit(0);
# }
