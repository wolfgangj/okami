import java.util.Optional;

class IfOp implements IOp {
    private Block _thenBranch;
    private Optional<Block> _elseBranch;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public Block thenBranch() {
        return _thenBranch;
    }

    public Optional<Block> elseBranch() {
        return _elseBranch;
    }

    public IfOp(Block thenBranch, Optional<Block> elseBranch, String pos) {
        _thenBranch = thenBranch;
        _elseBranch = elseBranch;
        _pos = pos;
    }
}
