class PublicDeclaration implements IDeclaration {
    private String pos;

    public PublicDeclaration(String pos) {
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.VPUBLIC;
    }

    public String name() {
        return "{public}";
    }
}
