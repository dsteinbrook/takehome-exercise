#!/usr/bin/env python3
"""
Parse a large Facebook chat export HTML file to extract unique authors
and the page numbers where each appears.

Streams the file line-by-line to handle multi-GB inputs without
loading everything into memory. Does not use lxml.
"""

import argparse
import re
import sys
import time
from collections import defaultdict

DATA_FILE = "data/huge_chat_export.html"
OUTPUT_FILE = "output.txt"

PAGE_RE = re.compile(
    r"Page\s+(?:Numbers[\s:]+)?(\d+)", re.IGNORECASE
)

AUTHOR_DIV_RE = re.compile(
    r'>Author<div class="m"><div>\s*(.*?)\s*\(Facebook:\s*(\d+)\)'
)
AUTHOR_MSG_RE = re.compile(
    r'class="author">\s*(.*?)\s*\(Facebook:\s*(\d+)\)'
)
AUTHOR_COMMENT_RE = re.compile(
    r"<!--\s*Author:\s*(.*?)\s*\(Facebook:\s*(\d+)\)\s*-->"
)
AUTHOR_SPAN_RE = re.compile(
    r"Message from\s+(.*?)\s*\(Facebook:\s*(\d+)\)"
)


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "-n", "--max-lines", type=int, default=None,
        help="Stop after reading this many lines (default: read entire file)",
    )
    args = parser.parse_args()

    authors: dict[tuple[str, str], set[int]] = defaultdict(set)
    current_page: int | None = None
    lines_processed = 0
    t0 = time.time()

    with open(DATA_FILE, encoding="utf-8") as f:
        for line in f:
            lines_processed += 1
            if args.max_lines is not None and lines_processed > args.max_lines:
                break
            if lines_processed % 10_000_000 == 0:
                elapsed = time.time() - t0
                print(
                    f"  {lines_processed / 1e6:.0f}M lines  "
                    f"({elapsed:.1f}s elapsed, "
                    f"{len(authors):,} unique authors so far)",
                    file=sys.stderr,
                )

            lower = line.lower()
            if "page" in lower and ("numbers" in lower or ">page " in lower):
                m = PAGE_RE.search(line)
                if m:
                    current_page = int(m.group(1))

            if current_page is not None and "Facebook:" in line:
                for pattern in (AUTHOR_DIV_RE, AUTHOR_MSG_RE, AUTHOR_COMMENT_RE, AUTHOR_SPAN_RE):
                    for name, fb_id in pattern.findall(line):
                        name = name.strip()
                        if name:
                            authors[(name, fb_id)].add(current_page)

    elapsed = time.time() - t0
    sorted_authors = sorted(
        authors.items(), key=lambda item: (item[0][0].lower(), item[0][1])
    )

    with open(OUTPUT_FILE, "w", encoding="utf-8") as out:
        for (name, fb_id), pages in sorted_authors:
            page_str = ", ".join(str(p) for p in sorted(pages))
            line = f"Author: {name} (Facebook: {fb_id})   Pages: {page_str}"
            print(line)
            out.write(line + "\n")

    print(
        f"\nTotal unique authors: {len(authors):,}",
        file=sys.stderr,
    )
    print(f"Processed {lines_processed:,} lines in {elapsed:.1f}s", file=sys.stderr)
    print(f"Results written to {OUTPUT_FILE}", file=sys.stderr)


if __name__ == "__main__":
    main()
