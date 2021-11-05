class CastOp implements IOp {
    private Effect effect;
    private String pos;

    public CastOp(final Effect effect,
                  final String pos) {
        this.effect = effect;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public Effect effect() {
        return this.effect;
    }
}
