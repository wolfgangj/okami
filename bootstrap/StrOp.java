class StrOp implements IOp {
    private String val;
    private String pos;

    public StrOp(final String val,
                 final String pos) {
        this.val = val;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public String val() {
        return this.val;
    }
}
