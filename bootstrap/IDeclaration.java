interface IDeclaration {
    enum Kind { TYPE, WORD, IMPORT, VPUBLIC, VPRIVATE };

    public String name();
    public String pos();
    public Kind kind();
}
