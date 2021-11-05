class IntOp implements IOp {
    private int val;
    private String pos;

    public String pos() {
        return this.pos;
    }

    public int val() {
        return this.val;
    }

    public IntOp(int val, String pos) {
        this.val = val;
        this.pos = pos;
    }
}
