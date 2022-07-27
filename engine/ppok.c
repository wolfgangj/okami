/*
 * ppok.c - PreProcessor for the EngineScript boot code
 * Copyright (C) 2022 Wolfgang Jährling
 *
 * ISC License
 *
 * Permission to use, copy, modify, and/or distribute this software for any
 * purpose with or without fee is hereby granted, provided that the above
 * copyright notice and this permission notice appear in all copies.
 *
 * THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
 * WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
 * MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
 * ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
 * WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
 * ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
 * OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.
 */

#include <stdio.h>
#include <stdlib.h>

enum mode { INTERPRET, COMPILE, POSTPONE } mode = INTERPRET;

int bracket(int c) {
  if (c == '[') {
    switch (mode) {
    case INTERPRET: mode = COMPILE;  break;
    case COMPILE:   mode = POSTPONE; break;
    case POSTPONE:  abort();         break;
    }
    return -1;
  }
  if (c == ']') {
    switch (mode) {
    case INTERPRET: abort();          break;
    case COMPILE:   mode = INTERPRET; break;
    case POSTPONE:  mode = COMPILE;   break;
    }
    return -1;
  }
  return 0;
}

int main() {
  for(;;) {
    int c = getchar();
    if (c == EOF) {
      break;
    }

    // skip whitespace
    if (c == ' ' || c == '\n') {
      continue;
    }

    // ignore comments
    if (c == '\\') {
      do {
        c = getchar();
      } while (c != EOF && c != '\n');
      continue;
    }

    // switch between modes via brackets
    if (bracket(c)) {
      continue;
    }

    char output[9];
    int i = 0;
    do {
      output[i] = c;
      c = getchar();
      i++;
    } while (c != ' ' && c != '\n' && c != EOF && c != '[' && c != ']' && i <= 8);
    output[i] = '\0';

    switch(mode) {
      case INTERPRET:
        printf("%-8s", output);
        break;

      case COMPILE:
        // TODO
        break;

      case POSTPONE:
        // TODO
        break;
    }

    bracket(c);
  }
  putchar('\n');

  return 0;
}
