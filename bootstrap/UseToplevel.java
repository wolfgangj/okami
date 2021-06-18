class UseToplevel implements IToplevel {
    private String _pos;
    private String _moduleName;

    public UseToplevel(String moduleName, String pos) {
        _moduleName = moduleName;
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }

    public Kind kind() {
        return IToplevel.Kind.VPRIVATE;
    }

    public String name() {
        return _moduleName;
    }
}
