import java.util.ArrayList;

class ClassDeclaration implements IDeclaration {
    private final String name;
    private final ArrayList<IDeclaration> content;
    private final String pos;

    public ClassDeclaration(final String name,
                            final ArrayList<IDeclaration> content,
                            final String pos) {
        this.name = name;
        this.content = content;
        this.pos = pos;
    }

    public String name() {
        return this.name;
    }

    public ArrayList<IDeclaration> content() {
        return this.content;
    }
    
    public String pos() {
        return this.pos;
    }

    public Kind kind() {
        return IDeclaration.Kind.TYPE;
    }
}
