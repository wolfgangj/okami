import java.util.ArrayList;

class Effect {
    private ArrayList<IType> _from;
    private ArrayList<IType> _to;
    private boolean _noreturn;
    private String _pos;

    public Effect(ArrayList<IType> from, ArrayList<IType> to, boolean noreturn,
                  String pos) {
        if (noreturn && to.size() > 0) {
            Error.add("incoherent result list in effect", pos);
        }

        _from = from;
        _to = to;
        _noreturn = noreturn;
        _pos = pos;
    }

    public ArrayList<IType> from() {
        return _from;
    }

    public ArrayList<IType> to() {
        if (_noreturn) {
            // TODO: can this happen when a type cast contains 'never'?
            throw new RuntimeException("internal error: asking for result stack of 'never' word");
        }
        return _to;
    }

    public String pos() {
        return _pos;
    }

    public boolean noreturn() {
        return _noreturn;
    }

    public String toString() {
        // TODO
        return "TODO";
    }
}
