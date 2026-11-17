#!/usr/bin/env perl
# Give style.css and script.js a new ?v= tag on every page, so visitors' browsers
# download the new files instead of showing a cached old copy.
# Run from the repository root:  perl .claude/scripts/bump-version.pl
# New tag = today's date (YYYYMMDD); if today's date is already used, the next letter is added (b, c, ...).
use strict;
use warnings;

my @pages = qw(index.html team.html events.html research.html
               publications.html activities.html media.html join.html);

my ($d, $m, $y) = (localtime)[3, 4, 5];
my $today = sprintf '%04d%02d%02d', $y + 1900, $m + 1, $d;

# Find the current tag (from index.html).
open my $fh, '<:raw', 'index.html' or die "Run this from the website folder (index.html not found)\n";
my $index = do { local $/; <$fh> };
close $fh;
my ($current) = $index =~ /style\.css\?v=([0-9a-z]+)"/;
$current //= '';

my $new;
if ($current =~ /^\Q$today\E([a-y]?)$/) {
    my $letter = $1 eq '' ? 'b' : chr(ord($1) + 1);
    $new = $today . $letter;
} else {
    $new = $today;
}

my $changed = 0;
for my $p (@pages) {
    open my $in, '<:raw', $p or die "cannot read $p\n";
    my $t = do { local $/; <$in> };
    close $in;
    my $n = 0;
    $n += ($t =~ s/(\b(?:style\.css|script\.js))(?:\?v=[^"]*)?"/$1?v=$new"/g);
    die "$p: no style.css/script.js link found - stopping without changes to the remaining pages\n" unless $n;
    open my $out, '>:raw', $p or die "cannot write $p\n";
    print $out $t;
    close $out;
    $changed += $n;
}
print "Version tag: " . ($current || '(none)') . " -> $new ($changed links updated)\n";
