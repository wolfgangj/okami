class PrivateDeclaration implements IDeclaration {
    private String _pos;

    public PrivateDeclaration(String pos) {
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.VPRIVATE;
    }

    public String name() {
        return "{private}";
    }
}
