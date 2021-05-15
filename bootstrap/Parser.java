import java.io.FileNotFoundException;

class Parser {
    private String _filename;
    private Lexer _lex;

    public Parser(String filename)
        throws FileNotFoundException {
        _filename = filename;
        _lex = new Lexer(filename);
    }

    // returns null on eof and on error
    public IToplevel nextToplevel() {
        var tok = nextToken();
        switch (tok.kind()) {
        case EOF: {
            return null;
        }
        case ID: {
            return parseToplevel(tok.text());
        }
        default: {
            Error.add("unexpected token " + tok.toString() + " at toplevel",
                      tok.pos());
            return null;
        }
        }
    }

    private Token nextToken() {
        return _lex.nextToken();
    }

    // returns null on error
    private IToplevel parseToplevel(String keyword) {
        switch (keyword) {
        case "def": {
            return parseDefinition();
        }
        case "the": {
            return parseVariable();
        }
        case "private": {
            return new PrivateToplevel();
        }
        case "public": {
            return new PublicToplevel();
        }
        case "class": {
            return parseClass();
        }
        case "opt": {
            return parseOpt();
        }
        case "use": {
            return parseUse();
        }
        case "type": {
            return parsePrimitiveType();
        }
        case "let": {
            return parseAlias();
        }
        default: {
            Error.add("unknown toplevel keyword " + keyword,
                      _filename + ":" + _lex.line());
            return null;
        }
        }
    }

    private IToplevel parseDefinition() {
        return null; // TODO
    }

    private IToplevel parseVariable() {
        return null; // TODO
    }

    private IToplevel parseClass() {
        return null; // TODO
    }

    private IToplevel parseOpt() {
        return null; // TODO
    }

    private IToplevel parseUse() {
        return null; // TODO
    }

    private IToplevel parsePrimitiveType() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as typename after 'type', found "
                      + name.toString(), name.pos());
            return null;
        }
        var colon = nextToken();
        if (!colon.isSpecial(":")) {
            Error.add("expected ':', found " + colon.toString(), colon.pos());
            return null;
        }
        var base = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as base type for 'type', found "
                      + base.toString(), base.pos());
            return null;
        }
        return new PrimitiveTypeToplevel(name.text(), base.text(), name.pos());
    }

    private IToplevel parseAlias() {
        return null; // TODO
    }
}
