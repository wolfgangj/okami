#!/usr/bin/awk -f
# ok-il2-to-arm.awk - convert okami IL2 to ARM assembly
# Copyright (C) 2018 Wolfgang Jaehrling
#
# ISC License
#
# Permission to use, copy, modify, and/or distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

function isreg(x) { return x ~ /^r[0-9]$/ }
function isnum(x) { return x ~ /^[0-9]+$/ }

function err(msg) {
    printf("%d: %s\n", line, msg) >>"/dev/stderr"
    exit 1
}

function alu(op, reg, arg) {
    print op " " reg ", " reg ", " arg
}

BEGIN {
    line = 0

    print ".macro load_addr reg, addr"
    print "  movw \\reg, #:lower16:\\addr"
    print "  movt \\reg, #:upper16:\\addr"
    print ".endm"
}

{ line = line + 1 }

$1 == "mov.r" && isreg($2) && isreg($3) { print "mov " $2 ", " $3; next; }
$1 == "add.r" && isreg($2) && isreg($3) { alu("add", $2, $3); next; }
$1 == "sub.r" && isreg($2) && isreg($3) { alu("sub", $2, $3); next; }
$1 == "and.r" && isreg($2) && isreg($3) { alu("and", $2, $3); next; }
$1 == "or.r"  && isreg($2) && isreg($3) { alu("orr", $2, $3); next; }
$1 == "xor.r" && isreg($2) && isreg($3) { alu("xor", $2, $3); next; }

$1 == "mov.i" && isreg($2) && isnum($3) { print "mov " $2 ", #" $3; next; }
$1 == "add.i" && isreg($2) && isnum($3) { alu("add", $2, "#" $3); next; }
$1 == "sub.i" && isreg($2) && isnum($3) { alu("sub", $2, "#" $3); next; }
$1 == "and.i" && isreg($2) && isnum($3) { alu("and", $2, "#" $3); next; }
$1 == "or.i"  && isreg($2) && isnum($3) { alu("orr", $2, "#" $3); next; }
$1 == "xor.i" && isreg($2) && isnum($3) { alu("xor", $2, "#" $3); next; }

/^$/ { next }
/^;/ { next }
{ err("syntax error") }
