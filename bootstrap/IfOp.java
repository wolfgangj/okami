import java.util.Optional;

class IfOp implements IOp {
    private Block thenBranch;
    private Optional<Block> elseBranch;
    private String pos;

    public IfOp(final Block thenBranch,
                final Optional<Block> elseBranch,
                final String pos) {
        this.thenBranch = thenBranch;
        this.elseBranch = elseBranch;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Block thenBranch() {
        return this.thenBranch;
    }

    public Optional<Block> elseBranch() {
        return this.elseBranch;
    }
}
