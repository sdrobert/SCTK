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
  -h <path>: Path to hubscr.pl
  -w:        Write expected values instead of comparing
";

my $outdir;
my $indir = ".";
my $perl = $Config{perlpath};
my $hubscr = "hubscr.pl";
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
  "h=s" => sub{
    my ($opt_name, $opt_value) = @_;
    die "Error -$opt_name expected existing file, got $opt_value"
      unless (-f $opt_value);
    ($hubscr = $opt_value) =~ s/\\/\//g;
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

my $prefix = "$perl chfilt.pl -h $hubscr";

run_test("testmss", "$prefix -m -l english $indir/testmss.in -- -", "testmss.stm");
run_test("testmss_numbers", "$prefix -C numbers -m -l english $indir/testmss.in -- -", "testmss.numbers.stm");
run_test("test_optdel", "$prefix -l english -i -b 0 -e 999999 $indir/test.txt -- -", "test.txt.-optdel.stm");
run_test("test", "$prefix -d -l english -i -b 0 -e 999999 -k $indir/test.txt -- -", "test.txt.stm");
run_test("test_contexp", "$prefix -c -l english -i -b 0 -e 999999 -k $indir/test.txt -- -", "test.txt.-contexp.stm");
run_test("arb2004", "$prefix -c -l arabic -i -b 0 -e 999999 -d -k $indir/test.arb2004.txt -- -", "test.arb2004.txt.stm");
run_test("man2004", "$prefix -c -l mandarin -i -b 0 -e 999999 -d -k $indir/test.man2004.txt -- -", "test.man2004.txt.stm");
# "$1 $2 -m -l english testmss.in -- - | diff - testmss.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -C numbers -m -l english testmss.in -- - | diff - testmss.numbers.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -l english -i -b 0 -e 999999 test.txt -- - | diff - test.txt.-optdel.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -d -l english -i -b 0 -e 999999 -k test.txt -- - | diff - test.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -c -l english -i -b 0 -e 999999 -k test.txt -- - | diff - test.txt.-contexp.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -c -l arabic -i -b 0 -e 999999 -d -k test.arb2004.txt -- - | diff - test.arb2004.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl
# "$1 $2 -c -l mandarin -i -b 0 -e 999999 -d -k test.man2004.txt -- - | diff - test.man2004.txt.stm" -- ${PERL_EXECUTABLE} ${CMAKE_CURRENT_BINARY_DIR}/chfilt.pl