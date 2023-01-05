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
  -r <path>: Path to rfilter1 executable
  -w:        Write expected values instead of comparing
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};
my $rfilter1 = "rfilter";
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
  "r=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing exectuable, got $opt_value"
      unless (-x $opt_value);
    $rfilter1 = File::Spec->rel2abs(File::Spec->canonpath($opt_value));
  },
  "w" => \$set_test
) or die "$usage";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

sub run_test {
  my ($name, $cmd, $exp, $pass) = @_;
  my $pass_ = $pass eq "pass";
  print "   Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = $set_test ? $exp : File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  my ($old_stderr, $error_buff);
  unless($pass_) {
    open(my $old_stderr, ">&STDERR");
    close(STDERR);
    open(STDERR, ">", \$error_buff);
  }
  print $act_fh `$cmd`;
  my $ret = $? == 0;
  close($act_fh);
  unless($pass_) {
    close(STDERR);
    open(STDERR, ">&$old_stderr");
  }
  # die "$name error: $!" if $?;
  unless ($set_test) {
    die "   $name failed: expected command to $pass" unless ($ret == $pass_);
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


my $prefix = "$perl csrfilt.pl -r $rfilter1";

run_test("stm-dh", "$prefix -i stm -dh $indir/example.glm $indir/example.utm < $indir/test.stm.in", "test.stm.-dh.out", "pass");
run_test("stm", "$prefix -i stm $indir/example.glm $indir/example.utm < $indir/test.stm.in", "test.stm.out", "pass");
run_test("rttm-dh", "$prefix -i rttm -dh $indir/example.glm $indir/example.utm < $indir/test.rttm.in", "test.rttm.-dh.out", "pass");
run_test("rttm", "$prefix -i rttm $indir/example.glm $indir/example.utm < $indir/test.rttm.in", "test.rttm.out", "pass");
run_test("sastt-case2", "$prefix -i rttm $indir/example.glm $indir/example.utm < $indir/sastt-case2.sys.rttm", "sastt-case2.sys.rttm.filt", "pass");
run_test("trn-dh", "$prefix -i trn -dh $indir/example.glm $indir/example.utm < $indir/test.trn.in", "test.trn.-dh.out", "pass");
run_test("trn", "$prefix -i trn $indir/example.glm $indir/example.utm < $indir/test.trn.in", "test.trn.out", "pass");
run_test("text", "$prefix -dh $indir/example.glm $indir/example.utm < $indir/test.in", "test.out", "pass");
run_test("ctm-dh", "$prefix -i ctm -dh $indir/example.glm $indir/example.utm < $indir/test_ctm.in", "test_ctm.-dh.out", "pass");
run_test("ctm", "$prefix -i ctm $indir/example.glm $indir/example.utm < $indir/test_ctm.in", "test_ctm.out", "pass");
run_test("ctm-errors", "$prefix -i ctm -dh $indir/example.glm $indir/example.utm < $indir/test_ctm.errors.in", "test_ctm.errors.out", "fail");

# runIt($operation, "stm", "-i stm -dh",
      # "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.stm.in",  "../test_suite/test.stm.-dh.out", "pass");
# runIt($operation, "stm", "-i stm",
      # "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.stm.in",  "../test_suite/test.stm.out", "pass");
# runIt($operation, "rttm", "-i rttm -dh",
      # "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.rttm.in",  "../test_suite/test.rttm.-dh.out", "pass");
# runIt($operation, "rttm", "-i rttm",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/sastt-case2.sys.rttm",  "../test_suite/sastt-case2.sys.rttm.filt", "pass");
# runIt($operation, "rttm", "-i rttm",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.rttm.in",  "../test_suite/test.rttm.out", "pass");
# runIt($operation, "trn", "-i trn -dh",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.trn.in",  "../test_suite/test.trn.-dh.out", "pass");
# runIt($operation, "trn", "-i trn",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.trn.in",  "../test_suite/test.trn.out", "pass");
# #	$perl csrfilt.pl -dh $(T)/example.glm $(T)/example.utm < $(T)/test.in > $(T)/test.out
# #	$perl csrfilt.pl -i ctm -dh $(T)/example.glm $(T)/example.utm < $(T)/test_ctm.in > $(T)/test_ctm.out
# runIt($operation, "text", "-dh",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.in",  "../test_suite/test.out", "pass");
# runIt($operation, "ctm", "-i ctm",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.in",  "../test_suite/test_ctm.out", "pass");
# runIt($operation, "ctm", "-i ctm -dh",
#       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.in",  "../test_suite/test_ctm.-dh.out", "pass");
# runIt($operation, "ctm", "-i ctm -dh",
#        "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.errors.in",  "../test_suite/test_ctm.errors.out", "fail");
