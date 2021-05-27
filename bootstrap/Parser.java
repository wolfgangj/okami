import java.io.FileNotFoundException;
import java.util.ArrayList;

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
        case EOF:
            return null;
        case ID:
            return parseToplevel(tok.text());
        default:
            Error.add("unexpected token " + tok.toString() + " at toplevel",
                      tok.pos());
            return null;
        }
    }

    private Token nextToken() {
        return _lex.nextToken();
    }

    private Token peekToken() {
        return _lex.peekToken();
    }

    // returns null on error
    private IToplevel parseToplevel(String keyword) {
        switch (keyword) {
        case "def":
            return parseDefinition();
        case "the":
            return parseVariable();
        case "private":
            return new PrivateToplevel(_lex.pos());
        case "public":
            return new PublicToplevel(_lex.pos());
        case "class":
            return parseClass();
        case "opt":
            return parseOpt();
        case "use":
            return parseUse();
        case "type":
            return parsePrimitiveType();
        case "let":
            return parseAlias();
        default:
            Error.add("unknown toplevel keyword " + keyword,
                      _filename + ":" + _lex.line());
            return null;
        }
    }

    private void expectSpecial(String which) {
        var tok = nextToken();
        if (!tok.isSpecial(which)) {
            Error.add("expected '" + which + "', found " + tok.toString(),
                      tok.pos());
        }
    }

    private IToplevel parseDefinition() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier, found " + name.toString(),
                      name.pos());
        }
        expectSpecial("(");
        var effect = parseEffect();
        var code = parseBlock();

        if (Error.any()) {
            return null;
        }
        /* TODO
        return new Definition(name.text, effect, code, name.pos());
        */return null;
    }

    private Effect parseEffect() {
        // TODO: catch EOF in the loops
        var from = new ArrayList<IType>();
        while (true) {
            var tok = peekToken();
            if (tok.isSpecial(":")) {
                // skip over all colons until we find something else
                do {
                    nextToken(); // skip the ':'
                    tok = peekToken();
                } while (tok.isSpecial(":"));
                break;
            }
            if (tok.isSpecial(")")) {
                break; // leave the ')' here
            }
            var type = parseType();
            from.add(type);
        }

        var to = new ArrayList<IType>();
        var noreturn = false;
        while (true) {
            var tok = peekToken();
            if (tok.isSpecial(")")) {
                nextToken(); // remove the ')'
                break;
            }
            if (tok.isIdentifier("never")) {
                nextToken(); // remove it
                noreturn = true;
            } else {
                var type = parseType();
                to.add(type);
            }
        }
        if (Error.any()) {
            return null;
        }
        return new Effect(from, to, noreturn, _lex.pos());
    }

    private Block parseBlock() {
        var tok = nextToken();
        if (!tok.isSpecial("[")) {
            Error.add("expected '[', found " + tok.toString(), tok.pos());
            return null;
        }
        var pos = tok.pos();

        var code = new ArrayList<IOp>();
        while (true) {
            tok = nextToken();
            if (tok.isSpecial("]")) {
                break;
            }

            switch (tok.kind()) {
            case SPECIAL:
                switch (tok.text()) {
                case "@":
                    // TODO
                    break;
                case "(":
                    // TODO
                    break;
                case "$":
                    // TODO
                    break;
                default:
                    Error.add("expected code, found " + tok.toString(), tok.pos());
                }
                break;
            case ID:
                switch (tok.text()) {
                case "if":
                    // TODO
                    break;
                case "with":
                    // TODO
                    break;
                case "loop":
                    // TODO
                    break;
                case "new":
                    // TODO
                    break;
                case "is":
                    // TODO
                    break;
                case "size":
                    // TODO: also allow it as normal identifier
                    break;
                case "srcpos":
                    // TODO
                    break;
                }
                break;
            case INT:
                // TODO
                break;
            case STR:
                // TODO
                break;
            default:
                Error.add("expected code, found " + tok.toString(), tok.pos());
            }
        }
        return new Block(code, pos);
    }

    private IToplevel parseVariable() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as variable name after 'the', found "
                      + name.toString(), name.pos());
        }
        expectSpecial(":");
        var type = parseType();
        if (Error.any()) {
            return null;
        }
        return new VariableToplevel(name.text(), type, name.pos());
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
        }
        expectSpecial(":");
        var base = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as base type for 'type', found "
                      + base.toString(), base.pos());
        }
        if (Error.any()) {
            return null;
        }
        return new PrimitiveTypeToplevel(name.text(), base.text(), name.pos());
    }

    private IToplevel parseAlias() {
        return null; // TODO
    }

    private IType parseType() {
        var tok = nextToken();
        switch (tok.kind()) {
        case ID:
            return new BasicType(tok.text(), tok.pos());
        case SPECIAL:
            switch (tok.text()) {
            case "@":
                return new AdrType(parseType(), tok.pos());
            case "^":
                return new PtrType(parseType(), tok.pos());
            case "[":
                int len = parseInt();
                if (len <= 0) {
                    Error.add("invalid array len " + len, tok.pos());
                }
                tok = nextToken();
                if (!tok.isSpecial("]")) {
                    Error.add("expected ']', found " + tok.toString(), tok.pos());
                }
                IType type = parseType();
                if (Error.any()) {
                    return null;
                }
                return new AryType(type, len, tok.pos());
            case "(":
                return null; // TODO
            default:
                Error.add("expected type, found " + tok.toString(), tok.pos());
                return null;
            }
        default:
            Error.add("expected type, found " + tok.toString(), tok.pos());
            return null;
        }
    }

    private int parseInt() {
        var tok = nextToken();
        if (tok.kind() != Token.Kind.INT) {
            Error.add("expected int literal, found " + tok.toString(), tok.pos());
        }
        if (Error.any()) {
            return 0;
        }
        return Integer.parseInt(tok.text());
    }
}
