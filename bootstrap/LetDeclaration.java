class LetDeclaration implements IDeclaration {
    private String name;
    private Token value;
    private String pos;

    public LetDeclaration(final String name,
                          final Token value,
                          final String pos) {
        this.name = name;
        this.value = value;
        this.pos = pos;
    }

    public String name() {
        return this.name;
    }

    public Token value() {
        return this.value;
    }
    
    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.WORD;
    }
}
