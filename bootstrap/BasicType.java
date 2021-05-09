class BasicType implements Type {
    private String name;

    public BasicType(String n) {
        name = n;
    }

    public String toString() {
        return name;
    }
}
