class WordOp implements IOp {
    private String name;
    private String pos;

    public WordOp(final String name,
                  final String pos) {
        this.name = name;
        this.pos = pos;
    }

    public String pos() {
        return this.pos;
    }

    public String name() {
        return this.name;
    }
}
