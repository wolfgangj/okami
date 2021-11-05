class PrivateDeclaration implements IDeclaration {
    private String pos;

    public PrivateDeclaration(final String pos) {
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.VPRIVATE;
    }

    public String name() {
        return "{private}";
    }
}
