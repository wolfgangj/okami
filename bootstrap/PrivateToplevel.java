class PrivateToplevel implements IToplevel {
    private String _pos;

    public PrivateToplevel(String pos) {
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }
}
