class BasicType implements IType {
    private String _name;

    public BasicType(String name) {
        _name = name;
    }

    public String toString() {
        return _name;
    }
}
