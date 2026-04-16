#!/usr/bin/env python3
"""
fix_bookmark_ids.py — Fix duplicate w:id attributes in docx-js generated .docx files.

docx-js assigns id="1" to all bookmarks. Word requires unique IDs.
This script reads the XML, reassigns IDs sequentially, and rewrites the file.

Usage:
  python3 fix_bookmark_ids.py output.docx
"""

import sys
import zipfile
import shutil
import re
import os

def fix(path):
    tmp = path + '.tmp'
    shutil.copy(path, tmp)

    with zipfile.ZipFile(tmp, 'r') as z:
        xml = z.read('word/document.xml').decode('utf-8')

    counter = [0]
    def next_id(m):
        counter[0] += 1
        return m.group(1) + str(counter[0]) + m.group(3)

    xml = re.sub(r'(w:id=\")(\d+)(\")', next_id, xml)

    with zipfile.ZipFile(tmp, 'r') as zin:
        with zipfile.ZipFile(path, 'w', zipfile.ZIP_DEFLATED) as zout:
            for item in zin.infolist():
                if item.filename == 'word/document.xml':
                    zout.writestr(item, xml.encode('utf-8'))
                else:
                    zout.writestr(item, zin.read(item.filename))

    os.remove(tmp)
    print(f"✓ Bookmark IDs fixed: {path}")

if __name__ == '__main__':
    fix(sys.argv[1])
