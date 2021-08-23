#!/usr/bin/env python3
from html.parser import HTMLParser
import sys
import re

class HTMLTableParser(HTMLParser):
    def __init__(self, row_delim="\n", cell_delim=","):
        HTMLParser.__init__(self)
        self.despace_re = re.compile("\s+")
        self.data_interrupt = False
        self.first_row = True
        self.first_cell = True
        self.in_cell = False
        self.row_delim = row_delim
        self.cell_delim = cell_delim
        self.quote_buffer = False
        self.buffer = None

    def handle_starttag(self, tag, attrs):
        self.data_interrupt = True
        if tag == "table":
            self.first_row = True
            self.first_cell = True
        elif tag == "tr":
            if not self.first_row:
                sys.stdout.write(self.row_delim)
            self.first_row = False
            self.first_cell = True
            self.data_interrupt = False
        elif tag == "td" or tag == "th":
            if not self.first_cell:
                sys.stdout.write(self.cell_delim)
            self.first_cell = False
            self.data_interrupt = False
            self.in_cell = True
        elif tag == "br":
            self.quote_buffer = True
            self.buffer += self.row_delim

    def handle_endtag(self, tag):
        self.data_interrupt = True
        if tag == "td" or tag == "th":
            self.in_cell = False
        if self.buffer != None:
            # Quote if needed...
            if self.quote_buffer or self.cell_delim in self.buffer or "\"" in self.buffer:
                # Need to quote! First, replace all double-quotes with quad-quotes
                self.buffer = self.buffer.replace("\"", "\"\"")
                self.buffer = "\"{0}\"".format(self.buffer)
            sys.stdout.write(self.buffer)
            self.quote_buffer = False
            self.buffer = None

    def handle_data(self, data):
        if self.in_cell:
            #if self.data_interrupt:
            #   sys.stdout.write(" ")
            if self.buffer == None:
                self.buffer = ""
            self.buffer += self.despace_re.sub(" ", data).strip()
            self.data_interrupt = False

parser = HTMLTableParser()
parser.feed(sys.stdin.read())
