class VariableDeclaration implements IDeclaration {
    private String _name;
    private IType _type;
    private String _pos;

    public VariableDeclaration(String name, IType type, String pos) {
        name = _name;
        _type = type;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.WORD;
    }

    public String name() {
        return _name;
    }
}
