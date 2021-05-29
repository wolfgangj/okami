class AdrType implements IType {
    private IType _type;
    private String _pos;
    private boolean _nullable;

    public AdrType(IType type, boolean nullable, String pos) {
        _type = type;
        _nullable = nullable;
        _pos = pos;
    }

    public String toString() {
        return "@" + _type.toString();
    }

    public IType type() {
        return _type;
    }

    public String pos() {
        return _pos;
    }

    public boolean nullable() {
        return _nullable;
    }
}
