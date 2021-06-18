class Definition implements IToplevel {
    private String _name;
    private Effect _effect;
    private Block _code;
    private String _pos;

    public Definition(String name, Effect effect, Block code, String pos) {
        _name = name;
        _effect = effect;
        _code = code;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IToplevel.Kind.WORD;
    }
}
