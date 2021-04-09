#!/usr/bin/perl -w

use Config;
use strict;
use File::Compare qw(compare_text);
use File::Temp;
use Getopt::Long;

my $rfilter;

GetOptions(
      "r=s" => sub {
            my ($opt_name, $opt_value) = @_;
            die "Error: -$opt_name option expects a path to an executable, got $opt_value"
                  unless (-x $opt_value);
            $rfilter = $opt_value;
      }
);


my $operation = (defined($ARGV[0]) ? $ARGV[0] : "test");
my $perl = $Config{perlpath};

####################
sub error_exit { exit(1); }
sub error_quit { print('[ERROR] ', join(' ', @_), "\n"); &error_exit(); }
sub ok_exit { exit(0); }
sub ok_quit { print(join(' ', @_), "\n"); &ok_exit(); }
####################


sub runIt{
    my $tmp = new File::Temp();
    close($tmp);
    my ($op, $testId, $options, $glm, $utm, $input, $output, $expRet) = @_;
    if (defined($rfilter)) {
      $options .= " -r $rfilter";
    }
    print "   Running Test $testId\n";
    my $com = "$perl csrfilt.pl $options $glm $utm < $input > $tmp";
    my $ret = system "$com";
    if ($expRet eq "pass"){
	&error_quit("Execution failed for command expected to pass '$com'") if ($ret != 0);
    } else {
	&error_quit("Execution failed for command expected to fail '$com'") if ($ret == 0);
    }

    if ($op eq "setTests") {
	system "mv $tmp $output";
    } else {
	print "      Comparing output\n";
      unless (compare_text($output, $tmp->filename) == 0) {
            # here's where we try to use diff
            # (we don't do so before b/c windows)
            my $diffCom = "diff $output $tmp";
            open (DIFF, "$diffCom |") || &error_quit("Diff command '$diffCom' Failed");
            my @diff = <DIFF>;
            close DIFF;
            &error_quit("Test $testId has failed.\n    Command: $com\n    Diff output is : $diffCom\n@diff\n") if (@diff > 0);
      }
	print "      Successful Test.  Removing $tmp\n";
    }
}

runIt($operation, "stm", "-i stm -dh",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.stm.in",  "../test_suite/test.stm.-dh.out", "pass");
runIt($operation, "stm", "-i stm",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.stm.in",  "../test_suite/test.stm.out", "pass");
runIt($operation, "rttm", "-i rttm -dh",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.rttm.in",  "../test_suite/test.rttm.-dh.out", "pass");
runIt($operation, "rttm", "-i rttm",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/sastt-case2.sys.rttm",  "../test_suite/sastt-case2.sys.rttm.filt", "pass");
runIt($operation, "rttm", "-i rttm",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.rttm.in",  "../test_suite/test.rttm.out", "pass");
runIt($operation, "trn", "-i trn -dh",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.trn.in",  "../test_suite/test.trn.-dh.out", "pass");
runIt($operation, "trn", "-i trn",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.trn.in",  "../test_suite/test.trn.out", "pass");
#	$perl csrfilt.pl -dh $(T)/example.glm $(T)/example.utm < $(T)/test.in > $(T)/test.out
#	$perl csrfilt.pl -i ctm -dh $(T)/example.glm $(T)/example.utm < $(T)/test_ctm.in > $(T)/test_ctm.out
runIt($operation, "text", "-dh",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test.in",  "../test_suite/test.out", "pass");
runIt($operation, "ctm", "-i ctm",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.in",  "../test_suite/test_ctm.out", "pass");
runIt($operation, "ctm", "-i ctm -dh",
      "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.in",  "../test_suite/test_ctm.-dh.out", "pass");
runIt($operation, "ctm", "-i ctm -dh",
       "../test_suite/example.glm",  "../test_suite/example.utm",  "../test_suite/test_ctm.errors.in",  "../test_suite/test_ctm.errors.out", "fail");


&ok_quit();

#	rm -rf testBase
#	mkdir -p testBase
#	cp ../test_suite/lvc_hyp.ctm ../test_suite/lvc_refe.stm testBase
#	cp ../test_suite/lvc_hyp.ctm testBase/lvc_hyp2.ctm
#	(cd testBase; ../hubscr.pl -p ../../csrfilt:../../def_art:../../acomp:../../hamzaNorm -l english -g ../../test_suite/example.glm -h hub5 -r lvc_refe.stm lvc_hyp.ctm lvc_hyp2.ctm)
