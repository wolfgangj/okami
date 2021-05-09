import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;

class Lexer {
    private String _filename;
    private int _line = 1;
    private FileInputStream _src;
    private Token _ahead = null;

    public Lexer(String filename)
    throws FileNotFoundException {
        _filename = filename;
        _src = new FileInputStream(filename);
    }

    public int line() {
        return _line;
    }

    public Token nextToken() {
        if (_ahead != null) {
            var token = _ahead;
            _ahead = null;
            return token;
        } else {
            return readToken();
        }
    }

    public Token peekToken() {
        _ahead = nextToken();
        return _ahead;
    }

    public int getc() { // TODO: private
        try {
            var c = _src.read();
            if (c == '\n') {
                _line++;
            }
            return c;
        } catch (IOException e) {
            return -1;
        }
    }

    private Token readToken() {
        // TODO
        return null;
    }
}
