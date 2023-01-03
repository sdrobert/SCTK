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
  "s" => \$set_test
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
  unless ($set_test) {
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

my $prefix = "$perl tanweenFilt.pl";

run_test("arb2004", "$prefix -- $indir/test.arb2004.txt -", "test.arb2004.tanweenFilt.txt");
run_test("arb2004_a", "$prefix -a -- $indir/test.arb2004.txt -", "test.arb2004.tanweenFilt-a.txt");
run_test("arb2004_stm_1", "$perl -pe \"s/<O>//\" < $indir/test.arb2004.txt.stm | $prefix -i stm -- - -", "test.arb2004.txt.stm.tanween");
run_test("arb2004_stm_2", "$prefix -i stm -- $indir/test.arb2004.txt.stm - | perl -pe \"s/<O>//\"", "test.arb2004.txt.stm.tanween");
run_test("arb2004_stm_2_a", "$prefix -a -i stm -- $indir/test.arb2004.txt.stm - | perl -pe \"s/<O>//\"", "test.arb2004.txt.stm.tanween-a");
run_test("arb2004_ctm", "$prefix -i ctm -- $indir/test.arb2004.txt.ctm - | perl -pe \"s/<O>//\"", "test.arb2004.txt.ctm.tanween");
run_test("arb2004_ctm_a", "$prefix -a -i ctm -- $indir/test.arb2004.txt.ctm - | perl -pe \"s/<O>//\"", "test.arb2004.txt.ctm.tanween-a");
# cat $(T)/test.arb2004.txt | ./tanweenFilt.pl -- - - | diff - $(T)/test.arb2004.tanweenFilt.txt
# cat $(T)/test.arb2004.txt | ./tanweenFilt.pl -a -- - - | diff - $(T)/test.arb2004.tanweenFilt-a.txt
# cat $(T)/test.arb2004.txt.stm | sed 's/<O>//' | ./tanweenFilt.pl -i stm -- - - | diff - $(T)/test.arb2004.txt.stm.tanween
# cat $(T)/test.arb2004.txt.stm | ./tanweenFilt.pl -i stm -- - - | sed 's/<O>//' | diff - $(T)/test.arb2004.txt.stm.tanween
# cat $(T)/test.arb2004.txt.stm | ./tanweenFilt.pl -a -i stm -- - - | sed 's/<O>//' | diff - $(T)/test.arb2004.txt.stm.tanween-a
# cat $(T)/test.arb2004.txt.ctm | ./tanweenFilt.pl -i ctm -- - - | sed 's/<O>//' | diff - $(T)/test.arb2004.txt.ctm.tanween
# cat $(T)/test.arb2004.txt.ctm | ./tanweenFilt.pl -a -i ctm -- - - | sed 's/<O>//' | diff - $(T)/test.arb2004.txt.ctm.tanween-a