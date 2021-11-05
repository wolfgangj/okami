class DefinitionDeclaration implements IDeclaration {
    private String name;
    private Effect effect;
    private Block code;
    private String pos;

    public DefinitionDeclaration(final String name,
                                 final Effect effect,
                                 final Block code,
                                 final String pos) {
        this.name = name;
        this.effect = effect;
        this.code = code;
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
