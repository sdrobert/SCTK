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

my $prefix = "$perl hamzaNorm.pl";

# run_test("testmss", "$prefix -m -l english $indir/testmss.in -- -", "testmss.stm");
run_test("arb2004", "$prefix -- $indir/test.arb2004.txt -", "test.arb2004.hamzaNorm.txt");
run_test("arb2004_stm_1", "$perl -pe \"s/<O>//\" < $indir/test.arb2004.txt.stm | $prefix -i stm -- - -", "test.arb2004.txt.stm.hamza");
run_test("arb2004_stm_2", "$prefix -i stm -- $indir/test.arb2004.txt.stm - | $perl -pe \"s/<O>//\"", "test.arb2004.txt.stm.hamza");
run_test("arb2004_ctm", "$prefix -i ctm -- $indir/test.arb2004.txt.ctm - | $perl -pe \"s/<O>//\"", "test.arb2004.txt.ctm.hamza");
