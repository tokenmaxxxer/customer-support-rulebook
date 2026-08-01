# Shared local helper for the customer-support-*-gate.sh scripts' semantic
# checks (issue-13 §4): section-scoped and adjacency-scoped field matching,
# replacing the whole-document substring grep every gate used before this
# migration. This is NOT part of core's gate-lib.sh/.py — issue-13's
# scout-brief.md confirmed gate-lib does not cover section/adjacency
# matching, so this is this rulebook's own design, kept local and shared
# across gates only because more than two gates need the identical slice
# logic (issue-13 proposal §4).
#
# Loaded the same way a gate loads GATE_LIB_PY: via importlib against a
# fixed path, never a dotted import.

import re


def section_slices(content, heading_pattern):
    """Split `content` on markdown '#'-heading boundaries and return the
    list of (heading_line, slice_text) pairs whose heading line matches
    `heading_pattern` (case-insensitive). `slice_text` runs from just after
    the matching heading to the next heading at the same-or-shallower
    level, or end of document.
    """
    lines = content.splitlines()
    heading_re = re.compile(r'^(#{1,6})\s+(.*)$')
    headings = []  # (line_index, level, text)
    for i, line in enumerate(lines):
        m = heading_re.match(line)
        if m:
            headings.append((i, len(m.group(1)), m.group(2)))

    results = []
    for idx, (line_i, level, text) in enumerate(headings):
        if not re.search(heading_pattern, text, re.IGNORECASE):
            continue
        end = len(lines)
        for (later_i, later_level, _t) in headings[idx + 1:]:
            if later_level <= level:
                end = later_i
                break
        results.append((lines[line_i], "\n".join(lines[line_i + 1:end])))
    return results


def table_header_slice(content):
    """Return the header row + separator row of the first markdown table
    found in `content` (lines containing '|'), or "" if none. Used for
    column-presence checks that must look at the header row specifically,
    not anywhere in the document.
    """
    lines = content.splitlines()
    for i, line in enumerate(lines):
        if '|' in line:
            header = line
            sep = lines[i + 1] if i + 1 < len(lines) else ""
            if re.search(r'^\s*\|?[\s:|-]+\|?\s*$', sep):
                return header + "\n" + sep
            return header
    return ""


def section_has(content, heading_pattern, field_pattern):
    """True if any section whose heading matches `heading_pattern` has a
    non-empty slice containing `field_pattern`. If no matching heading
    exists at all, falls back to False (caller decides whether "no
    section" itself is a failure).
    """
    slices = section_slices(content, heading_pattern)
    if not slices:
        return False
    for _heading, slice_text in slices:
        if re.search(field_pattern, slice_text, re.IGNORECASE):
            return True
    return False


def any_section_matched(content, heading_pattern):
    return len(section_slices(content, heading_pattern)) > 0


def adjacency_ok(content, keyword_pattern, citation_pattern, window=3):
    """True if some line matching `keyword_pattern` has `citation_pattern`
    within its own paragraph (blank-line-delimited block), falling back to
    a +/-`window`-line scan when that paragraph exceeds 20 lines.
    """
    lines = content.splitlines()
    keyword_re = re.compile(keyword_pattern, re.IGNORECASE)
    citation_re = re.compile(citation_pattern, re.IGNORECASE)

    # paragraph boundaries: blank lines split paragraphs
    paras = []
    start = 0
    for i, line in enumerate(lines):
        if line.strip() == "":
            if i > start:
                paras.append((start, i))
            start = i + 1
    if start < len(lines):
        paras.append((start, len(lines)))

    for i, line in enumerate(lines):
        if not keyword_re.search(line):
            continue
        para = next(((s, e) for (s, e) in paras if s <= i < e), None)
        if para and (para[1] - para[0]) <= 20:
            block = lines[para[0]:para[1]]
        else:
            lo, hi = max(0, i - window), min(len(lines), i + window + 1)
            block = lines[lo:hi]
        if any(citation_re.search(b) for b in block):
            return True
    return False
