class LetDeclaration implements IDeclaration {
    private String _name;
    private Token _value;
    private String _pos;

    public LetDeclaration(String name, Token value, String pos) {
        _name = name;
        _value = value;
        _pos = pos;
    }

    public String name() {
        return _name;
    }

    public Token value() {
        return _value;
    }
    
    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.WORD;
    }
}
