interface IToplevel {
    enum Kind { TYPE, WORD, IMPORT, VPUBLIC, VPRIVATE };

    public String pos();
    public Kind kind();
}
