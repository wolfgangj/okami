class StrOp implements IOp {
    private String _val;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public String val() {
        return _val;
    }

    public StrOp(String val, String pos) {
        _val = val;
        _pos = pos;
    }
}
