#!/usr/bin/env python

"""
 Author: Saophalkun Ponlu (http://phalkunz.com)
 Contact: phalkunz@gmail.com
 Date: May 23, 2009
 Modified: June 15, 2009
 
 Additional modifications:
 Author: Phil Christensen (http://bubblehouse.org)
 Contact: phil@bubblehouse.org
 Date: February 22, 2010
"""

import sys, subprocess

colorizedSubcommands = (
	'status',
	'stat',
	'st',
	'add',
	'remove',
	#'diff',
	#'di',
)

statusColors = {
    'M'     : "31",     # red 
    '?'    : "37",     # grey
    'A'     : "32",     # green
    'X'     : "33",     # yellow
    'C'     : "30;41",  # black on red
    '-'     : "31",     # red
    'D'     : "31;1",   # bold red
    '+'    : "32",     # green
}

def colorize(line):
    for status in statusColors:
        if line.startswith(status):
            return ''.join(("\033[", statusColors[status], "m", line, "\033[m"))
    else:
        return line

if __name__ == '__main__':
    command = sys.argv

    if len(command) > 1:
        subcommand = (command[1], '')[len(command) < 2]
    else:
        subcommand = ''
    if subcommand in colorizedSubcommands:
        while True:
            line = sys.stdin.readline()
            if not line:
                break
            #if sys.stdout.isatty():
            sys.stdout.write(colorize(line))
            #else:
            #    sys.stdout.write(line)
    else:
        while True:
            line = sys.stdin.readline()
            if not line:
                break
            sys.stdout.write(line)
    sys.stdout.flush()
    sys.exit(0)
