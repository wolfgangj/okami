class CastOp implements IOp {
    private final Effect effect;
    private final String pos;

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
