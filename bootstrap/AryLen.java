import java.util.Optional;

class AryLen {
    private int num;
    private Optional<String> sym;
    private String pos;

    public AryLen(final int num,
                  final String pos) {
        this.sym = Optional.empty();
        this.pos = pos;
        setNum(num); // call after setting pos
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

    public void setNum(final int num) {
        if (num <= 0) {
            Error.add("invalid array len " + num, this.pos);
        }
        this.num = num;
    }
}
