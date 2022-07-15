class UseDeclaration implements IDeclaration {
    private final String pos;
    private final String moduleName;

    public UseDeclaration(final String moduleName,
                          final String pos) {
        this.moduleName = moduleName;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.IMPORT;
    }

    public String name() {
        return this.moduleName;
    }
}
