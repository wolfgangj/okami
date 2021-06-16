class LoopOp implements IOp {
    private Block _code;

    public String pos() {
        return _code.pos();
    }

    public Block code() {
        return _code;
    }

    public LoopOp(Block code) {
        _code = code;
    }
}
