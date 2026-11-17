#!/usr/bin/env perl
# After `git pull --rebase` (or a merge) stops with conflicts, resolve ONLY the conflicts where the two sides differ
# in nothing but the ?v= version tag. Every other conflict is left untouched for a human to decide.
# Run from the repository root:  perl .claude/scripts/resolve-version-conflicts.pl
# Exit 0: all conflicts were version-tag-only and are resolved (files are `git add`-ed).
#         Next: see step 9 in CLAUDE.md (bump version, site check, git add -A, rebase --continue, push).
# Exit 1: some conflicts are real content conflicts - STOP and ask the user (`git rebase --abort` undoes the pull).
use strict;
use warnings;

my @files = grep { length } split /\n/, `git diff --name-only --diff-filter=U`;
die "git diff failed\n" if $?;
if (!@files) { print "No conflicted files.\n"; exit 0; }

my ($fixed, $left) = (0, 0);
my @unresolved_files;
for my $f (@files) {
    open my $in, '<:raw', $f or die "cannot read $f\n";
    my @lines = <$in>;
    close $in;

    my @out;
    my $file_left = 0;
    my $i = 0;
    while ($i < @lines) {
        if ($lines[$i] !~ /^<<<<<<< /) { push @out, $lines[$i++]; next; }
        my $start = $i++;
        my (@ours, @base, @theirs);
        my $part = 'ours';
        my $end;
        for (; $i < @lines; $i++) {
            my $l = $lines[$i];
            if ($l =~ /^\|\|\|\|\|\|\| /)   { $part = 'base'; next; }
            if ($l =~ /^=======\r?$/)        { $part = 'theirs'; next; }
            if ($l =~ /^>>>>>>> /)           { $end = $i; last; }
            push @{ $part eq 'ours' ? \@ours : $part eq 'base' ? \@base : \@theirs }, $l;
        }
        die "$f: unterminated conflict block starting at line " . ($start + 1) . "\n" unless defined $end;
        my $norm = sub { my $t = join '', @_; $t =~ s/\?v=[0-9A-Za-z]+/?v=TAG/g; $t =~ s/\r\n/\n/g; $t };
        if ($norm->(@ours) eq $norm->(@theirs)) {
            # Identical apart from the version tag: keep the side with the NEWER tag (tags are YYYYMMDD + letter,
            # so they sort as text), so the next bump-version.pl always produces a tag nobody has published yet.
            my $maxtag = sub { my @t = sort ((join '', @_) =~ /\?v=([0-9A-Za-z]+)/g); @t ? $t[-1] : '' };
            push @out, ($maxtag->(@ours) gt $maxtag->(@theirs)) ? @ours : @theirs;
            $fixed++;
        } else {
            push @out, @lines[$start .. $end];   # real conflict: keep the markers untouched
            $file_left++;
        }
        $i = $end + 1;
    }

    open my $outfh, '>:raw', $f or die "cannot write $f\n";
    print $outfh @out;
    close $outfh;
    if ($file_left) {
        $left += $file_left;
        push @unresolved_files, $f;
    } else {
        system('git', 'add', '--', $f) == 0 or die "git add $f failed\n";
    }
}

print "Resolved $fixed version-tag-only conflict(s).\n";
if ($left) {
    print "NOT resolved: $left real conflict(s) in: @unresolved_files\n";
    print "STOP: show these to the user and ask how to proceed (`git rebase --abort` or `git merge --abort` undoes it).\n";
    exit 1;
}
print "All conflicts resolved. Next: see step 9 in CLAUDE.md (bump version, site check, git add -A, rebase --continue, push).\n";
exit 0;
