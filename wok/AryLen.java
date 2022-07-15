import java.util.Optional;

class AryLen {
    private final int num;
    private final Optional<String> sym;
    private final String pos;

    public AryLen(final int num,
                  final String pos) {
        this.sym = Optional.empty();
        this.pos = pos;

        if (num <= 0) {
            Error.add("invalid array len " + num, pos);
        }
        this.num = num;
    }

    public AryLen(final String sym, final String pos) {
        this.sym = Optional.of(sym);
        this.num = -1;
        this.pos = pos;
    }

    public String toString() {
        if (this.sym.isEmpty()) {
            return "" + this.num;
        } else {
            return this.sym.get();
        }
    }
}
