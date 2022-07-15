import java.util.Optional;

class AryType implements IType {
    private final IType type;
    private final AryLen len;
    private final String pos;

    public AryType(final IType type,
                   final AryLen len,
                   final String pos) {
        this.type = type;
        this.len = len;
        this.pos = pos;
    }

    public IType type() {
        return this.type;
    }

    public AryLen len() {
        return this.len;
    }

    public String pos() {
        return this.pos;
    }

    public String toString() {
        return "[" + this.len + "]" + this.type;
    }
}
