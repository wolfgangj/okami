class PrimitiveTypeDeclaration implements IDeclaration {
    private String name;
    private String base;
    private String pos;

    public PrimitiveTypeDeclaration(final String name,
                                    final String base,
                                    final String pos) {
        this.name = name;
        this.base = base;
        this.pos = pos;
    }

    public String name() {
        return this.name;
    }

    public String base() {
        return this.base;
    }
    
    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.TYPE;
    }
}
