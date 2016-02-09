#!/usr/bin/perl -w

# tokenize_coptic.pl Version 4.0.4

# this assumes a UTF-8 file with untokenized 'word forms' separated by spaces or underscores
# three files must be present in the tokenizer directory or specified via options: copt_lex.tab, segmentation_table.tab and morph_table.tab
# 
# usage:
# tokenize_coptic.pl [options] file
# See help (-h) for options

use Getopt::Std;
use utf8;

binmode(STDOUT, ":utf8");
binmode(STDIN, ":utf8");

my $usage;
{
$usage = <<"_USAGE_";
This script splits up Coptic bound groups and assumes a UTF-8 file with untokenized groups of characters separated by spaces or underscores
Three files must be present in the tokenizer directory or specified via options: copt_lex.tab, segmentation_table.tab and morph_table.tab

Usage:  tokenize_coptic.pl [options] <FILE>

Options and argument:

-h              print this [h]elp message and quit
-d              specify [d]ictionary file, default is copt_lex.tab in script directory
-s              specify [s]egmentation file, default is segmentation_table.tab in script directory
-m              specify [m]orph table file, default is morph_table.tab in script directory
-p              output [p]ipe separated word forms instead of tokens in separate lines wrapped by <norm> tags
-l               add [l]ine tags marking original linebreaks in input file
-n              [n]o output of word forms in <norm_group> elements before the set of tokens extracted from each group

<FILE>    A text file encoded in UTF-8 without BOM, possibly containing markup. Bound groups are separated by spaces or underscores.


Examples:

Tokenize a Coptic plain text file in UTF-8 encoding (without BOM):
  tokenize_coptic.pl in_Coptic_utf8.txt > out_Coptic_tokenized.txt

Copyright 2013-2015, Amir Zeldes

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
_USAGE_
}

### OPTIONS BEGIN ###
%opts = ();
getopts('hlm:npd:s:',\%opts) or die $usage;

#help
if ($opts{h} || (@ARGV == 0)) {
    print $usage;
    exit;
}
if ($opts{p})   {$pipes = 1;} else {$pipes = 0;}
if ($opts{l})   {$nolines = 0;} else {$nolines = 1;}
if ($opts{n})   {$noword = 1;} else {$noword = 0;}
if (!($lexicon = $opts{d})) 
    {$lexicon = "copt_lex.tab";}
if (!($segfile = $opts{s})) 
    {$segfile  = "segmentation_table.tab";}
if (!($morphfile = $opts{m})) 
    {$morphfile = "morph_table.tab";}

### OPTIONS END ###

### BUILD LEXICON ###
#build function word lists
$pprep = "ⲁϫⲛⲧ|ⲉϩⲣⲁ|ⲉϩⲣⲁⲓⲉϫⲱ|ⲉϫⲛⲧⲉ|ⲉϫⲱ|ⲉⲣⲁⲧ|ⲉⲣⲁⲧⲟⲩ|ⲉⲣⲟ|ⲉⲣⲱ|ⲉⲧⲃⲏⲏⲧ|ⲉⲧⲟⲟⲧ|ϩⲁⲉⲓⲁⲧ|ϩⲁϩⲧⲏ|ϩⲁⲣⲁⲧ|ϩⲁⲣⲓϩⲁⲣⲟ|ϩⲁⲣⲟ|ϩⲁⲣⲱ|ϩⲁⲧⲟⲟⲧ|ϩⲓϫⲱ|ϩⲓⲣⲱ|ϩⲓⲧⲉ|ϩⲓⲧⲟⲟⲧ|ϩⲓⲧⲟⲩⲱ|ϩⲓⲱ|ϩⲓⲱⲱ|ⲕⲁⲧⲁⲣⲟ|ⲕⲁⲧⲁⲣⲱ|ⲙⲙⲟ|ⲙⲙⲱ|ⲙⲛⲛⲥⲱ|ⲙⲡⲁⲙⲧⲟⲉⲃⲟⲗ|ⲛⲏⲧⲛ|ⲛⲁ|ⲛϩⲏⲧ|ⲛⲙⲙⲏ|ⲛⲙⲙⲁ|ⲛⲥⲁⲃⲗⲗⲁ|ⲛⲥⲱ|ⲛⲧⲟⲟⲧ|ⲟⲩⲃⲏ|ϣⲁⲣⲟ|ϣⲁⲣⲱ|ⲛⲏ|ⲛⲛⲁϩⲣⲁ|ⲟⲩⲧⲱ|ⲛⲛⲁϩⲣⲏ|ϩⲁⲧⲏ|ⲉⲧⲃⲏⲏ|ⲛⲣⲁⲧ|ⲉⲣⲁ|ⲛⲁϩⲣⲁ|ⲛϩⲏ|ϩⲓⲧⲟⲟ|ⲕⲁⲧⲁ|ⲙⲉⲭⲣⲓ|ⲡⲁⲣⲁ|ⲉⲧⲃⲉ|ⲛⲧⲉ|ⲙⲛⲛⲥⲱ|ⲛⲁϩⲣⲉ?[ⲁⲙⲛ]";
$nprep = "ⲉ|ⲛ|ⲙ|ⲉⲧⲃⲉ|ϣⲁ|ⲛⲥⲁ|ⲕⲁⲧⲁ|ⲙⲛ|ϩⲓ|ⲛⲧⲉ|ϩⲁⲧⲛ|ϩⲁⲧⲙ|ϩⲓⲣⲙ|ϩⲓⲣⲛ|ⲉⲣⲁⲧ|ϩⲛ|ϩⲙ|ϩⲓⲧⲛ|ϩⲓⲧⲙ|ϩⲓϫⲛ|ϩⲓϫⲙ|ϩⲁ|ⲙⲉⲭⲣⲓ|ⲡⲁⲣⲁ|ⲛⲁ|ⲛⲧⲉ|ⲛ?ⲛⲁϩⲣⲉ?[ⲙⲛ]|ⲉϫ[ⲛⲙ]";
$indprep = "ⲉⲧⲃⲉ|ϩⲛ|ϩⲙ";
$ppers = "ⲓ|ⲕ|ϥ|ⲥ|ⲛ|ⲧⲉⲧⲛ|(?<=ⲙⲡ)ⲉⲧⲛ|(?<=ϣⲁⲛⲧ)ⲉⲧⲛ|(?<=ⲧⲣⲉ)ⲧⲛ|ⲟ?ⲩ|(?<=ⲛ)ⲅ";
$ppero = "ⲓ|ⲕ|ϥ|ⲥ|ⲛ|ⲧⲛ|ⲧⲏⲩⲧⲛ|ⲟ?ⲩ|(?<=[ⲉⲟ]ⲟⲩ)ⲧ";
$pperinterloc = "ⲁⲛⲅ|ⲛⲧⲕ|ⲛⲧⲉ|ⲁⲛ|ⲁⲛⲟⲛ|ⲛⲧⲉⲧⲛ";
$art = "ⲡ|ⲡⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲛ|ⲛⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲧ|ⲧⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲟⲩ|(?<=[ⲁⲉ])ⲩ|ϩⲉⲛ|ⲡⲉⲓ|ⲧⲉⲓ|ⲛⲉⲓ|ⲕⲉ|ⲙ(?=[ⲙⲡⲃ])|ⲡⲓ|ⲛⲓ|ϯ";
$ppos = "[ⲡⲧⲛ]ⲉ[ⲕϥⲥⲛⲩ]|[ⲡⲧⲛ]ⲉⲧⲛ|[ⲡⲧⲛ]ⲁ|[ⲡⲧⲛ]ⲟⲩ";
$triprobase = "ⲁ|ⲙⲡ|ⲙⲡⲉ|ϣⲁ|ⲙⲉ|ⲙⲡⲁⲧ|ϣⲁⲛⲧⲉ?|ⲛⲧⲉⲣⲉ?|ⲛⲛⲉ|ⲛⲧⲉ|ⲛ|ⲧⲣⲉ|ⲧⲁⲣⲉ|ⲙⲁⲣⲉ|ⲙⲡⲣⲧⲣⲉ"; 
$trinbase = "ⲁ|ⲙⲡⲉ|ϣⲁⲣⲉ|ⲙⲉⲣⲉ|ⲙⲡⲁⲧⲉ|ϣⲁⲛⲧⲉ|ⲛⲧⲉⲣⲉ|ⲛⲛⲉ|ⲛⲧⲉⲣⲉ|ⲛⲧⲉ|ⲧⲣⲉ|ⲧⲁⲣⲉ|ⲙⲁⲣⲉ|ⲙⲡⲣⲧⲣⲉ|ⲉⲣϣⲁⲛ";
$bibase = "ϯ|ⲧⲉ|ⲕ|ϥ|ⲥ|ⲧⲛ|ⲧⲉⲧⲛ|ⲥⲉ";
$exist = "ⲟⲩⲛ|ⲙⲛ";

#get external open class lexicon
if ($lexicon ne "")
{
open LEX,"<:encoding(UTF-8)",$lexicon or die "could not find lexicon file";
while (<LEX>) {
    chomp;
	if ($_ =~ /^(.*)\t(.*)\t(.*)$/) #ignore comments in modifier file marked by #
    {
	if ($2 eq 'N') {$nounlist .= "$1|";} 
	if ($2 eq 'NPROP') {$namelist .= "$1|";} 
	elsif ($2 eq 'V') {	$verblist .= "$1|";} 
	elsif ($2 eq 'VSTAT') {$vstatlist .= "$1|";} 
	elsif ($2 eq 'ADV') {$advlist .= "$1|";} 
	elsif ($2 eq 'VBD') {$vbdlist .= "$1|";} 
	elsif ($2 eq 'IMOD') {$imodlist .= "$1|";} 
	elsif ($2 ne 'N') {$stoplist{$1} = "$1;$2";} 
	}
}


#add ad hoc stoplist members
$stoplist{'ϥⲓ'} = 'ϥⲓ;V';

#add negated TM forms of verbs
$tm = $verblist;
$tm =~ s/\|/|ⲧⲙ/g;
$verblist .=  "$tm";

$nounlist .="ⲥⲁⲧⲁⲛⲁⲥ|%%%";
$verblist .="%%%";
$vstatlist .="%%%";
$advlist .="%%%";
$namelist .="ⲡⲁⲓ|ⲧⲁⲓ|ⲛⲁⲓ|ϭⲉ|%%%";
}
### END LEXICON ###

### PREVIOUS SEGMENTATIONS ###
#get most frequent previous segmentations from training corpus
if ($segfile ne "")
{
open SEG,"<:encoding(UTF-8)",$segfile or die "could not find segmentation file";
while (<SEG>) {
    chomp;
	if ($_ =~ /^(.*)\t(.*)$/)
    {
		$segs{$1} = $2;
	}
}
}
#get most frequent previous morphological analyses from training corpus
if ($morphfile ne "")
{
open MORPH,"<:encoding(UTF-8)",$morphfile or die "could not find segmentation file";
while (<MORPH>) {
    chomp;
	if ($_ =~ /^(.*)\t(.*)$/)
    {
		$morphs{$1} = $2;
	}
}
}
### END PREVISOUS SEGMENTATIONS ###

# ADD TAG SUPPORT TO LEXICON

#Global to flag theta fixing
$fix_theta_group = 0;

open FILE,"<:encoding(UTF-8)",shift or die "could not find input document";
$preFirstWord = 1;
$strCurrentTokens = "";
$strOutput ="";
$strOutput ="";
while (<FILE>) {

    chomp;
	$input = $_;
	$input =~ s/\n//g;
	if ($input =~ /^<[^>+]>$/ || $nolines==1)
	{
		$line.=$input;
	}
	else
	{
		$line .= "<line>". $input ."</line>";
	}
}
	
	
	$line = &preprocess($line);
	$line =~ s/^\n+//;
	$line =~ s/\n+$//;

	@sublines = split("\n+",$line);
	foreach $subline (@sublines)	{

		if ($subline =~ /<norm_group norm_group=\"([^\"]+)\">/) {
			#bound group begins, tokenize full form from element attribute
			
			if ($preFirstWord == 1)
			{
				$strOutput .= $strCurrentTokens;
				$strCurrentTokens = "";
				$preFirstWord=0;
			}
			$word = $1;
			
			$strTokenized = &tokenize($word);
			$subline = &restore_caps($subline);
			$strOutput .= $strCurrentTokens;
			$strCurrentTokens = "";
			
			if ($noword == 1) {$subline =~ s/\n*<norm_group[^>]*>\n*//g; $strOutput .= $subline;
			}
			else{	 $subline =~ s/\|//g; $strOutput .= $subline ."\n";}
		}
		elsif ($subline eq "</norm_group>"){
			#bound group ends, flush tags and output resegmented tokens
				#search for morphemes to add

			$strCurrentTokens = &align($strCurrentTokens,$strTokenized,"norm");
			@norms =  ( $strCurrentTokens =~ /norm=\"([^\"]+)\"/g );
			$strMorphed = "";
			foreach $norm (@norms){
				$analysis = &morph_analyze($norm);
				if ($analysis =~ m/\|/){
					$strMorphed .= "|" . $analysis . "|";
				}
				$strMorphed =~ s/\|+/\|/g;
			}
			$strMorphed =~ s/^\|//;
			$strMorphed =~ s/\|$//;

			$strCurrentTokens = &align($strCurrentTokens,$strMorphed,"morph");

			if ($pipes == 1)
			{
				$strCurrentTokens =~ s/\n<\/norm>\n<norm[^>]*>\n/|/g;
				$strCurrentTokens =~ s/<\/?norm[^>]*>\n//g;
				$strCurrentTokens =~ s/\n<\/morph>\n<morph[^>]*>\n/-/g;
				$strCurrentTokens =~ s/<\/?morph[^>]*>\n//g;
			}
			else
			{
				$strCurrentTokens =~ s/\|/\n/g;
			}
			$strCurrentTokens =~ s/\n+/\n/g;
			$strOutput .= $strCurrentTokens;
			$strCurrentTokens = "";
			if ($noword == 1) {$subline =~ s/\n*<\/?norm_group[^>]*>\n*//g;}
			$strOutput .= $subline ;
			if ($fix_theta_group==1){
				if ($strOutput =~ /.*<norm_group norm_group="([^"]*ⲑ[^"]*)"/ms){
					$orig_group = $1;
				}
				$strOutput =~ s/(.*<norm_group norm_group="[^"]*)ⲑ([^"]*")/$1ⲧϩ$2/ms;
				if ($strOutput =~ /.*<norm_group norm_group="([^"]+)"/ms){
					$last_norm_group = $1;
				}
				if ($last_norm_group =~ /(̈|%|̄|̀|̣|`|̅|̈|̂|︤|︥|︦|⳿|~|\[|\]|̇)/){
					$last_norm_group =~ s/(̈|%|̄|̀|̣|`|̅|̈|̂|︤|︥|︦|⳿|~|\[|\]|̇)//g;
					$strOutput =~ s/(.*<norm_group norm_group=")([^"]+)"/$1$last_norm_group"/ms;
				}
				$strOutput =~ s/(.*)<norm_group /$1<norm_group orig_group="$orig_group" /ms;
				$fix_theta_group = 0;
			}
			
		}
		elsif ($subline =~ m/<.*>/) {
			#other SGML tag, just save it
			$strCurrentTokens .= $subline ."\n";
		}
		else
		{
			#token
			$strCurrentTokens .= $subline ."\n";
		}
	}
	$strOutput = &orderSGML($strOutput);
	print $strOutput;

	sub tokenize{
	$strWord = $_[0];
	
	
	if ($strWord =~ /<.+>/)
	{
		$strWord =~ s/@/ /g;
		$strOutput .= "$strWord\n"; #XML tag
	}
	elsif ($strWord eq ""){ #do nothing
	}
		else
	{
		
		$dipl = $strWord;
		#$strWord = &encode_caps($strWord);
		$strWord =~ s/(̈|%|̄|̀|̣|`|̅|̈|̂|︤|︥|︦|⳿|~|\[|\]|̇)//g; 

		#remove supralinear strokes and other decorations for tokenization
		if ($strWord =~ /\|/) #pipes found, assume explicit tokenization is present
		{
			$dipl =~ s/\|//g;
			$strWord;
		}
		else #try to tokenize based on grammar patterns
		{

			#check for theta/phi containing an article
			if($strWord =~ /^($nprep|$pprep)?(ⲑ|ⲫ)(.+)$/) 
			{
				if (defined($1)){$opt_prep = $1;}else{$opt_prep="";}
				$theta_phi = $2;
				$noun_candidate = $3;
				$noun_candidate =  "ϩ" . $noun_candidate;
				if ($noun_candidate =~ /^($nounlist|$namelist)$/) #experimentally allowing proper nouns with articles
				{
					if ($theta_phi eq "ⲑ") {$theta_phi = "ⲧ";} else {$theta_phi = "ⲡ";}
					$strWord = $opt_prep . $theta_phi . $noun_candidate;
				}
			}
			#check for theta containing a relative converter
			
			if($strWord =~ /^((?:(?:$nprep|$pprep)?$art)?ⲉⲑ)(.+)$/) 
			{
				$theta= $1;
				$verb_candidate = $2;
				$theta=~s/ⲑ$/ⲧ/;
				$verb_candidate =  "ϩ" .  $verb_candidate;
				if ($verb_candidate =~ /^($verblist|$vstatlist)$/) 
				{
					$strWord = $theta . $verb_candidate;
				}
			}


			#check for fused t-i
			if($strWord =~ /^(ϣⲁⲛ)ϯ(.*)/) 
			{
				$candidate = $1;
				$candidate .=  "ⲧ";
				if (defined($2)){$ending = $2;}else{$ending="";}
				if ($candidate =~ /^($triprobase|$pprep)$/) 
				{
					$strWord = $candidate . "ⲓ". $ending;
				}
			}
			elsif($strWord =~ /^(.*)ϯ(.+)$/) 
			{
				$candidate = $2;
				$candidate =  "ⲓ" . $candidate;
				if (defined($1)){$start = $1;}else{$start="";}
				if ($candidate =~ /^($nounlist|$namelist)$/) 
				{
					$strWord = $start . "ⲧ". $candidate;
				}
			}
					
			#adhoc segmentations
			if ($strWord =~ /^ⲛⲁⲩ$/){$strWord = "ⲛⲁ|ⲩ";} #free standing nau is a PP not a V
			elsif ($strWord =~ /^ⲛⲁϣ$/){$strWord = "ⲛ|ⲁϣ";} #"in which (way)"
			elsif ($strWord =~ /^ⲉⲓⲣⲉ$/){$strWord = "ⲉⲓⲣⲉ";} #free standing eire is not e|i|re
			elsif ($strWord =~ /^ϩⲟⲡⲟⲩ$/){$strWord = "ϩⲟⲡⲟⲩ";} #free standing hopou is not hop|ou
			elsif ($strWord =~ /^ⲉϫⲓ$/){$strWord = "ⲉ|ϫⲓ";} 
			elsif ($strWord =~ /^ⲛⲏⲧⲛ$/){$strWord = "ⲛⲏ|ⲧⲛ";} 

			#check stoplist
			elsif (exists $stoplist{$strWord}) {$strWord = $strWord;} 

			#check segmentation file
			elsif (exists $segs{$strWord}) {$strWord = $segs{$strWord};} 
			
			#adverbs
			elsif ($strWord =~ /^($advlist)$/){$strWord = $1;}
			
			#optative/conditional, make ppers a portmanteau segment with base
			elsif ($strWord =~ /^(ⲉ)($ppers)(ⲉ|ϣⲁⲛ)($verblist)$/) {$strWord = $1 . $2 . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉ)($ppers)(ⲉ|ϣⲁⲛ)($verblist)($nounlist|$ppero|$namelist)$/) {$strWord = $1 . $2 . $3 . "|" . $4."|" . $5;}
			elsif ($strWord =~ /^(ⲉ)($ppers)(ⲉ|ϣⲁⲛ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . $2 . $3 . "|" . $4."|" . $5."|" . $6;}
			
			
			#ⲧⲏⲣ=
			elsif ($strWord =~ /^(ⲧⲏⲣ)($ppero)$/){$strWord = $1 ."|" . $2;}

			#pure existential
			elsif ($strWord =~ /^(ⲟⲩⲛ|ⲙⲛ)($nounlist)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲟⲩⲛ|ⲙⲛ)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}

			#prepositions
			elsif ($strWord =~ /^($pprep)($ppero)$/){$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^($nprep)($namelist)$/){$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^($nprep)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;} #experimentally allowing proper nouns with articles
			elsif ($strWord =~ /^($nprep)([ⲡⲧⲛ]ⲁ)($namelist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;} 
			elsif ($strWord =~ /^($nprep)([ⲡⲧⲛ]ⲁ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|" . $4;} 
			elsif ($strWord =~ /^(ϫⲉ)($pprep)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ϫⲉ)($nprep)($namelist)$/){$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ϫⲉ)($nprep)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;} #experimentally allowing proper nouns with articles
			#elsif ($strWord =~ /^($nprep)($art|$ppos)ⲉ($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}

			#tripartite clause
			#pronominal
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			#2sgF
			elsif ($strWord =~ /^(ⲁⲣ)($verblist)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^(ⲁⲣ)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ⲁⲣ)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 ;}
			#proper name subject
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ;}
			#prenominal
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			#proper name subject separate bound group
			elsif ($strWord =~ /^($trinbase)($namelist)$/)  {$strWord = $1 . "|" . $2;}
			#prenominal separate bound group
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3;}

			#with je-
			#pronominal
			elsif ($strWord =~ /^(ϫⲉ)($triprobase)($ppers)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)($triprobase)($ppers)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^(ϫⲉ)($triprobase)($ppers)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			#2sgF
			elsif ($strWord =~ /^(ϫⲉ)(ⲁⲣ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲁⲣ)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲁⲣ)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			#proper name subject
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($namelist)($verblist)$/)   {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($namelist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($namelist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			#prenominal
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($art|$ppos)($nounlist)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($art|$ppos)($nounlist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6;}
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($art|$ppos)($nounlist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6;}
			#proper name subject separate bound group
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($namelist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3;}
			#prenominal separate bound group
			elsif ($strWord =~ /^(ϫⲉ)($trinbase)($art|$ppos)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}

			
			#elsif ($strWord =~ /^($art|$ppos)($namelist)$/) {$strWord = $1 . "|" . $2 ;} #experimental, allow names with article
			#relative generic NP p-et-o, ... 
			elsif ($strWord =~ /^(ⲉⲧ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^($art)(ⲉⲧ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($art)(ⲉⲧ)($pprep)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉⲧ)(ⲛⲁ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2. "|" . $3 ;}
			elsif ($strWord =~ /^($art)(ⲉⲧ)(ⲛⲁ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|" . $4;}
			#with nqi
			elsif ($strWord =~ /^(ⲛϭⲓ)($art)(ⲉⲧ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲛϭⲓ)($art)(ⲉⲧ)($pprep)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^(ⲛϭⲓ)($art)(ⲉⲧ)(ⲛⲁ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			#with preposition
			elsif ($strWord =~ /^($nprep)($art)(ⲉⲧ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|" . $4;}
			elsif ($strWord =~ /^($nprep)($art)(ⲉⲧ)($pprep)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^($nprep)($art)(ⲉⲧ)(ⲛⲁ)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|" . $4 . "|" . $5;}
			#presentative
			elsif ($strWord =~ /^(ⲉⲓⲥ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}

			#Verboids
			#pronominal subject - peja=f, nanou=s
			elsif ($strWord =~ /^($vbdlist)($ppero)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)($vbdlist)($ppero)$/) {$strWord = $1 . "|" . $2  . "|" . $3;} #negated
			elsif ($strWord =~ /^(ϫⲉ)($vbdlist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" .$3  ;} #with je
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($vbdlist)($ppero)$/) {$strWord = $1 . "|" . $2  . "|" . $3. "|" .$4;} #negated with je
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛ?ⲉⲣⲉ)($vbdlist)($ppero)$/) {$strWord = $1 . "|" . $2. "|" . $3 ;} # converted
			
			#nominal subject - peje-prwme
			#elsif ($strWord =~ /^($vbdlist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			
			#bipartite clause
			#pronominal + future
			elsif ($strWord =~ /^($bibase)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)($bibase)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2."|".$3;} #negated
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;}
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5;}
			elsif ($strWord =~ /^($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|".$5;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;} #negated
			elsif ($strWord =~ /^(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4. "|" . $5;}#negated
			elsif ($strWord =~ /^(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5. "|" . $6;}#negated
			elsif ($strWord =~ /^(ⲛ|ⲙ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}#negated
			elsif ($strWord =~ /^(ⲛ|ⲙ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|".$5. "|" . $6;}#negated
			#indefinite + future
			elsif ($strWord =~ /^($exist)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			#with je-
			#pronominal + future
			elsif ($strWord =~ /^(ϫⲉ)($bibase)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ϫⲉ)($bibase)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;}
			elsif ($strWord =~ /^(ϫⲉ)($bibase)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5;}
			elsif ($strWord =~ /^(ϫⲉ)($bibase)(ⲛⲁ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6;}
			elsif ($strWord =~ /^(ϫⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5;}
			elsif ($strWord =~ /^(ϫⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($bibase)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4. "|".$5;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5. "|".$6;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($bibase)(ⲛⲁ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6. "|".$7;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5. "|".$6;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ|ⲙ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6. "|".$7;}
			#indefinite + future
			elsif ($strWord =~ /^(ϫⲉ)($exist)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;}
			elsif ($strWord =~ /^(ϫⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5;}
			elsif ($strWord =~ /^(ϫⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5 . "|". $6;}
			
			#converted bipartite clause
			#pronominal + future
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($ppers)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($ppers)($nprep)($art)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;} #PP predicate
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($ppers)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($ppers)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			#nominal
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			#indefinite
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			#with je-
			#pronominal + future
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($ppers)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($ppers)($nprep)($art)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6;} #PP predicate
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($ppers)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($ppers)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6;}
			#nominal
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6."|".$7;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛ?ⲉⲣⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			#indefinite
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($exist)($nounlist)($verblist|$vstatlist|$advlist)$/){$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5."|".$6."|".$7;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲛⲉ)($exist)($nounlist)$/){$strWord = $1 . "|" . $2 . "|" . $3 ."|".$4;}
			
			#interlocutive nominal sentence
			elsif ($strWord =~ /^($pperinterloc)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2  . "|" . $3 ;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)($pperinterloc)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2  . "|" . $3. "|" . $4 ;}
			elsif ($strWord =~ /^(ϫⲉ)($pperinterloc)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)(ϫⲉ)($pperinterloc)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			
			
			#simple NP - moved from before "relative generic NP p-et-o, ... " to account for preterite ne|u-sotm instead of possessive *neu-sotm with nominalized verb
			#if this causes trouble consider splitting ART and PPOS cases of simple NP
			elsif ($strWord =~ /^(ⲛϭⲓ|ϫⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^([ⲡⲧⲛ]ⲁ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 ;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 ;}
			elsif ($strWord =~ /^(ⲛ|ⲙ)([ⲡⲧⲛ]ⲁ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲛϭⲓ|ϫⲉ)($namelist)$/) {$strWord = $1 . "|" . $2 ;}

			#nominal separated future verb or independent/to-infinitive
			elsif($strWord =~ /^($verblist)($ppero)$/){$strWord = $1 . "|" . $2;}
			elsif($strWord =~ /^(ⲛⲁ|ⲉ)($verblist)$/){$strWord = $1 . "|" . $2;}
			elsif($strWord =~ /^(ⲛⲁ|ⲉ)($verblist)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif($strWord =~ /^(ⲉ)(ⲧⲣⲉ)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif($strWord =~ /^(ⲉ)(ⲧⲣⲉ)($ppers)($verblist)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif($strWord =~ /^(ⲉ)(ⲧⲙ)(ⲧⲣⲉ)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|" . $5;}
			elsif($strWord =~ /^(ⲉ)(ⲧⲙ)(ⲧⲣⲉ)($ppers)($verblist)($ppero)$/){$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5 . "|" . $6;}

			#converted tripartite clause
			#pronominal
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($ppers)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($ppers)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;} #nominalized
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($ppers)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5 . "|" . $6;} #nominalized
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁⲣ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;} #nominalized
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁⲣ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;} #nominalized
			#prenominal
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)$/)   {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)$/)   {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}  #nominalized
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($art|$ppos)($nounlist)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|" . $6;}  #nominalized
			#proper name subject separate bound group
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($namelist)$/)  {$strWord = $1 . "|" . $2 . "|". $3;}
			#prenominal separate bound group
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3. "|" . $4;}

			#possessives
			elsif ($strWord =~ /^((?:ⲟⲩⲛⲧ|ⲙⲛⲧ)[ⲁⲉⲏ]?)($ppers)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^((?:ⲟⲩⲛⲧ|ⲙⲛⲧ)[ⲁⲉⲏ]?)($ppers)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^(ⲛⲉ|ⲉ)((?:ⲟⲩⲛⲧ|ⲙⲛⲧ)[ⲁⲉⲏ]?)($ppers)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3."|".$4;}
			elsif ($strWord =~ /^(ⲛⲉ|ⲉ)((?:ⲟⲩⲛⲧ|ⲙⲛⲧ)[ⲁⲉⲏ]?)($ppers)$/) {$strWord = $1 . "|" . $2 . "|" . $3 ;}

			#IMOD
			elsif ($strWord =~ /^($imodlist)($ppero)$/) {$strWord = $1 . "|" . $2;}

			#converter+prep
			elsif ($strWord =~ /^(ⲉⲧ)($indprep)$/) {$strWord = $1 . "|" . $2;}

			#PP with no article
			elsif ($strWord =~ /^($nprep)($nounlist|$namelist)$/) {$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^(ϫⲉ)($nprep)($nounlist|$namelist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 ;}

			#negative imperative
			elsif ($strWord =~ /^(ⲙⲡⲣ)($verblist)$/) {$strWord = $1 . "|" . $2;}

			#tm preposed before subject in negative conjunctive with separated verb
			elsif ($strWord =~ /^(ⲛⲧⲉ)(ⲧⲙ)($nounlist)$/) {$strWord = $1 . "|" . $2. "|" . $3;}
			
			#p-tre-f-V style NP with or without preposition
			elsif ($strWord =~ /^($nprep|ϫⲉ)(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($ppero)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|" . $5;}
			elsif ($strWord =~ /^($nprep|ϫⲉ)(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|" . $5;}
			elsif ($strWord =~ /^(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($ppero)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($ppero)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|" . $5;}
			elsif ($strWord =~ /^(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ϫⲉ)(ⲡⲉ?|$ppos)(ⲧⲣⲉ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|" . $5;}
			
			#else {			
			#nothing found
			#}	

		#split off negating TMs
		if ($strWord=~/\|ⲧⲙ(?!ⲁⲉⲓⲏⲩ|ⲁⲓⲏⲩ|ⲁⲓⲟ|ⲁⲓⲟⲕ|ⲙⲟ|ⲟ$|\|)/) {$strWord =~ s/\|ⲧⲙ/|ⲧⲙ|/;}
		
		$strWord;
	}

}
}

sub morph_analyze{

	$strUnit	 = $_[0];
	
	#check segmentation file
	if (exists $morphs{$strUnit}) {$strUnit = $morphs{$strUnit};} 

	#mnt
	elsif ($strUnit =~ /^(ⲙⲛⲧ)(ⲁⲧ)(..+)$/) {$strUnit = $1 . "|" . $2 . "|" . $3;}
	elsif ($strUnit =~ /^(ⲙⲛⲧ)(ⲣⲉϥ)(..+)$/) {$strUnit = $1 . "|" . $2 . "|" . $3;}
	elsif($strUnit =~ /^(ⲙⲛⲧ)(..+)$/) {$strUnit = $1 . "|" . $2;} #might overgenerate
	
	#ref
	elsif ($strUnit =~ /^(ⲣⲉϥ)(ⲣ)($nounlist)$/) {$strUnit = $1 . "|" . $2 . "|" . $3;}
	elsif ($strUnit =~ /^(ⲣⲉϥ)($verblist)$/) {$strUnit = $1 . "|" . $2;}

	#no entries for plain at- : consider if no overgeneration
	
	#VN compounds
	elsif($strUnit =~ /^($verblist)($nounlist)$/) { if(length($1)>2){$strUnit = $1 . "|" . $2;}} #might overgenerate	
	
	$strUnit;
}

sub preprocess{

	$rawline = $_[0];
	$rawline =~ s/([^< ]+) (?=[^<>]*>)/$1%/g;
	$rawline =~ s/([^<_]+)_(?=[^<>]*>)/$1@/g;
	$rawline =~ s/_/ /g;	
	$rawline =~ s/ +/ /g;	
	$rawline =~ s/(^| +)([^ ]+)(?=[ ]+|$)/$1 . '<norm_group%norm_group="' . &removexml($2) . '">' . $2 . "<\/norm_group>"/eg;
	$rawline =~ s/>/>\n/g;
	$rawline =~ s/</\n</g;
	$rawline =~ s/\n+/\n/g;
	$rawline =~ s/^\n//;
	$rawline =~ s/\n$//;
	$rawline =~ s/%/ /g;
	$rawline =~ s/@/_/g;
	$rawline = &encode_caps($rawline);
	$rawline;
	
}

sub removexml{
	$input = $_[0];
	$input =~ s/<[^<>]+>//g;
	$input;
}

sub encode_caps{
	$input = $_[0];
	$input =~ s/Ⲁ/ⲁ~/g;
	$input =~ s/Ⲃ/ⲃ~/g;
	$input =~ s/Ⲅ/ⲅ~/g;
	$input =~ s/Ⲇ/ⲇ~/g;
	$input =~ s/Ⲉ/ⲉ~/g;
	$input =~ s/Ⲍ/ⲍ~/g;
	$input =~ s/Ⲏ/ⲏ~/g;
	$input =~ s/Ⲑ/ⲑ~/g;
	$input =~ s/Ⲓ/ⲓ~/g;
	$input =~ s/Ⲕ/ⲕ~/g;
	$input =~ s/Ⲗ/ⲗ~/g;
	$input =~ s/Ⲙ/ⲙ~/g;
	$input =~ s/Ⲛ/ⲛ~/g;
	$input =~ s/Ⲟ/ⲟ~/g;
	$input =~ s/Ⲝ/ⲝ~/g;
	$input =~ s/Ⲡ/ⲡ~/g;
	$input =~ s/Ⲣ/ⲣ~/g;
	$input =~ s/Ⲥ/ⲥ~/g;
	$input =~ s/Ⲧ/ⲧ~/g;
	$input =~ s/Ⲩ/ⲩ~/g;
	$input =~ s/Ⲭ/ⲭ~/g;
	$input =~ s/Ⲯ/ⲯ~/g;
	$input =~ s/Ⲫ/ⲫ~/g;
	$input =~ s/Ⲱ/ⲱ~/g;
	$input =~ s/Ϭ/ϭ~/g;
	$input =~ s/Ϩ/ϩ~/g;
	$input =~ s/Ϥ/ϥ~/g;
	$input =~ s/Ϫ/ϫ~/g;
	$input =~ s/Ϣ/ϣ~/g;
	$input =~ s/Ϯ/ϯ~/g;
	$input;
}

sub restore_caps{
	$input = $_[0];
	$input =~ s/ⲁ~/Ⲁ/g;
	$input =~ s/ⲃ~/Ⲃ/g;
	$input =~ s/ⲅ~/Ⲅ/g;
	$input =~ s/ⲇ~/Ⲇ/g;
	$input =~ s/ⲉ~/Ⲉ/g;
	$input =~ s/ⲍ~/Ⲍ/g;
	$input =~ s/ⲏ~/Ⲏ/g;
	$input =~ s/ⲑ~/Ⲑ/g;
	$input =~ s/ⲓ~/Ⲓ/g;
	$input =~ s/ⲕ~/Ⲕ/g;
	$input =~ s/ⲗ~/Ⲗ/g;
	$input =~ s/ⲙ~/Ⲙ/g;
	$input =~ s/ⲛ~/Ⲛ/g;
	$input =~ s/ⲟ~/Ⲟ/g;
	$input =~ s/ⲝ~/Ⲝ/g;
	$input =~ s/ⲡ~/Ⲡ/g;
	$input =~ s/ⲣ~/Ⲣ/g;
	$input =~ s/ⲥ~/Ⲥ/g;
	$input =~ s/ⲧ~/Ⲧ/g;
	$input =~ s/ⲩ~/Ⲩ/g;
	$input =~ s/ⲭ~/Ⲭ/g;
	$input =~ s/ⲯ~/Ⲯ/g;
	$input =~ s/ⲫ~/Ⲫ/g;
	$input =~ s/ⲱ~/Ⲱ/g;
	$input =~ s/ϭ~/Ϭ/g;
	$input =~ s/ϩ~/Ϩ/g;
	$input =~ s/ϥ~/Ϥ/g;
	$input =~ s/ϫ~/Ϫ/g;
	$input =~ s/ϣ~/Ϣ/g;
	$input =~ s/ϯ~/Ϯ/g;
	$input;
}

sub orderSGML{
	$input = $_[0];
	@lines = split("\n",$input);
	foreach $line (@lines)	{
		if ($line =~ m/(<\/([^>]+)>)/) { # Closing tag
			if (!(exists $closers{$2})){$closers{$2} = $1;}
			else{$closers{$2} = $1}
		}
		elsif ($line =~ m/(<([^> ]+)[^>]*>)/) { # Opening tag
			if (!(exists $openers{$2})){$openers{$2} = $1;}
			else{$openers{$2} = $1}
		}
		else { # Token - flush opening and closing tags in order
		&flush_tags(\%closers,"close");
		&flush_tags(\%openers,"open");
		print "$line\n";
		undef %openers;
		undef %closers;
		}
	}

	&flush_tags(\%closers,"close");
}

sub flush_tags{
	@priorities = ('pb','cb','line','norm_group','norm','gap','hi','morph','m');
	my %tags =  %{$_[0]};
	$close = $_[1];
	if ($close eq "close"){
		@priorities = reverse @priorities;
			foreach my $key ( sort keys %tags )	{
				if (!( $key ~~ @priorities)){
					print "$tags{$key}\n";
				}
			}
		}
	foreach $priority (@priorities){
		if (exists $tags{$priority}){
			print $tags{$priority}."\n";
		}
		delete $tags{$priority};
	}
	if ($close eq "open"){
		foreach my $key ( sort {$b cmp $a} keys %tags )	{
			print "$tags{$key}\n";
		}
	}
}

sub align{
			$strCurrentTokens = $_[0];
			$strTokenized = $_[1];
			$tag = $_[2];
			
			$strPattern = ($strTokenized);
			@t = split(/\|/, $strTokenized);

			$strPattern =~ s/([\[\]\(\)])/\\$1/g;
			$strPattern =~ s/([^\\\|\n\r])/$1#/g;
			$strPattern =~ s/\|/\)\(/g;
			$strPattern =~ s'#'(?:(?:[\r\\ṇ̄︦︤︥̀̂`⳿̣̂̅̈︤︦̇]|<[^>]+>|̣|~)*)?'g; #allow intervening tags, linebreaks, capital letter escapes with tilde, square brackets and Coptic diacritics
			$strPattern = join '','(?<!\\")(' , $strPattern , ')'; #negative lookbehind prevents matching tokens within a quoted attribute in an SGML tag
			$strPattern =~ s/\n*$//; #strip pattern 
			$strPattern =~ s/^\n*//;
			$strPattern =~ s/[\r]*//; #don't allow carriage returns anywhere
			$count = () = $strTokenized =~ /\|/g; 
			
			#handle split theta tokens
			if ($strCurrentTokens =~ /ⲑ/ && $strTokenized !~ /ⲑ/ && $strTokenized =~ /ⲧ\|ϩ/){
				$fix_theta = 1;
				$fix_theta_group = 1;
				$strCurrentTokens =~ s/ⲑ/ⲧϩ/;
			}
			else{
				$fix_theta = 0;
			}
			
			if ($strCurrentTokens =~ /$strPattern/){
				if ($count==0) {$t[0]=$strTokenized; $strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n/;}
				elsif ($count==1) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[0]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[1]\">\n$2\n<\/$tag>\n/;}
				elsif ($count==2) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n/;}
				elsif ($count==3) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n/;}
				elsif ($count==4) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n<$tag $tag=\"$t[(5-1)]\">\n$5\n<\/$tag>\n/;}
				elsif ($count==5) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n<$tag $tag=\"$t[(5-1)]\">\n$5\n<\/$tag>\n<$tag $tag=\"$t[(6-1)]\">\n$6\n<\/$tag>\n/;}
				elsif ($count==6) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n<$tag $tag=\"$t[(5-1)]\">\n$5\n<\/$tag>\n<$tag $tag=\"$t[(6-1)]\">\n$6\n<\/$tag>\n<$tag $tag=\"$t[(7-1)]\">\n$7\n<\/$tag>\n/;}
				elsif ($count==7) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n<$tag $tag=\"$t[(5-1)]\">\n$5\n<\/$tag>\n<$tag $tag=\"$t[(6-1)]\">\n$6\n<\/$tag>\n<$tag $tag=\"$t[(7-1)]\">\n$7\n<\/$tag>\n<$tag $tag=\"$t[(8-1)]\">\n$8\n<\/$tag>\n/;}
				elsif ($count==8) {$strCurrentTokens =~ s/$strPattern/<$tag $tag=\"$t[(1-1)]\">\n$1\n<\/$tag>\n<$tag $tag=\"$t[(2-1)]\">\n$2\n<\/$tag>\n<$tag $tag=\"$t[(3-1)]\">\n$3\n<\/$tag>\n<$tag $tag=\"$t[(4-1)]\">\n$4\n<\/$tag>\n<$tag $tag=\"$t[(5-1)]\">\n$5\n<\/$tag>\n<$tag $tag=\"$t[(6-1)]\">\n$6\n<\/$tag>\n<$tag $tag=\"$t[(7-1)]\">\n$7\n<\/$tag>\n<$tag $tag=\"$t[(8-1)]\">\n$8\n<\/$tag>\n<$tag $tag=\"$t[(9-1)]\">\n$9\n<\/$tag>\n/;}

				$strCurrentTokens =~ s/<$tag[^>]*>\s*<\/$tag>\s*//; #remove leading or trailing empty element
				if ($fix_theta){
					$strCurrentTokens =~ s/ⲧ(\n<\/$tag>\n<$tag $tag="([^"]+)">\n)ϩ/ⲑ$1/;
				}
				$strCurrentTokens = &restore_caps($strCurrentTokens);
			}
			else { 
				if  ($count==0) {
					$flat_word = $word;
					$flat_word =~ s/[\n\|]+//g;
					$strCurrentTokens =  "<$tag $tag=\"$flat_word\" warning=\"no pattern match for token\">\n" . $strCurrentTokens . "\n</$tag>\n"; #no match for pattern
				}
				else {

					$strUnits="";
					@subpipes = split('\|',$strTokenized);
					foreach $subpipe (@subpipes)	{
					$strUnits .= "<$tag $tag=\"$subpipe\">\n$subpipe\n</$tag>\n";
					
					}
					$strCurrentTokens = $strUnits;
				}
			}
			$strCurrentTokens =~ s/\n+/\n/g;
			$strCurrentTokens;
}
