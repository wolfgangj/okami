class PrimitiveTypeToplevel implements IToplevel {
    private String _name;
    private String _base;
    private String _pos;

    public PrimitiveTypeToplevel(String name, String base, String pos) {
        _name = name;
        _base = base;
        _pos = pos;
    }

    public String name() {
        return _name;
    }

    public String base() {
        return _base;
    }
    
    public String pos() {
        return _pos;
    }
}
