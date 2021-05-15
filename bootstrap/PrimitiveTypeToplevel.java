class PrimitiveTypeToplevel implements IToplevel {
    private String _name;
    private String _pos;
    private String _base;

    public PrimitiveTypeToplevel(String name, String pos, String base) {
        _name = name;
        _pos = pos;
        _base = base;
    }

    public String name() {
        return _name;
    }

    public String pos() {
        return _pos;
    }

    public String base() {
        return _base;
    }    
}
