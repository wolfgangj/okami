class BasicType implements IType {
    private String name;
    private String pos;

    public BasicType(final String name,
                     final String pos) {
        this.name = name;
        this.pos = pos;
    }

    public String toString() {
        return this.name;
    }

    public String name() {
        return this.name;
    }

    public String pos() {
        return this.pos;
    }
}
