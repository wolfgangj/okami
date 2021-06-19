import java.util.Optional;

class AryLen {
    private int _num;
    private Optional<String> _sym;
    private String _pos;

    public AryLen(int num, String pos) {
        _sym = Optional.empty();
        _pos = pos;
        setNum(num); // call after setting pos
    }

    public AryLen(String sym, String pos) {
        _sym = Optional.of(sym);
        _num = -1;
        _pos = pos;
    }

    public String toString() {
        if (_sym.isEmpty()) {
            return "" + _num;
        } else {
            return _sym.get();
        }
    }

    public void setNum(int num) {
        if (num <= 0) {
            Error.add("invalid array len " + num, _pos);
        }
        _num = num;
    }
}
