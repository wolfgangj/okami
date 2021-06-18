class VariableToplevel implements IToplevel {
    private String _name;
    private IType _type;
    private String _pos;

    public VariableToplevel(String name, IType type, String pos) {
        name = _name;
        _type = type;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IToplevel.Kind.WORD;
    }

    public String name() {
        return _name;
    }
}
