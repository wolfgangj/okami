class CastOp implements IOp {
    private Effect _effect;
    private String _pos;

    public String pos() {
        return _pos;
    }

    public Effect effect() {
        return _effect;
    }

    public CastOp(Effect effect, String pos) {
        _effect = effect;
        _pos = pos;
    }
}
