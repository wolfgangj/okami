class AdrType implements Type {
    private Type _type;

    public AdrType(Type type) {
        _type = type;
    }

    public String toString() {
        return "@" + _type.toString();
    }
}
