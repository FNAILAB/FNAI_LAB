#!/usr/bin/env perl
# FNAI LAB website checker. Run from the repository root:
#   perl .claude/scripts/check-site.pl
# Exits 0 when the site looks safe to publish, 1 when something is broken.
# Read-only: it never changes files.
use strict;
use warnings;

my @errors;
my @warnings;
my %pages = map { $_ => 1 } qw(index.html team.html events.html research.html
                              publications.html activities.html media.html join.html);

# Every page must exist.
for my $p (sort keys %pages) {
    push @errors, "$p is missing" unless -f $p;
}

my %versions;    # "style.css?v=X" / "script.js?v=X" values seen across pages
my %html;
for my $p (sort keys %pages) {
    next unless -f $p;
    open my $fh, '<:raw', $p or do { push @errors, "cannot read $p"; next };
    local $/;
    my $t = <$fh>;
    close $fh;
    $html{$p} = $t;

    # 1. Open/close tag balance for the structural tags the skills touch.
    for my $tag (qw(div article section ul ol figure main nav header footer)) {
        my $open  = () = $t =~ /<$tag[\s>]/gi;
        my $close = () = $t =~ /<\/$tag>/gi;
        push @errors, "$p: <$tag> opened $open times but closed $close times"
            if $open != $close;
    }
    for my $tag (qw(html head body)) {
        my $open  = () = $t =~ /<$tag[\s>]/gi;
        my $close = () = $t =~ /<\/$tag>/gi;
        push @errors, "$p: expected exactly one <$tag> ... </$tag>"
            unless $open == 1 && $close == 1;
    }

    # 2. Every local file the page points to must exist.
    while ($t =~ /\b(?:src|href)="([^"]+)"/g) {
        my $ref = $1;
        next if $ref =~ m{^(?:https?:|mailto:|tel:|#|data:|//)}i;
        (my $path = $ref) =~ s/[?#].*$//;
        next if $path eq '';
        push @errors, "$p: links to \"$ref\" but $path does not exist" unless -e $path;
    }

    # 3. Cache-busting version tags.
    for my $asset (qw(style.css script.js)) {
        my @found = $t =~ /\Q$asset\E(\?v=[^"]*)?"/g;
        if (!@found) {
            push @errors, "$p: does not load $asset";
            next;
        }
        for my $v (@found) {
            if (!defined $v || $v eq '') {
                push @errors, "$p: loads $asset without a ?v= version tag";
            } else {
                $versions{"$asset$v"}{$p} = 1;
            }
        }
    }

    # 4. Leftover template placeholders.
    for my $ph ('TODO', 'FIXME', '{{', '}}', '[NAME]', '[TITLE]', '<NAME>', 'YYYY.', 'XXXX') {
        push @errors, "$p: contains leftover placeholder \"$ph\"" if index($t, $ph) >= 0;
    }

    # 5. Carousels must have a track with at least one image, and the (i/n) labels must add up.
    my $car = 0;
    while ($t =~ /<div class="carousel[^"]*"[^>]*data-carousel[^>]*>\s*<div class="carousel-track">(.*?)<\/div>\s*<\/div>/gs) {
        $car++;
        my $track = $1;
        my @imgs  = $track =~ /<img\b[^>]*>/g;
        if (!@imgs) { push @errors, "$p: carousel #$car has no images"; next; }
        my $n = scalar @imgs;
        my $i = 0;
        for my $img (@imgs) {
            $i++;
            if ($img =~ /alt="[^"]*\((\d+)\/(\d+)\)"/) {
                push @errors, "$p: carousel #$car photo $i is labelled ($1/$2), expected ($i/$n)"
                    if $1 != $i || $2 != $n;
            }
            push @errors, "$p: carousel #$car photo $i has no alt text" unless $img =~ /alt="[^"]+"/;
        }
    }
    my $carDecl = () = $t =~ /data-carousel/g;
    push @errors, "$p: found $carDecl carousels but only $car are well-formed (missing carousel-track?)"
        if $carDecl != $car;
}

# Leftover git conflict markers (an unfinished merge/rebase) must never be published.
for my $f ((sort keys %pages), qw(style.css brand.css script.js)) {
    next unless -f $f;
    open my $fh, '<:raw', $f or next;
    my $n = 0;
    while (my $l = <$fh>) {
        $n++;
        push @errors, "$f line $n: git conflict marker \"" . substr($l, 0, 7) . "\" - finish resolving the conflict first"
            if $l =~ /^(?:<{7}|={7}|>{7}|\|{7})(?:\s|$)/;
    }
    close $fh;
}

# Version tags must be identical on every page.
my %distinct;
for my $k (keys %versions) { (my $v = $k) =~ s/^.*\?v=//; $distinct{$v} = 1; }
if (keys %distinct > 1) {
    push @errors, "pages use different version tags: " . join(', ', sort keys %distinct)
        . " (run: perl .claude/scripts/bump-version.pl)";
}

# Page-specific checks.
if (my $t = $html{'team.html'}) {
    my %seen;
    for my $slug ($t =~ /data-photo="([^"]+)"/g) {
        push @errors, "team.html: data-photo=\"$slug\" is used twice" if $seen{$slug}++;
        push @errors, "team.html: data-photo=\"$slug\" must be lowercase letters, digits and hyphens"
            unless $slug =~ /^[a-z0-9]+(?:-[a-z0-9]+)*$/;
        my @files = grep { -f } map { "assets/team/$slug.$_" } qw(jpg jpeg png webp JPG PNG);
        push @warnings, "team.html: no photo file for $slug (the grey placeholder will show)" unless @files;
    }
    for my $id (qw(pi graduate undergraduate affiliated alumni past)) {
        push @errors, "team.html: section id=\"$id\" is missing" unless $t =~ /id="$id"/;
    }
}
if (my $t = $html{'publications.html'}) {
    for my $h ('In Press', 'International Journal', 'International Conference') {
        push @errors, "publications.html: section \"$h\" is missing"
            unless $t =~ /<div class="pub-group"><h2>\Q$h\E<\/h2><ul class="pub-list">/;
    }
}
if (my $t = $html{'index.html'}) {
    push @errors, "index.html: News list (<div class=\"news-list\">) is missing" unless $t =~ /<div class="news-list">/;
}
if (my $t = $html{'events.html'}) {
    push @errors, "events.html: event grid (<div class=\"event-grid\">) is missing" unless $t =~ /<div class="event-grid">/;
}

# Image files: nothing huge, nothing the browser cannot show.
if (opendir my $dh, 'assets') {
    my @dirs = ('assets');
    while (my $d = shift @dirs) {
        opendir my $h, $d or next;
        for my $f (readdir $h) {
            next if $f =~ /^\./;
            my $path = "$d/$f";
            if (-d $path) { push @dirs, $path; next; }
            my $size = -s $path;
            push @errors, "$path is " . int($size / 1024) . " KB; resize it below 1 MB (see .claude/scripts/resize-image.ps1)"
                if $size > 1024 * 1024 && $f =~ /\.(jpe?g|png|webp)$/i;
            push @errors, "$path: .$1 photos do not display in most browsers; convert to .jpg"
                if $f =~ /\.(heic|heif|tiff?)$/i;
        }
        closedir $h;
    }
}

for (@warnings) { print "WARNING: $_\n"; }
if (@errors) {
    print "ERROR: $_\n" for @errors;
    print "\nSITE CHECK FAILED (" . scalar(@errors) . " problem(s)). Do not commit or push until these are fixed.\n";
    exit 1;
}
my ($v) = keys %distinct;
print "SITE CHECK PASSED. Version tag: " . ($v // 'none') . "\n";
exit 0;
