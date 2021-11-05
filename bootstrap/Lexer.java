import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

class Lexer {
    private String filename;
    private int line = 1;
    private FileInputStream src;
    private Token ahead = null;
    private final int NOTHING = -2;
    private int cahead = NOTHING;

    public Lexer(final String filename)
        throws FileNotFoundException {
        this.filename = filename;
        this.src = new FileInputStream(filename);
    }

    public int line() {
        return this.line;
    }

    public String pos() {
        return this.filename + ":" + this.line;
    }

    public Token nextToken() {
        if (this.ahead != null) {
            final var token = this.ahead;
            this.ahead = null;
            return token;
        } else {
            return readToken();
        }
    }

    public Token peekToken() {
        this.ahead = nextToken();
        return this.ahead;
    }

    private int nextc() {
        try {
            if (this.cahead != NOTHING) {
                final var c = this.cahead;
                this.cahead = NOTHING;
                return c;
            } else {
                return this.src.read();
            }
        } catch (IOException e) {
            this.cahead = NOTHING;
            return -1;
        }
    }

    private int getc() {
        final var c = nextc();
        if (c == '\n') {
            this.line++;
        }
        return c;
    }

    private int peekc() {
        this.cahead = nextc();
        return this.cahead;
    }

    private int firstRelevant() {
        while (true) {
            var c = getc();
            if (!isIrrelevantChar(c)) {
                return c;
            }
            if (c == ';') { // comment character
                do {
                    c = getc();
                } while (c != '\n' && c != -1);
            }
        }
    }

    private boolean isIrrelevantChar(final int c) {
        switch (c)  {
        case ' ': case '\n': case ';': case '\t':
            return true;
        }
        return false;
    }

    private boolean isSpecialTokenChar(final int c) {
        switch (c) {
        case '@': case '^': case '(': case ')': case '[': case ']':
        case '{': case '}': case '$': case ':':
            return true;
        }
        return false;
    }
    
    private boolean isIdentifierChar(final int c) {
        if (isSpecialTokenChar(c) || isIrrelevantChar(c)) {
            return false;
        }
        switch (c) {
        case '#': case '%': case '&': case '|': case '"':
        case ',': case '\\': case '.':
            return false;
        }
        return true;
    }

    private int escapedChar(final int c) {
        switch (c) {
        case 'n':
            return '\n';
        case 't':
            return '\t';
        case '\\' :
            return '\\';
        case '"' :
            return '"';
        default:
            Error.add("unknown character literal: \\" + ((char) c),
                      this.filename + ":" + this.line);
            return c;
        }
    }

    private Token stringToken() {
        var str = "";
        while (true) {
            var c = getc();
            if (c == '"') {
                break;
            }
            if (c == '\\') {
                c = escapedChar(getc());
            }
            if (c == -1) {
                Error.add("end of file in string literal",
                          this.filename + ": " + this.line);
                break;
            }
            str += (char) c;
        }
        return new Token(Token.Kind.STR, str, this.filename, this.line);
    }

    private Token charToken() {
        var c = getc();
        if (c == '\\') {
            c = escapedChar(getc());
        }
        return new Token(Token.Kind.INT, Integer.toString(c),
                         this.filename, this.line);
    }

    private boolean isDecimal(final String text) {
        try {
            Integer.parseInt(text);
            return true;
        } catch (NumberFormatException e) {
            return false;
        }
    }

    private Token readToken() {
        var c = firstRelevant();
        if (isSpecialTokenChar(c)) {
            return new Token(Token.Kind.SPECIAL, String.valueOf((char) c),
                             this.filename, this.line);
        }
        switch (c) {
        case '"': // string
            return stringToken();
        case '~' : // character
            return charToken();
        case -1: // eof
            return new Token(Token.Kind.EOF, "", this.filename, this.line);
        default:
            var tok = "" + (char) c;
            while (isIdentifierChar(peekc())) {
                tok = tok + (char) getc();
            }
            if (isDecimal(tok)) {
                return new Token(Token.Kind.INT, tok, this.filename, this.line);
            }
            // TODO: hex numbers
            return new Token(Token.Kind.ID, tok, this.filename, this.line);
        }
        // not reached
    }
}
