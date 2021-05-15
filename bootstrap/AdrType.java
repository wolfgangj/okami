class AdrType implements IType {
    private IType _type;

    public AdrType(IType type) {
        _type = type;
    }

    public String toString() {
        return "@" + _type.toString();
    }
}
