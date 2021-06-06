import java.util.ArrayList;

class Block {
    private String _pos;
    private ArrayList<IOp> _ops;

    public Block(ArrayList<IOp> ops, String pos) {
        _ops = ops;
        _pos = pos;
    }

    public Block(String pos) {
        _pos = pos;
        _ops = new ArrayList<IOp>();
    }

    public String pos() {
        return _pos;
    }
}
