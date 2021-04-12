#!/usr/bin/perl -w

# ALIGN2HTML
# Author: Jerome Ajot
#
# This software was developed at the National Institute of Standards and Technology by
# employees of the Federal Government in the course of their official duties. Pursuant
# to title 17 Section 105 of the United States Code this software is not subject to
# copyright protection and is in the public domain. ALIGN2HTML is an experimental system.
# NIST assumes no responsibility whatsoever for its use by other parties, and makes no
# guarantees, expressed or implied, about its quality, reliability, or any other
# characteristic. We would appreciate acknowledgement if the software is used.
#
# THIS SOFTWARE IS PROVIDED "AS IS."  With regard to this software, NIST MAKES NO EXPRESS
# OR IMPLIED WARRANTY AS TO ANY MATTER WHATSOEVER, INCLUDING MERCHANTABILITY,
# OR FITNESS FOR A PARTICULAR PURPOSE.

### Revision History
# Version 0.5		SDR Flatten PATHTOOLS option to a single directory, mimicking
#               install structure. Alternatively, specify separate directories
#               for each of RTTMSMOOTH and RTTMSORT

use strict;
use Getopt::Long;
use Data::Dumper;
use File::Basename;
use Config;

Getopt::Long::Configure(qw( auto_abbrev no_ignore_case ));

my $VERSION = "0.5";

my $RTTMFile = "";
my $CTMFile = "";
my $PATHTOOLS;
my $RTTMSMOOTH;
my $RTTMSORT;
my $PERL = $Config{perlpath};

sub usage
{
	print "perl $0 [OPTION] -r rttmfile -c ctmfile > outputfile\n";
	print "\n";
	print "Required file arguments:\n";
	print "  -r, --rttmfile           Path to the RTTM file.\n";
	print "  -c, --ctmfile            Path to the CTM file.\n";
	print "Path arguments:\n";
	print "  -p, --pathtools          Path to the directory containing the \n";
	print "                           scripts RTTMSMOOTH.pl and RTTMSORT.pl.\n";
	print "  --smoothfile             Path to the script RTTMSMOOTH.pl.\n";
	print "  --sortfile               Path to the script RTTMSORT.pl.\n";
	print "\n";
	print "pathtools is mutally exclusive with the options smoothfile and\n";
	print "sortfile. If either smoothfile or sortfile is specified, both must\n";
	print "be specified. The default behaviour is to set pathtools to the\n";
	print "same directory as this script\n";
	print "\n";
}

sub loadRTTMFile
{
	my ($rttmFile, $rttmhash) = @_;

	open(RTTM, $rttmFile) or die "Unable to open for read RTTM file '$rttmFile'";

	while (<RTTM>)
	{
		chomp;

		# Remove comments which start with ;;
		s/;;.*$//;

		# Remove unwanted space at the begining and at the end of the line
		s/^\s*//;
		s/\s*$//;

		# if the line is empty then ignore
		next if ($_ =~ /^$/);

		my ($type, $file, $chnl, $tbeg, $tdur, $ortho, $stype, $spkrname, $conf) = split(/\s+/,$_,9);

		if(uc($type) eq "SPKR-INFO")
		{
		    $rttmhash->{SPKR}{$file}{$chnl}{$spkrname} = 1;
		}

		if(uc($type) eq "SPEAKER")
		{
			push( @{ $rttmhash->{DATA}{$file}{$chnl}{$tbeg} }, ($tbeg, $tdur, $ortho, $stype, $spkrname, $conf));
		}
	}

	close RTTM;
}

sub loadCTMFile
{
	my ($ctmFile, $ctmhash) = @_;

	open(CTM, $ctmFile) or die "Unable to open for read CTM file '$ctmFile'";

	while (<CTM>)
	{
		chomp;

		# Remove comments which start with ;;
		s/;;.*$//;

		# Remove unwanted space at the begining and at the end of the line
		s/^\s*//;
		s/\s*$//;

		# if the line is empty then ignore
		next if ($_ =~ /^$/);

		my ($file, $chnl, $tbeg, $tdur, $ortho, $conf, $stype, $spkrname) = split(/\s+/,$_,8);

		if($stype eq "lex")
		{
			my $mid = sprintf("%.4f", $tbeg+$tdur/2);

		    push( @{ $ctmhash->{$file}{$chnl}{$tbeg} }, ($tbeg, $tdur, $ortho, $stype, $conf, $mid));
		}
	}

	close CTM;
}

sub findSpeaker
{
	my ($rttmhash, $file, $chnl, $mid) = @_;
	my @listspkr;

	foreach my $tbeg(sort keys %{ $rttmhash->{DATA}{$file}{$chnl} })
	{
		my $bt = @{ $rttmhash->{DATA}{$file}{$chnl}{$tbeg} }[0];
		my $dur = @{ $rttmhash->{DATA}{$file}{$chnl}{$tbeg} }[1];
		my $spkrname = @{ $rttmhash->{DATA}{$file}{$chnl}{$tbeg} }[4];

		if( ($bt <= $mid) && ($mid <= sprintf("%.3f", $bt+$dur) ) )
		{
			push( @listspkr, [ ($spkrname, $tbeg) ] );
		}
	}

	if(scalar(@listspkr) == 0)
	{
		return undef;
	}
	else
	{
		return(\@{ $listspkr[int(rand(scalar(@listspkr)))] });
	}
}

sub MergedData
{
	my ($rttmhash, $ctmhash, $file, $chnl) = @_;

	if (exists($ctmhash->{$file}{$chnl}) )
	{
		foreach my $tbeg(sort {$a <=> $b} keys %{ $ctmhash->{$file}{$chnl} })
		{
			my $mid = $ctmhash->{$file}{$chnl}{$tbeg}[5];
		    my $spkrtbeg = findSpeaker($rttmhash, $file, $chnl, $mid);

		    if($spkrtbeg)
		    {
		    	my $ctmbeg = $ctmhash->{$file}{$chnl}{$tbeg}[0];
		    	my $ctmdur = $ctmhash->{$file}{$chnl}{$tbeg}[1];
		    	my $ctmortho = $ctmhash->{$file}{$chnl}{$tbeg}[2];
		    	my $ctmstype = $ctmhash->{$file}{$chnl}{$tbeg}[3];
		    	my $ctmconf = $ctmhash->{$file}{$chnl}{$tbeg}[4];
		    	my $ctmspkr = $spkrtbeg->[0];

		    	print OUTPUT "SPEAKER $file $chnl $ctmbeg $ctmdur <NA> <NA> $ctmspkr <NA>\n";
		    	print OUTPUT "LEXEME $file $chnl $ctmbeg $ctmdur $ctmortho $ctmstype $ctmspkr $ctmconf\n";
		    }
		}
	}
}

GetOptions
(
    'rttmfile=s' => \$RTTMFile,
    'ctmfile=s'  => \$CTMFile,
    'pathtools=s'  => \$PATHTOOLS,
		'smoothfile=s'  => \$RTTMSMOOTH,
		'sortfile=s'  => \$RTTMSORT,
    'version'    => sub { print "mergectm2rttm version: $VERSION\n"; exit },
    'help'       => sub { usage (); exit },
);

die "ERROR: An RTTM file must be set." if($RTTMFile eq "");
die "ERROR: An CTM file must be set." if($CTMFile eq "");

if (defined($RTTMSMOOTH) || defined($RTTMSORT)) {
	die "If --smoothfile or --sortfile is set, both must be set"
		unless (defined($RTTMSMOOTH) && defined($RTTMSORT));
	die "If --smoothfile or --sortfile is set, --pathtools must not be"
		if (defined($PATHTOOLS));
} else {
	unless (defined($PATHTOOLS)) {
		$PATHTOOLS = basename(__FILE__);
	}
	$PATHTOOLS =~ tr:\\:/:;
	$RTTMSMOOTH = $PATHTOOLS ."/rttmSmooth.pl";
	$RTTMSORT = $PATHTOOLS ."/rttmSort.pl";
}

die "ERROR: '$RTTMSMOOTH' cannot be found, please specify the tools path with -p\n" if(! -e $RTTMSMOOTH);
die "ERROR: '$RTTMSORT' cannot be found, please specify the tools path with -p\n" if(! -e $RTTMSORT);

my %RTTM;
my %CTM;

loadRTTMFile($RTTMFile, \%RTTM);
loadCTMFile($CTMFile, \%CTM);

open(OUTPUT, "| $PERL $RTTMSMOOTH | $PERL $RTTMSORT");

print ";; type file chnl tbeg tdur ortho stype name conf\n";

foreach my $file(sort keys %{ $RTTM{SPKR} })
{
	foreach my $chnl(sort keys %{ $RTTM{SPKR}{$file} })
	{
		foreach my $spkrname(sort keys %{ $RTTM{SPKR}{$file}{$chnl} })
		{
			print OUTPUT "SPKR-INFO $file $chnl <NA> <NA> <NA> unknown $spkrname <NA>\n";
		}

		MergedData(\%RTTM, \%CTM, $file, $chnl);
	}
}

close(OUTPUT);

