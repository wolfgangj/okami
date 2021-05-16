class PtrType implements IType {
    private IType _type;
    private String _pos;

    public PtrType(IType type, String pos) {
        _type = type;
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
}
