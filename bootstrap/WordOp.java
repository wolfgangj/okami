class WordOp implements IOp {
    private String _name;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public String name() {
        return _name;
    }

    public WordOp(String name, String pos) {
        _name = name;
        _pos = pos;
    }
}
