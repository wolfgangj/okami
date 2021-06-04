class IntOp implements IOp {
    private int _val;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public int val() {
        return _val;
    }

    public IntOp(int val, String pos) {
        _val = val;
        _pos = pos;
    }
}
