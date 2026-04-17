#!/usr/bin/env bash
# Investigate author and page number format variations in the HTML export.
# All commands are read-only; nothing is modified.

set -u

DATA="data/huge_chat_export.html"

echo "=== File size and line count ==="
wc -l "$DATA"
du -h "$DATA"

echo ""
echo "========================================"
echo "=== PAGE NUMBER FORMAT INVESTIGATION ==="
echo "========================================"

echo ""
echo "-- Count: 'Page Numbers' (exact case, any suffix):"
rg -c 'Page Numbers' "$DATA" || echo "0"

echo "-- Count: 'page numbers' (case-insensitive):"
rg -c -i 'page numbers' "$DATA" || echo "0"

echo "-- Count: lowercase 'page numbers' only:"
rg -c 'page numbers' "$DATA" || echo "0"

echo "-- Count: 'Page Numbers:' (with colon):"
rg -c 'Page Numbers:' "$DATA" || echo "0"

echo "-- Count: '>Page N<' (no 'Numbers' word):"
rg -c '>Page \d' "$DATA" || echo "0"

echo "-- Sample: lowercase page number lines:"
rg 'page numbers' "$DATA" | head -5

echo "-- Sample: 'Page Numbers:' (with colon):"
rg 'Page Numbers:' "$DATA" | head -5

echo "-- Sample: '>Page N<' (no 'Numbers'):"
rg '>Page \d' "$DATA" | head -5

echo "-- All distinct page-number line formats (up to 40 samples):"
rg -i -m 40 'page\s+\d' "$DATA" | sort -u

echo ""
echo "-- Check: any alt page abbreviations (pg, pp, page:, p.) ?"
rg -i -m 5 '(pg\.|\bpp\.|\bpage:|\bp\.\s*\d)' "$DATA" || echo "(none found)"

echo "-- Check: non-English page markers?"
rg -i -m 5 '(seite|página|página|страниц|页|ページ)' "$DATA" || echo "(none found)"

echo ""
echo "========================================"
echo "=== AUTHOR FORMAT INVESTIGATION ======="
echo "========================================"

echo ""
echo "-- Pattern 1: >Author<div class=\"m\"><div> :"
rg -c '>Author<div' "$DATA" || echo "0"

echo "-- Pattern 2: class=\"author\"> :"
rg -c 'class="author"' "$DATA" || echo "0"

echo "-- Pattern 3: <!--Author: (HTML comments) :"
rg -c '<!--.*Author' "$DATA" || echo "0"

echo "-- Pattern 4: Message from ... (Facebook:) :"
rg -c 'Message from.*Facebook:' "$DATA" || echo "0"

echo "-- Current Participants (non-message author header):"
rg -c 'Current Participants' "$DATA" || echo "0"

echo "-- Total lines with 'Facebook:' :"
rg -c 'Facebook:' "$DATA" || echo "0"

echo ""
echo "-- Sanity check: case variations of 'author':"
echo "   Case-insensitive 'author': $(rg -ic 'author' "$DATA")"
echo "   Exact 'Author':            $(rg -c 'Author' "$DATA")"
echo "   Lowercase 'author':        $(rg -c 'author' "$DATA")"

echo ""
echo "-- Sanity check: case variations of 'facebook:':"
echo "   Case-insensitive: $(rg -ic 'facebook:' "$DATA")"
echo "   Exact 'Facebook:': $(rg -c 'Facebook:' "$DATA")"

echo ""
echo "-- Check: any alt Facebook shorthand (FB:, Fb:, fb:)?"
rg -m 5 '(\bFB:|\bFb:|\bfb:)' "$DATA" || echo "(none found)"

echo ""
echo "-- Facebook ID length distribution (should all be same length):"
rg -o 'Facebook:\s*\d+' "$DATA" | rg -o '\d+' | awk '{ print length($0) }' | sort | uniq -c

echo ""
echo "-- Completeness: 'Facebook:' lines NOT matching any known author pattern:"
rg 'Facebook:' "$DATA" \
  | rg -v '(>Author<div class="m"><div>|class="author">|<!--.*Author|Message from|Current Participants)' \
  | head -20
echo "(Empty output above means every Facebook: line is accounted for)"

echo ""
echo "-- Check: any other author-like attribution patterns?"
rg -i -m 5 '(sent by|posted by|written by|from:).*Facebook:' "$DATA" || echo "(none found)"
rg -m 5 '(data-author|data-sender|data-user|data-fbid)' "$DATA" || echo "(none found)"

echo ""
echo "-- Check: HTML entities that might affect parsing?"
rg -m 5 '(&amp;|&nbsp;|&quot;|&#)' "$DATA" || echo "(none found)"

echo ""
echo "-- Unique 'Message from ...' variations (first 20):"
rg 'Message from.*Facebook:' "$DATA" | sort -u | head -20

echo ""
echo "========================================"
echo "=== 15-DIGIT ID SWEEP ================="
echo "========================================"
echo "Find every isolated 15-digit number in the file and see whether any"
echo "appear in contexts OTHER than 'Facebook: <id>'. If the counts match,"
echo "there are no hidden IDs in unexpected formats."
echo ""

echo "-- Count of all isolated 15-digit numbers in file:"
rg -o --pcre2 '(?<!\d)\d{15}(?!\d)' "$DATA" | wc -l

echo "-- Count of '(Facebook: <15 digits>)':"
rg -c 'Facebook:\s*\d{15}' "$DATA" || echo "0"

echo "(The two counts above must match.)"
echo ""

echo "-- Any line containing a 15-digit id but NOT the string 'Facebook:' ?"
rg --pcre2 '(?<!\d)\d{15}(?!\d)' "$DATA" | rg -v 'Facebook:' | head -10
echo "(Empty output means every 15-digit id is paired with 'Facebook:')"

echo ""
echo "-- Count of UNIQUE line templates (id digits masked) that contain a 15-digit id:"
rg --pcre2 '(?<!\d)\d{15}(?!\d)' "$DATA" \
  | sed -E 's/[0-9]{15}/<ID>/g' \
  | sort -u \
  | wc -l

echo ""
echo "-- Unique line templates NOT matching any of the 4 known author patterns:"
echo "   (any non-empty output here is a new author/context format to handle)"
rg --pcre2 '(?<!\d)\d{15}(?!\d)' "$DATA" \
  | sed -E 's/[0-9]{15}/<ID>/g' \
  | sort -u \
  | rg -v '(>Author<div class="m"><div>|class="author">|<!--.*Author|Message from)'
echo "(The 2 Current Participants lines are expected to appear here — they are"
echo " the chat metadata header, not page-scoped messages.)"

echo ""
echo "-- Sample of all line templates that contain a 15-digit id (first 30):"
rg --pcre2 '(?<!\d)\d{15}(?!\d)' "$DATA" \
  | sed -E 's/[0-9]{15}/<ID>/g' \
  | sort -u \
  | head -30

echo ""
echo "-- Non-15-digit number lengths that look id-like (10-14 and 16-25 digits):"
for len in 10 11 12 13 14 16 17 18 19 20 21 22 23 24 25; do
  count=$(rg -c --pcre2 "(?<!\d)\d{$len}(?!\d)" "$DATA" || echo 0)
  if [ "$count" != "0" ] && [ -n "$count" ]; then
    echo "  ${len}-digit: $count line(s)"
    rg --pcre2 "(?<!\d)\d{$len}(?!\d)" "$DATA" | head -1
  fi
done

echo ""
echo "-- Check: any IDs with separators (hyphens/spaces between digit groups)?"
rg -m 5 --pcre2 '\d{3,}[-\s]\d{3,}[-\s]\d{3,}' "$DATA" || echo "(none found)"

echo ""
echo "-- Check: any IDs inside HTML attributes (id=, data-*=)?"
rg -m 5 '(id="\d|data-[a-z]+="\d)' "$DATA" || echo "(none found)"

echo ""
echo "========================================"
echo "=== NAME-NEAR-ID CROSS-CHECK ========="
echo "========================================"
echo "For every 15-digit id, show the word/token immediately before it."
echo "If all matches look like '(Facebook:' / 'Facebook:', no new format exists."
echo ""

rg -o --pcre2 '\S{1,40}\s\(?Facebook:\s*\d{15}\)?' "$DATA" 2>/dev/null \
  | awk '{ print $1 }' \
  | sort -u \
  | head -20 \
  || echo "(rg PCRE not available; skipping)"

echo ""
echo "========================================"
echo "Investigation complete."
echo "========================================"
