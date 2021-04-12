#! /usr/bin/env perl
use warnings;
use strict;

use Getopt::Long;
use File::Temp;
use File::Spec;
use File::Basename;
use File::Compare qw(compare_text);

my $usage = "Usage: $0 [<OPTIONS>] <rfilter_path>

OPTIONS
  -o <dir>:  Store results in desired folder instead of a temporary one.
  -i <dir>:  Directory where expected value files exist
";

my $outdir;
my $indir = ".";

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
  }
) or die "$usage";

die $usage unless (@ARGV == 1);
my $rfilter1_path = File::Spec->canonpath(shift);
die "Error: $rfilter1_path does not exist or is not an executable"
  unless (-x $rfilter1_path);

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub run_test {
  my ($name, $cmd, $exp) = @_;
  print "Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  print $act_fh `$cmd`;
  # die "$name error: $!" if $?;
  close($act_fh);
  if (compare_text($exp, $act)) {
    print "$name failed\n";
    system "diff", $exp, $act;
    die;
  } else {
    print "$name passed\n";
  }
}

run_test("arb2004", "$rfilter1_path $indir/test.arb2004.glm < $indir/test.arb2004.txt", "test.arb2004.txt.rfilter1");
run_test("man2004", "$rfilter1_path $indir/test.man2004.glm < $indir/test.man2004.txt", "test.man2004.txt.rfilter1");
# ./rfilter1 ../test_suite/test.arb2004.glm < ../test_suite/test.arb2004.txt | diff - ../test_suite/test.arb2004.txt.rfilter1
# ./rfilter1 ../test_suite/test.man2004.glm < ../test_suite/test.man2004.txt | diff - ../test_suite/test.man2004.txt.rfilter1