class PublicDeclaration implements IDeclaration {
    private String _pos;

    public PublicDeclaration(String pos) {
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.VPUBLIC;
    }

    public String name() {
        return "{public}";
    }
}
