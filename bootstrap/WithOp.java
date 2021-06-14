class WithOp implements IOp {
    private Block _withBranch;
    private Block _elseBranch;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public Block withBranch() {
        return _withBranch;
    }

    public Block elseBranch() {
        return _elseBranch;
    }

    public WithOp(Block withBranch, Block elseBranch, String pos) {
        _withBranch = withBranch;
        _elseBranch = elseBranch;
        _pos = pos;
    }
}
