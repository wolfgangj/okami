class WithOp implements IOp {
    private Block withBranch;
    private Block elseBranch;
    private String pos;

    public WithOp(final Block withBranch,
                  final Block elseBranch,
                  final String pos) {
        this.withBranch = withBranch;
        this.elseBranch = elseBranch;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Block withBranch() {
        return this.withBranch;
    }

    public Block elseBranch() {
        return this.elseBranch;
    }
}
