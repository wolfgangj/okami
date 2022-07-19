define hook-stop
  x/1i $pc
end
alias da=disassemble
alias reg=info registers

break _start
run
