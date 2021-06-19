class UseDeclaration implements IDeclaration {
    private String _pos;
    private String _moduleName;

    public UseDeclaration(String moduleName, String pos) {
        _moduleName = moduleName;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.IMPORT;
    }

    public String name() {
        return _moduleName;
    }
}
