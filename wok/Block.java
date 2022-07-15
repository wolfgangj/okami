import java.util.ArrayList;

class Block {
    private final String pos;
    private final ArrayList<IOp> ops;

    public Block(final ArrayList<IOp> ops,
                 final String pos) {
        this.ops = ops;
        this.pos = pos;
    }

    public Block(final String pos) {
        this.pos = pos;
        this.ops = new ArrayList<IOp>();
    }

    public String pos() {
        return this.pos;
    }
}
