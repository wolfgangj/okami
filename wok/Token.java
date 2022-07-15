class Token {
    enum Kind {
        SPECIAL,
        ID,
        INT,      // convert text to int with try{Integer.parseInt(_text)}catch(NumberFormatException e) {}
        STR,
        EOF
    }
    private final Kind kind;
    private final String text;

    private final String filename;
    private final int line;

    public Token(final Kind kind,
                 final String text,
                 final String filename,
                 final int line) {
        this.kind = kind;
        this.text = text;
        this.filename = filename;
        this.line = line;
    }

    public boolean isSpecial(final String which) {
        return this.kind == Kind.SPECIAL && this.text.equals(which);
    }

    public boolean isIdentifier(final String which) {
        return this.kind == Kind.ID && this.text.equals(which);
    }

    public boolean isEof() {
        return this.kind == Kind.EOF;
    }

    public Kind kind() {
        return this.kind;
    }

    public String text() {
        return this.text;
    }

    public String toString() {
        return this.kind + "(" + this.text + ")";
    }

    public String pos() {
        return this.filename + ":" + this.line;
    }
}
