import java.util.ArrayList;

class Block {
    private String _pos;
    private ArrayList<IOp> _ops;

    public Block(ArrayList<IOp> ops, String pos) {
        _ops = ops;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }
}
