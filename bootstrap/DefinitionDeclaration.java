class DefinitionDeclaration implements IDeclaration {
    private String _name;
    private Effect _effect;
    private Block _code;
    private String _pos;

    public DefinitionDeclaration(String name, Effect effect, Block code, String pos) {
        _name = name;
        _effect = effect;
        _code = code;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.WORD;
    }

    public String name() {
        return _name;
    }
}
