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
    public Optional<IDeclaration> nextDeclaration() {
        var tok = nextToken();
        switch (tok.kind()) {
        case EOF:
            return Optional.empty();
        case ID:
            return parseDeclaration(tok.text());
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

    private Optional<IDeclaration> parseDeclaration(String keyword) {
        switch (keyword) {
        case "def":
            return parseDefinition();
        case "the":
            return parseVariable();
        case "private":
            return Optional.of(new PrivateDeclaration(_lex.pos()));
        case "public":
            return Optional.of(new PublicDeclaration(_lex.pos()));
        case "class":
            return parseClass();
        case "opt":
            return parseOpt();
        case "use":
            return parseUse();
        case "type":
            return parsePrimitiveType();
        case "let":
            return parseLet();
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

    private Optional<IDeclaration> parseDefinition() {
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
        return Optional.of(new DefinitionDeclaration(name.text(), effect,
                                                     code, name.pos()));
    }

    private Effect parseEffect() {
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
            if (unexpectedEof(tok)) {
                break;
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
            if (unexpectedEof(tok)) {
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
        if (noreturn && to.size() > 0) {
            Error.add("incoherent result list in effect", _lex.pos());
        }
        return new Effect(from,
                          noreturn ? Optional.empty() : Optional.of(to),
                          _lex.pos());
    }

    private boolean unexpectedEof(Token tok) {
        if (tok.isEof()) {
            Error.add("unexpected EOF", tok.pos());
            return true;
        }
        return false;
    }

    private Block parseBlock() {
        expectSpecial("[");
        var pos = _lex.pos();

        var code = new ArrayList<IOp>();
        while (true) {
            var tok = nextToken();
            if (tok.isSpecial("]")) {
                break;
            }
            if (unexpectedEof(tok)) {
                break;
            }

            switch (tok.kind()) {
            case SPECIAL:
                switch (tok.text()) {
                case "@": case "#":
                    code.add(new WordOp(tok.text(), tok.pos()));
                    break;
                case "(":
                    code.add(new CastOp(parseEffect(), tok.pos()));
                    break;
                default:
                    Error.add("expected code, found " + tok.toString(), tok.pos());
                }
                break;
            case ID:
                var special = false;
                switch (tok.text()) {
                case "if":
                    expectSpecial(":");
                    code.add(parseIf());
                    special = true;
                    break;
                case "with":
                    expectSpecial(":");
                    code.add(parseWith());
                    special = true;
                    break;
                case "loop":
                    expectSpecial(":");
                    code.add(parseLoop());
                    special = true;
                    break;
                case "new":
                    // TODO
                    break;
                case "is":
                    // TODO
                    break;
                case "memsize":
                    // we allow this also as normal identifier
                    if (peekToken().isSpecial(":")) {
                        nextToken(); // remove the colon
                        special = true;
                        //code.add(parseMemsize());//TODO
                    }
                    break;
                case "srcpos":
                    special = true;
                    code.add(new StrOp(_filename + ":" + tok.pos(),
                                       tok.pos()));
                    break;
                }
                if (!special) {
                    code.add(new WordOp(tok.text(), tok.pos()));
                }
                break;
            case INT:
                try {
                    code.add(new IntOp(Integer.parseInt(tok.text()),
                                       tok.pos()));
                } catch (NumberFormatException e) {
                    Error.add("internal error", tok.pos());
                }
                break;
            case STR:
                code.add(new StrOp(tok.text(), tok.pos()));
                break;
            default:
                Error.add("expected code, found " + tok.toString(), tok.pos());
            }
        }
        return new Block(code, pos);
    }

    private IfOp parseIf() {
        var pos = _lex.pos();
        var thenBranch = parseBlock();
        Optional<Block> elseBranch = Optional.empty();

        var tok = peekToken();
        if (tok.isIdentifier("else")) {
            nextToken(); // remove 'else'
            expectSpecial(":");
            elseBranch = Optional.of(parseBlock());
        }

        return new IfOp(thenBranch, elseBranch, pos);
    }

    private WithOp parseWith() {
        var pos = _lex.pos();
        var withBranch = parseBlock();

        var tok = nextToken();
        if (!tok.isIdentifier("else")) {
            Error.add("'with' requires 'else'", tok.pos());
        }
        expectSpecial(":");

        var elseBranch = parseBlock();
        return new WithOp(withBranch, elseBranch, pos);
    }

    private LoopOp parseLoop() {
        var code = parseBlock();
        return new LoopOp(code);
    }


    private Optional<IDeclaration> parseVariable() {
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
        return Optional.of(new VariableDeclaration(name.text(), type.get(), name.pos()));
    }

    private Optional<IDeclaration> parseClass() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("class name expected, found " + name.toString(), name.pos());
        }
        expectSpecial("{");
        var content = new ArrayList<IDeclaration>();
        while (true) {
            var tok = nextToken();
            if (tok.isSpecial("}")) {
                break;
            }
            //if (unexpectedEof(tok)) {
            //    break;
            //}
            if (tok.kind() != Token.Kind.ID) {
                Error.add("unexpected token in class: " + tok.toString(), tok.pos());
                break;
            }
            Optional<IDeclaration> entry = Optional.empty();
            switch (tok.text()) {
            case "def":
                entry = parseDefinition();
                break;
            case "the":
                entry = parseVariable();
                break;
            case "private":
                entry = Optional.of(new PrivateDeclaration(_lex.pos()));
                break;
            case "public":
                entry = Optional.of(new PublicDeclaration(_lex.pos()));
                break;
            case "opt":
                entry = parseOpt();
                break;
            case "type":
                entry = parsePrimitiveType();
                break;
            case "let":
                entry = parseLet();
                break;
            default:
                Error.add("unknown class keyword " + tok.toString(), tok.pos());
            }
            if (entry.isEmpty()) {
                break;
            }
            content.add(entry.get());
        }
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new ClassDeclaration(name.text(), content, name.pos()));
    }

    private Optional<IDeclaration> parseOpt() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("option type name expected, found " + name.toString(),
                      name.pos());
        }
        expectSpecial("{");

        var options = new ArrayList<String>();
        while (true) {
            var tok = nextToken();
            if (tok.isSpecial("}")) {
                break;
            }
            if (tok.kind() != Token.Kind.ID) {
                Error.add("expected identifier or '}', found " + tok.toString(),
                          tok.pos());
                break;
            }
            options.add(tok.text());
        }
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new OptDeclaration(name.text(), options, name.pos()));
    }

    private Optional<IDeclaration> parseUse() {
        var tok = nextToken();
        if (tok.kind() != Token.Kind.ID && tok.kind() != Token.Kind.STR) {
            Error.add("expected module name, found " + tok.toString(),
                      tok.pos());
            return Optional.empty();
        }
        return Optional.of(new UseDeclaration(tok.text(), tok.pos()));
    }

    private Optional<IDeclaration> parsePrimitiveType() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier as typename after 'type', found "
                      + name.toString(), name.pos());
        }
        expectSpecial(":");
        var base = nextToken();
        if (base.kind() != Token.Kind.ID) {
            Error.add("expected identifier as base type for 'type', found "
                      + base.toString(), base.pos());
        }
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new PrimitiveTypeDeclaration(name.text(), base.text(), name.pos()));
    }

    private Optional<IDeclaration> parseLet() {
        var name = nextToken();
        if (name.kind() != Token.Kind.ID) {
            Error.add("expected identifier after 'let', found "
                      + name.toString(), name.pos());
        }
        expectSpecial(":");
        var value = nextToken();
        if (value.kind() == Token.Kind.SPECIAL) {
            Error.add("expected value, found " + value.toString(), value.pos());
        }
        if (Error.any()) {
            return Optional.empty();
        }
        return Optional.of(new LetDeclaration(name.text(), value, name.pos()));
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
                AryLen len = parseAryLen();
                expectSpecial("]");
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

    private AryLen parseAryLen() {
        var tok = nextToken();
        switch (tok.kind()) {
        case INT:
            return new AryLen(Integer.parseInt(tok.text()), tok.pos());
        case ID:
            return new AryLen(tok.text(), tok.pos());
        default:
            Error.add("expected int literal or identifier, found "
                      + tok.toString(), tok.pos());
            return new AryLen(-1, tok.pos());
        }
    }
}
