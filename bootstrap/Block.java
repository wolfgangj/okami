import java.util.ArrayList;

class Block {
    private String pos;
    private ArrayList<IOp> ops;

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
