class AdrType implements IType {
    private final IType type;
    private final String pos;
    private final boolean nullable;

    public AdrType(final IType type,
                   final boolean nullable,
                   final String pos) {
        this.type = type;
        this.nullable = nullable;
        this.pos = pos;
    }

    public String toString() {
        return "@" + this.type;
    }

    public IType type() {
        return this.type;
    }

    public String pos() {
        return this.pos;
    }

    public boolean nullable() {
        return this.nullable;
    }
}
