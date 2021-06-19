import java.util.Optional;

class AryType implements IType {
    private IType _type;
    private AryLen _len;
    private String _pos;

    public AryType(IType type, AryLen len, String pos) {
        _type = type;
        _len = len;
        _pos = pos;
    }

    public IType type() {
        return _type;
    }

    public AryLen len() {
        return _len;
    }

    public String pos() {
        return _pos;
    }

    public String toString() {
        return "[" + _len.toString() + "]" + _type.toString();
    }
}
