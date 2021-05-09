class AdrType implements Type {
    private Type type;

    public AdrType(Type t) {
        type = t;
    }

    public String toString() {
        return "@" + type.toString();
    }
}
