import java.util.ArrayList;
import java.util.Optional;

class Effect {
    private ArrayList<IType> from;
    private Optional<ArrayList<IType>> to;
    private String pos;

    public Effect(final ArrayList<IType> from,
                  final Optional<ArrayList<IType>> to,
                  String pos) {
        this.from = from;
        this.to = to;
        this.pos = pos;
    }

    public static Effect empty(final String pos) {
        return new Effect(new ArrayList<>(),
                          Optional.of(new ArrayList<>()),
                          pos);
    }

    public ArrayList<IType> from() {
        return this.from;
    }

    public Optional<ArrayList<IType>> to() {
        return this.to;
    }

    public String pos() {
        return this.pos;
    }

    public boolean noreturn() {
        return this.to.isEmpty();
    }

    public String toString() {
        return "(" + typeList(this.from) + " :: " +
            (this.to.isEmpty() ? "never" : typeList(this.to.get())) + ")";
    }

    private String typeList(final ArrayList<IType> list) {
        var result = "";
        var first = true;
        for (var type : list) {
            if (first) {
                first = false;
            } else {
                result += " ";
            }
            result += type;
        }
        return result;
    }
}
