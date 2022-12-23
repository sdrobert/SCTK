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
  -e <path>: Path to utf-1.2.dtd. If unset, assumed to be at directory above
             expected value files
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};
my $dtd;

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
  "e=s" => sub {
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing file, got $opt_value"
      unless (-f $opt_value);
    $dtd = File::Spec->canonpath($opt_value);
  }
) or die "${usage}Error: could not parse options";

unless (defined($outdir)) {
  $outdir = File::Temp->newdir();
}

if (defined($dtd)) {
  $dtd = "-e $dtd";
}

sub run_test {
  my ($name, $cmd, $exp) = @_;
  print "Beginning $name\n";
  $exp = File::Spec->catfile($indir, $exp);
  my $act = File::Spec->catfile($outdir, basename($exp).".act");
  open(my $act_fh, '>', $act);
  print $act_fh `$cmd`;
  die("Command failed!") if ($?);
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

my $prefix = "$perl utf_filt.pl $dtd -f stm -o - -d";

run_test("test_man", "$prefix -i $indir/test.man.utf", "test.man.stm");
run_test("test_eng", "$prefix -i $indir/test.eng.utf", "test.eng.stm");
run_test("test_eng_notrans_stm", "$prefix -t -n -i $indir/test.eng.utf", "test.eng.notrans.stm");
# perl utf_filt.pl -s $(NSGMLS) -e utf-1.2.dtd -f stm -i ../test_suite/test.man.utf -o - -d | diff - ../test_suite/test.man.stm;
# perl utf_filt.pl -s $(NSGMLS) -e utf-1.2.dtd -f stm -i ../test_suite/test.eng.utf -o - -d | diff - ../test_suite/test.eng.stm;
# perl utf_filt.pl -s $(NSGMLS) -t -n -e utf-1.2.dtd -f stm -i ../test_suite/test.eng.utf -o - -d | diff - ../test_suite/test.eng.notrans.stm;