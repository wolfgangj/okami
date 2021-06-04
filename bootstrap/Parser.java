import java.io.FileNotFoundException;
import java.util.ArrayList;
import java.util.Optional;

class Parser {
    private String _filename;
    private Lexer _lex;

    public Parser(String filename)
        throws FileNotFoundException {
        _filename = filename;
        _lex = new Lexer(filename);
    }

    // returns Optional.empty on eof (and on error)
    public Optional<IToplevel> nextToplevel() {
        var tok = nextToken();
        switch (tok.kind()) {
        case EOF:
            return Optional.empty();
        case ID:
            return parseToplevel(tok.text());
        default:
            Error.add("unexpected token " + tok.toString() + " at toplevel",
                      tok.pos());
            return Optional.empty();
        }
    }

    private Token nextToken() {
        return _lex.nextToken();
    }

    private Token peekToken() {
        return _lex.peekToken();
    }

    private Optional<IToplevel> parseToplevel(String keyword) {
        switch (keyword) {
        case "def":
            return parseDefinition();
        case "the":
            return parseVariable();
        case "private":
            return Optional.of(new PrivateToplevel(_lex.pos()));
        case "public":
            return Optional.of(new PublicToplevel(_lex.pos()));
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
            return Optional.empty();
        }
    }

    private void expectSpecial(String which) {
        var tok = nextToken();
        if (!tok.isSpecial(which)) {
            Error.add("expected '" + which + "', found " + tok.toString(),
                      tok.pos());
        }
    }

    private Optional<IToplevel> parseDefinition() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier, found " + name.toString(),
                      name.pos());
        }
        expectSpecial("(");
        var effect = parseEffect();
        var code = parseBlock();

        if (Error.any()) {
            return Optional.empty();
        }
        /* TODO
        return Optional.of(new Definition(name.text, effect, code.get(), name.pos()));
        */return Optional.empty();
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
            if (type.isPresent()) {
                from.add(type.get());
            }
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
                if (type.isPresent()) {
                    to.add(type.get());
                }
            }
        }
        return new Effect(from, to, noreturn, _lex.pos());
    }

    private Optional<Block> parseBlock() {
        var tok = nextToken();
        if (!tok.isSpecial("[")) {
            Error.add("expected '[', found " + tok.toString(), tok.pos());
            return Optional.empty();
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
                    code.add(new NameOp("@", tok.pos()));
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
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new Block(code, pos));
    }

    private Optional<IToplevel> parseVariable() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as variable name after 'the', found "
                      + name.toString(), name.pos());
        }
        expectSpecial(":");
        var type = parseType();
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new VariableToplevel(name.text(), type.get(), name.pos()));
    }

    private Optional<IToplevel> parseClass() {
        return Optional.empty(); // TODO
    }

    private Optional<IToplevel> parseOpt() {
        return Optional.empty(); // TODO
    }

    private Optional<IToplevel> parseUse() {
        return Optional.empty(); // TODO
    }

    private Optional<IToplevel> parsePrimitiveType() {
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
            return Optional.empty();
        }
        return Optional.of(new PrimitiveTypeToplevel(name.text(), base.text(), name.pos()));
    }

    private Optional<IToplevel> parseAlias() {
        return Optional.empty(); // TODO
    }

    private Optional<IType> parseType() {
        var tok = nextToken();
        switch (tok.kind()) {
        case ID:
            return Optional.of(new BasicType(tok.text(), tok.pos()));
        case SPECIAL:
            var nullable = false; // for @ or ^
            switch (tok.text()) {
            case "^":
                nullable = true;
                // FALL THROUGH
            case "@":
                var adrType = parseType();
                if (adrType.isEmpty()) {
                    return Optional.empty();
                }
                return Optional.of(new AdrType(adrType.get(), nullable, tok.pos()));
            case "[":
                int len = parseInt();
                if (len <= 0) {
                    Error.add("invalid array len " + len, tok.pos());
                }
                tok = nextToken();
                if (!tok.isSpecial("]")) {
                    Error.add("expected ']', found " + tok.toString(), tok.pos());
                }
                var type = parseType();
                if (Error.any()) {
                    return Optional.empty();
                }
                return Optional.of(new AryType(type.get(), len, tok.pos()));
            default:
                Error.add("expected type, found " + tok.toString(), tok.pos());
                return Optional.empty();
            }
        default:
            Error.add("expected type, found " + tok.toString(), tok.pos());
            return Optional.empty();
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
