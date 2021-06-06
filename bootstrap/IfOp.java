class IfOp implements IOp {
    private Block _block;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public Block block() {
        return _block;
    }

    public IfOp(Block block, String pos) {
        _block = block;
        _pos = pos;
    }
}
