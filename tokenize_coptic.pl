#!/usr/bin/perl -w

# tokenize_coptic.pl Version 2.0.2

# this assumes a UTF-8 file with untokenized 'word forms'
# separated by spaces
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
This script converts characters from one Coptic encoding to another.

Notes and assumptions:
- ...

Usage:  tokenize_coptic.pl [options] <FILE>

Options and argument:

-h              print this [h]elp message and quit
-p              output [p]ipe separated word forms instead of tokens in separate lines wrapped by <orig> tags
-l               add [l]ine tags marking original linebreaks in input file
-n              [n]o output of word forms in <orig_group> elements before the set of tokens extracted from each group

<FILE>    A text file encoded in UTF-8 without BOM, possibly containing markup


Examples:

Tokenize a Coptic plain text file in UTF-8 encoding (without BOM):
  tokenize_coptic.pl in_Coptic_utf8.txt > out_Coptic_tokenized.txt

Copyright 2013-2014, Amir Zeldes

This program is free software. You may copy or redistribute it under
the same terms as Perl itself.
_USAGE_
}

### OPTIONS BEGIN ###
%opts = ();
getopts('hlnp',\%opts) or die $usage;

#help
if ($opts{h} || (@ARGV == 0)) {
    print $usage;
    exit;
}
if ($opts{p})   {$pipes = 1;} else {$pipes = 0;}
if ($opts{l})   {$nolines = 0;} else {$nolines = 1;}
if ($opts{n})   {$noword = 1;} else {$noword = 0;}

### OPTIONS END ###

### BUILD LEXICON ###
#build function word lists
$pprep = "ⲁϫⲛⲧ|ⲉϩⲣⲁ|ⲉϩⲣⲁⲓⲉϫⲱ|ⲉϫⲛⲧⲉ|ⲉϫⲱ|ⲉⲣⲁⲧ|ⲉⲣⲁⲧⲟⲩ|ⲉⲣⲟ|ⲉⲣⲱ|ⲉⲧⲃⲏⲏⲧ|ⲉⲧⲟⲟⲧ|ϩⲁⲉⲓⲁⲧ|ϩⲁϩⲧⲏ|ϩⲁⲣⲁⲧ|ϩⲁⲣⲓϩⲁⲣⲟ|ϩⲁⲣⲟ|ϩⲁⲣⲱ|ϩⲁⲧⲟⲟⲧ|ϩⲓϫⲱ|ϩⲓⲣⲱ|ϩⲓⲧⲉ|ϩⲓⲧⲟⲟⲧ|ϩⲓⲧⲟⲩⲱ|ϩⲓⲱ|ϩⲓⲱⲱ|ⲕⲁⲧⲁⲣⲟ|ⲕⲁⲧⲁⲣⲱ|ⲙⲙⲟ|ⲙⲙⲱ|ⲙⲛⲛⲥⲱ|ⲙⲡⲁⲙⲧⲟⲉⲃⲟⲗ|ⲛⲏⲧⲛ|ⲛⲁ|ⲛϩⲏⲧ|ⲛⲙⲙⲏ|ⲛⲙⲙⲁ|ⲛⲥⲁⲃⲗⲗⲁ|ⲛⲥⲱ|ⲛⲧⲟⲟⲧ|ⲟⲩⲃⲏ|ϣⲁⲣⲟ|ϣⲁⲣⲱ|ⲛⲏ|ⲛⲛⲁϩⲣⲁ|ⲟⲩⲧⲱ|ⲛⲛⲁϩⲣⲏ|ϩⲁⲧⲏ|ⲉⲧⲃⲏⲏ|ⲛⲣⲁⲧ|ⲉⲣⲁ|ⲛⲁϩⲣⲁ|ⲛϩⲏ|ϩⲓⲧⲟⲟ|ⲕⲁⲧⲁ|ⲙⲉⲭⲣⲓ|ⲡⲁⲣⲁ|ⲉⲧⲃⲉ|ⲛⲧⲉ|ⲙⲛⲛⲥⲱ|ⲛⲁϩⲣⲉ?[ⲁⲙⲛ]";
$nprep = "ⲉ|ⲛ|ⲙ|ⲉⲧⲃⲉ|ϣⲁ|ⲛⲥⲁ|ⲕⲁⲧⲁ|ⲙⲛ|ϩⲓ|ⲛⲧⲉ|ϩⲁⲧⲛ|ϩⲁⲧⲙ|ϩⲓⲣⲙ|ϩⲓⲣⲛ|ⲉⲣⲁⲧ|ϩⲛ|ϩⲙ|ϩⲓⲧⲛ|ϩⲓⲧⲙ|ϩⲓϫⲛ|ϩⲓϫⲙ|ϩⲁ|ⲕⲁⲧⲁ|ⲙⲉⲭⲣⲓ|ⲡⲁⲣⲁ|ⲛⲁ|ⲛⲧⲉ|ⲛⲁϩⲣⲉ?[ⲙⲛ]";
$indprep = "ⲉⲧⲃⲉ|ϩⲛ|ϩⲙ";
$ppers = "ⲓ|ⲕ|ϥ|ⲥ|ⲛ|ⲧⲉⲧⲛ|(?<=ⲙⲡ)ⲉⲧⲛ|(?<=ϣⲁⲛⲧ)ⲉⲧⲛ|(?<=ⲧⲣⲉ)ⲧⲛ|ⲟ?ⲩ|(?<=ⲛ)ⲅ";
$ppero = "ⲓ|ⲕ|ϥ|ⲥ|ⲛ|ⲧⲛ|ⲧⲏⲩⲧⲛ|ⲟ?ⲩ|(?<=[ⲉⲟ]ⲟⲩ)ⲧ";
$pperinterloc = "ⲁⲛⲅ|ⲛⲧⲕ|ⲛⲧⲉ|ⲁⲛ|ⲁⲛⲟⲛ|ⲛⲧⲉⲧⲛ";
$art = "ⲡ|ⲡⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲛ|ⲛⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲧ|ⲧⲉ(?=(?:[^ⲁⲉⲓⲟⲩⲏⲱ][^ⲁⲉⲓⲟⲩⲏⲱ]|ⲯ|ⲭ|ⲑ|ⲫ|ⲝ|ϩⲟⲟⲩ|ⲟ?ⲩⲟⲉⲓϣ|ⲣⲟⲙⲡⲉ|ⲟ?ⲩϣⲏ|ⲟ?ⲩⲛⲟⲩ))|ⲟⲩ|(?<=[ⲁⲉ])ⲩ|ϩⲉⲛ|ⲡⲉⲓ|ⲧⲉⲓ|ⲛⲉⲓ|ⲕⲉ|ⲙ(?=ⲙ)|ⲡⲓ|ⲛⲓ|ϯ";
$ppos = "[ⲡⲧⲛ]ⲉ[ⲕϥⲥⲛⲩ]|[ⲡⲧⲛ]ⲉⲧⲛ|[ⲡⲧⲛ]ⲁ";
$triprobase = "ⲁ|ⲙⲡ|ⲙⲡⲉ|ϣⲁ|ⲙⲉ|ⲙⲡⲁⲧ|ϣⲁⲛⲧⲉ?|ⲛⲧⲉⲣⲉ?|ⲛⲛⲉ|ⲛⲧⲉ|ⲛ|ⲧⲣⲉ|ⲧⲁⲣⲉ|ⲙⲁⲣⲉ|ⲙⲡⲣⲧⲣⲉ"; 
$trinbase = "ⲁ|ⲙⲡⲉ|ϣⲁⲣⲉ|ⲙⲉⲣⲉ|ⲙⲡⲁⲧⲉ|ϣⲁⲛⲧⲉ|ⲛⲧⲉⲣⲉ|ⲛⲛⲉ|ⲛⲧⲉⲣⲉ|ⲛⲧⲉ|ⲧⲣⲉ|ⲧⲁⲣⲉ|ⲙⲁⲣⲉ|ⲙⲡⲣⲧⲣⲉ|ⲉⲣϣⲁⲛ";
$bibase = "ϯ|ⲧⲉ|ⲕ|ϥ|ⲥ|ⲧⲛ|ⲧⲉⲧⲛ|ⲥⲉ";
$exist = "ⲟⲩⲛ|ⲙⲛ";

#get external open class lexicon
$lexicon = "copt_lex.tab";
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
	else {$stoplist{$1} = "$1;$2";} 
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

# ADD TAG SUPPORT TO LEXICON
#$namelist =~ s/(.)/$1(?:(?:<[^>]+>)+)?/g;

open FILE,"<:encoding(UTF-8)",shift or die "could not find input document";
$preFirstWord = 1;
$strCurrentTokens = "";

while (<FILE>) {

    chomp;
	$input = $_;
	$input =~ s/\n//g;
	if ($input =~ /^<[^>+]>$/ || $nolines==1)
	{
		$line.=$input . " ";
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
		if ($subline =~ /<orig_group orig_group=\"([^\"]+)\">/) {
			#bound groups begins, tokenize full form from element attribute
			if ($preFirstWord == 1)
			{
				print $strCurrentTokens;
				$strCurrentTokens = "";
				$preFirstWord=0;
			}
			$word = $1;
			print $strCurrentTokens;
			$strCurrentTokens = "";
			$strTokenized = &tokenize($word);
			if ($noword == 1) {$subline =~ s/\n*<orig_group[^>]*>\n*//g; print $subline;
			}
			else{	print $subline ."\n";}
			
		}
		elsif ($subline eq "</orig_group>"){
			#bound group ends, flush tags and output resegmented tokens
				#search for morphemes to add

			$strPattern = ($strTokenized);
			@t = split(/\|/, $strTokenized);

			$strPattern =~ s/([\[\]\(\)])/\\$1/g;
			$strPattern =~ s/([^\\])/$1\#/g;
			$strPattern =~ s/\|/\)\(/g;
			$strPattern =~ s/#/(?:(?:[\\n̄︦︤︥̂`̣̇̂̅̈︤︥︦]|<[^>]+>)*)?/g; #allow intervening tags, linebreaks, and Coptic diacritics
			$strPattern =~ s/(.*)/(?<!\\")\($1\)/; #negative lookbehind prevents matching tokens within a quoted attribute in an SGML tag
			$count = () = $strTokenized =~ /\|/g; 
			if ($strCurrentTokens =~ /$strPattern/){
				if ($count==0) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n/;}
				elsif ($count==1) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[0]\">\n$1\n<\/orig>\n<orig orig=\"$t[1]\">\n$2\n<\/orig>\n/;}
				elsif ($count==2) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n/;}
				elsif ($count==3) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n/;}
				elsif ($count==4) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n<orig orig=\"$t[(5-1)]\">\n$5\n<\/orig>\n/;}
				elsif ($count==5) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n<orig orig=\"$t[(5-1)]\">\n$5\n<\/orig>\n<orig orig=\"$t[(6-1)]\">\n$6\n<\/orig>\n/;}
				elsif ($count==6) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n<orig orig=\"$t[(5-1)]\">\n$5\n<\/orig>\n<orig orig=\"$t[(6-1)]\">\n$6\n<\/orig>\n<orig orig=\"$t[(7-1)]\">\n$7\n<\/orig>\n/;}
				elsif ($count==7) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n<orig orig=\"$t[(5-1)]\">\n$5\n<\/orig>\n<orig orig=\"$t[(6-1)]\">\n$6\n<\/orig>\n<orig orig=\"$t[(7-1)]\">\n$7\n<\/orig>\n<orig orig=\"$t[(8-1)]\">\n$8\n<\/orig>\n/;}
				elsif ($count==8) {$strCurrentTokens =~ s/$strPattern/<orig orig=\"$t[(1-1)]\">\n$1\n<\/orig>\n<orig orig=\"$t[(2-1)]\">\n$2\n<\/orig>\n<orig orig=\"$t[(3-1)]\">\n$3\n<\/orig>\n<orig orig=\"$t[(4-1)]\">\n$4\n<\/orig>\n<orig orig=\"$t[(5-1)]\">\n$5\n<\/orig>\n<orig orig=\"$t[(6-1)]\">\n$6\n<\/orig>\n<orig orig=\"$t[(7-1)]\">\n$7\n<\/orig>\n<orig orig=\"$t[(8-1)]\">\n$8\n<\/orig>\n<orig orig=\"$t[(9-1)]\">\n$9\n<\/orig>\n/;}
			}
			else { 
				if  ($count==0) {
					$strCurrentTokens =  "<orig warning=\"no pattern match for token\">\n" . $strCurrentTokens . "\n</orig>\n"; #no match for pattern
				}
				else {
					$strTokenized =~ s/\|/\n<\/orig>\n<orig>\n/g;
					$strCurrentTokens = "<orig>\n" . $strTokenized . "\n<\/orig>\n";
				}
			}
			$strCurrentTokens =~ s/\n+/\n/g;
			if ($pipes == 1)
			{
				$strCurrentTokens =~ s/\n<\/orig>\n<orig[^>]*>\n/|/g;
				$strCurrentTokens =~ s/<\/?orig[^>]*>\n//g;
			}
			print $strCurrentTokens;
			$strCurrentTokens = "";
			if ($noword == 1) {$subline =~ s/\n*<\/?orig_group[^>]*>\n*//g;}
			print $subline ;
		}
		elsif ($subline =~ /<.*>/) {
			#other SGML tag, just save it
			$strCurrentTokens .= $subline ."\n";
		}
		else
		{
			#token
			$strCurrentTokens .= $subline ."\n";		
		}
	}
 

	sub tokenize{
	$strWord = $_[0];
	
	
	if ($strWord =~ /<.+>/)
	{
		$strWord =~ s/@/ /g;
		print "$strWord\n"; #XML tag
	}
	elsif ($strWord eq ""){ #do nothing
	}
		else
	{
		
		$dipl = $strWord;
		$strWord =~ s/(̈|%|̄|`|̅|̈|̂|︤|︥|︦)//g; 

		#remove supralinear strokes and other decorations for tokenization
		if ($strWord =~ /\|/) #pipes found, assume explicit tokenization is present
		{
			$dipl =~ s/\|//g;
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
			
			#adverbs
			elsif ($strWord =~ /^($advlist)$/){$strWord = $1;}
			
			#optative/conditional, make ppers a portmanteau segment with base
			elsif ($strWord =~ /^(ⲉ)($ppers)(ⲉ|ϣⲁⲛ)($verblist)$/) {$strWord = $1 . $2 . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉ)($ppers)(ⲉ|ϣⲁⲛ)($verblist)($nounlist)$/) {$strWord = $1 . $2 . $3 . "|" . $4."|" . $5;}
			
			
			#ⲧⲏⲣ=
			elsif ($strWord =~ /^(ⲧⲏⲣ)($ppero)$/){$strWord = $1 ."|" . $2;}

			#pure existential
			elsif ($strWord =~ /^(ⲟⲩⲛ|ⲙⲛ)($nounlist)$/) {$strWord = $1 . "|" . $2 ;}

			#prepositions
			elsif ($strWord =~ /^($pprep)($ppero)$/){$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^($nprep)($namelist)$/){$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^($nprep)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;} #experimentally allowing proper nouns with articles
			#elsif ($strWord =~ /^($nprep)($art|$ppos)ⲉ($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}

			#tripartite clause
			#pronominal
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($triprobase)($ppers)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			#proper name subject
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($trinbase)($namelist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ;}
			#prenominal
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^($trinbase)($art|$ppos)($nounlist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}

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
			#nominal subject - peje-prwme
			#elsif ($strWord =~ /^($vbdlist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			
			#bipartite clause
			#pronominal + future
			elsif ($strWord =~ /^($bibase)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2;}
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4;}
			elsif ($strWord =~ /^($bibase)(ⲛⲁ)($verblist)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3. "|".$4 . "|" . $5;}
			#nominal + future (+object)
			#elsif ($strWord =~ /^($art|$ppos)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}

			elsif ($strWord =~ /^($art|$ppos)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($art|$ppos)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 . "|".$5;}
			#indefinite + future
			elsif ($strWord =~ /^($exist)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4."|".$5;}
			
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
			#indefinite
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)($verblist|$vstatlist|$advlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}
			elsif ($strWord =~ /^(ⲉⲧ?|ⲛⲉ)($exist)($nounlist)(ⲛⲁ)($verblist)($ppero)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}

			#interlocutive nominal sentence
			elsif ($strWord =~ /^($pperinterloc)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2  . "|" . $3 ;}
			
			
			#simple NP - moved from before "relative generic NP p-et-o, ... " to account for preterite ne|u-sotm instead of possessive *neu-sotm with nominalized verb
			#if this causes trouble consider splitting ART and PPOS cases of simple NP
			elsif ($strWord =~ /^(ⲛϭⲓ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3;}
			elsif ($strWord =~ /^($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 ;}
			elsif ($strWord =~ /^(ⲛϭⲓ)($namelist)$/) {$strWord = $1 . "|" . $2 ;}

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
			###
			#prenominal
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)$/)   {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)$/)   {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4 ."|" . $5;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)($ppero)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}
			elsif ($strWord =~ /^(ⲉ?ⲛⲧ|ⲉ)(ⲁ|ⲛⲛⲉ)($art|$ppos)($nounlist)($verblist)($nounlist)$/)  {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|".$6;}
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($art|$ppos)($nounlist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5;}  #nominalized
			elsif ($strWord =~ /^($art)(ⲉⲛⲧ)(ⲁ)($art|$ppos)($nounlist)($verblist)$/) {$strWord = $1 . "|" . $2 . "|" . $3 . "|" . $4. "|" . $5. "|" . $6;}  #nominalized

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

			#negative imperative
			elsif ($strWord =~ /^(ⲙⲡⲣ)($verblist)$/) {$strWord = $1 . "|" . $2;}

			#tm preposed before subject in negative conjunctive with separated verb
			elsif ($strWord =~ /^(ⲛⲧⲉ)(ⲧⲙ)($nounlist)$/) {$strWord = $1 . "|" . $2. "|" . $3;}

			#else {			
			#nothing found
			#}	

		#split off negating TMs
		if ($strWord=~/\|ⲧⲙ(?!ⲁⲉⲓⲏⲩ|ⲁⲓⲏⲩ|ⲁⲓⲟ|ⲁⲓⲟⲕ|ⲙⲟ|ⲟ$)/) {$strWord =~ s/\|ⲧⲙ/|ⲧⲙ|/;}
				
		$strWord;
	}

}
}

sub preprocess{

	$rawline = $_[0];
	$rawline =~ s/([^< ]+) (?=[^<>]*>)/$1%/g;
	$rawline =~ s/(^| )([^ ]+)(?= |$)/$1 . '<orig_group%orig_group="' . &removexml($2) . '">' . $2 . "<\/orig_group>"/eg;
	$rawline =~ s/>/>\n/g;
	$rawline =~ s/</\n</g;
	$rawline =~ s/\n+/\n/g;
	$rawline =~ s/^\n//;
	$rawline =~ s/\n$//;
	$rawline =~ s/%/ /g;
	$rawline;
	
}

sub removexml{
	$input = $_[0];
	$input =~ s/<[^<>]+>//g;
	$input;
}



