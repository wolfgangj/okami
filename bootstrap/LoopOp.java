class LoopOp implements IOp {
    private Block code;

    public String pos() {
        return this.code.pos();
    }

    public Block code() {
        return this.code;
    }

    public LoopOp(Block code) {
        this.code = code;
    }
}
