class VariableDeclaration implements IDeclaration {
    private String name;
    private IType type;
    private String pos;

    public VariableDeclaration(final String name,
                               final IType type,
                               final String pos) {
        this.name = name;
        this.type = type;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.WORD;
    }

    public String name() {
        return this.name;
    }
}
