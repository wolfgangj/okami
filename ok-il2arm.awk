#!/usr/bin/awk -f
# ok-il2arm.awk - convert okami IL2 to ARM assembly
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
function islabel(x)    { return x ~ /^[a-zA-Z_][a-zA-Z0-9_]+$/ }
function islabeldef(x) { return x ~ /^[a-zA-Z_][a-zA-Z0-9_]+:$/ }

function err(msg) {
    printf("%d: %s\n", line, msg) >>"/dev/stderr"
    exit 1
}

function alu(op, reg, arg) {
    print op " " reg ", " reg ", " arg
}

function cond(c, reg, arg, label) {
    print "cmp " reg ", " arg
    print "b" c " "  label
}

BEGIN {
    line = 0

    print ".macro mov_full reg, val"
    print "  movw \\reg, #:lower16:\\val"
    print "  movt \\reg, #:upper16:\\val"
    print ".endm"
}

{ line = line + 1 }

islabeldef($1) { print $1; next }

$1 == "mov.r" && isreg($2) && isreg($3) { print "mov " $2 ", " $3; next }
$1 == "add.r" && isreg($2) && isreg($3) { alu("add", $2, $3); next }
$1 == "sub.r" && isreg($2) && isreg($3) { alu("sub", $2, $3); next }
$1 == "and.r" && isreg($2) && isreg($3) { alu("and", $2, $3); next }
$1 == "or.r"  && isreg($2) && isreg($3) { alu("orr", $2, $3); next }
$1 == "xor.r" && isreg($2) && isreg($3) { alu("xor", $2, $3); next }

$1 == "mov.i" && isreg($2) && isnum($3) {
    if($3 < 65536) {
        print "mov " $2 ", #" $3
    } else {
        print "mov_full " $2 ", #" $3
    }
    next
}
$1 == "mov.a" && isreg($2) && islabel($3) {
    print "mov_full " $2 ", " $3
    next
}
$1 == "add.i" && isreg($2) && isnum($3) { alu("add", $2, "#" $3); next }
$1 == "sub.i" && isreg($2) && isnum($3) { alu("sub", $2, "#" $3); next }
$1 == "and.i" && isreg($2) && isnum($3) { alu("and", $2, "#" $3); next }
$1 == "or.i"  && isreg($2) && isnum($3) { alu("orr", $2, "#" $3); next }
$1 == "xor.i" && isreg($2) && isnum($3) { alu("xor", $2, "#" $3); next }

$1 == "b" && islabel($2) { print "b " $2; next; }
$1 == "b.eq.r" && islabel($2) && isreg($3) && isreg($4) { cond("eq", $3, $4, $2); next }
$1 == "b.ne.r" && islabel($2) && isreg($3) && isreg($4) { cond("ne", $3, $4, $2); next }
$1 == "b.lt.r" && islabel($2) && isreg($3) && isreg($4) { cond("lt", $3, $4, $2); next }
$1 == "b.gt.r" && islabel($2) && isreg($3) && isreg($4) { cond("gt", $3, $4, $2); next }
$1 == "b.le.r" && islabel($2) && isreg($3) && isreg($4) { cond("le", $3, $4, $2); next }
$1 == "b.ge.r" && islabel($2) && isreg($3) && isreg($4) { cond("ge", $3, $4, $2); next }
$1 == "b.eq.i" && islabel($2) && isreg($3) && isnum($4) { cond("eq", $3, "#" $4, $2); next }
$1 == "b.ne.i" && islabel($2) && isreg($3) && isnum($4) { cond("ne", $3, "#" $4, $2); next }
$1 == "b.lt.i" && islabel($2) && isreg($3) && isnum($4) { cond("lt", $3, "#" $4, $2); next }
$1 == "b.gt.i" && islabel($2) && isreg($3) && isnum($4) { cond("gt", $3, "#" $4, $2); next }
$1 == "b.le.i" && islabel($2) && isreg($3) && isnum($4) { cond("le", $3, "#" $4, $2); next }
$1 == "b.ge.i" && islabel($2) && isreg($3) && isnum($4) { cond("ge", $3, "#" $4, $2); next }

/^$/ { next }
/^;/ { next }
{ err("syntax error") }
