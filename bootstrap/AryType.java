class AryType implements IType {
    private IType _type;
    private int _len;
    private String _pos;

    public AryType(IType type, int len, String pos) {
        _type = type;
        _len = len;
        _pos = pos;
    }

    public IType type() {
        return _type;
    }

    public int len() {
        return _len;
    }

    public String pos() {
        return _pos;
    }

    public String toString() {
        return "[" + _len + "]" + _type.toString();
    }
}
