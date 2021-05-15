class Token {
    enum Kind {
        SPECIAL,
        ID,
        INT,      // convert text to int with try{Integer.parseInt(_text)}catch(NumberFormatException e) {}
        STR,
        EOF
    }
    private Kind _kind;
    private String _text;

    private String _filename;
    private int _line;

    public Token(Kind k, String t, String f, int l) {
        _kind = k;
        _text = t;
        _filename = f;
        _line = l;
    }

    public boolean isSpecial(String which) {
        return _kind == Kind.SPECIAL && _text == which;
    }

    public boolean isIdentifier(String which) {
        return _kind == Kind.ID && _text == which;
    }

    public boolean isEof() {
        return _kind == Kind.EOF;
    }

    public Kind kind() {
        return _kind;
    }

    public String text() {
        return _text;
    }

    public String toString() {
        return _kind + ":" + _text;
    }

    public String pos() {
        return _filename + ":" + _line;
    }
}
