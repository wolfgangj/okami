import java.util.ArrayList;
import java.util.Optional;

class Effect {
    private ArrayList<IType> _from;
    private Optional<ArrayList<IType>> _to;
    private String _pos;

    public Effect(ArrayList<IType> from, Optional<ArrayList<IType>> to,
                  String pos) {
        _from = from;
        _to = to;
        _pos = pos;
    }

    public ArrayList<IType> from() {
        return _from;
    }

    public Optional<ArrayList<IType>> to() {
        return _to;
    }

    public String pos() {
        return _pos;
    }

    public boolean noreturn() {
        return _to.isEmpty();
    }

    public String toString() {
        return "(" + typeList(_from) + " :: " +
            (_to.isEmpty() ? "never" : typeList(_to.get())) + ")";
    }

    private String typeList(ArrayList<IType> list) {
        var result = "";
        var first = true;
        for (var type : list) {
            if (first) {
                first = false;
            } else {
                result += " ";
            }
            result += type.toString();
        }
        return result;
    }
}
