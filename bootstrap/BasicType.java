class BasicType implements IType {
    private String _name;
    private String _pos;

    public BasicType(String name, String pos) {
        _name = name;
        _pos = pos;
    }

    public String toString() {
        return _name;
    }

    public String name() {
        return _name;
    }

    public String pos() {
        return _pos;
    }
}
