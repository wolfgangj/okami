class PublicToplevel implements IToplevel {
    private String _pos;

    public PublicToplevel(String pos) {
        _pos = pos;
    }

    public String pos() {
        return _pos;
    }
}
