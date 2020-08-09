import Base: show, step, run, reset

export Computer, step, run, reset, load, setinput, getoutput

const MEMSIZE = 90

mutable struct Computer
    pc::Int                 # program counter
    registers::Array{Int}   # Registers x1 to x9
    memory::Array{Int}      # From 0-89
    inputs::Array{Int}
    outputs::Array{Int}
end

function Computer(memory = zeros(Int, MEMSIZE))
    Computer(0, zeros(Int, 9), memory, Int[], Int[])
end

# A default computer if none as been created specifically
maincomputer = Computer()

function reset(comp::Computer)
    comp.pc = 0
    comp.registers = zeros(Int, 9)
    comp.outputs = Int[]
    comp
end

reset() = reset(maincomputer)

function load(comp::Computer, program::Array{<:Integer})
    comp.memory = program
end

function load(comp::Computer, filename::AbstractString)
    load(comp, parse.(Int, readlines(filename)))
end

load(program) = load(maincomputer, program)

setinput(comp::Computer, inputs) = comp.inputs = inputs
setinput(inputs) = setinput(maincomputer, inputs)
getoutput(comp::Computer) = comp.outputs
getoutput() = getoutput(maincomputer)

step() = step(maincomputer)
run() = run(maincomputer)

function step(comp::Computer)
    ir = comp.memory[comp.pc+1]
    regs = comp.registers
    
    print("$(comp.pc): $ir; ")
    
    opcode   = Opcode(div(ir, 1000))
    operands = rem(ir, 1000)
    
    # There is always a destination register. But source
    # could be an address or two registers
    dst      = div(operands, 100)
    addr     = rem(operands, 100)
    src      = div(addr, 10)
    offset   = rem(addr, 10)
    
    rd = if 1 <= dst <= 9
            comp.registers[dst]
        else
            0
        end
    
    if opcode == ADD
        rd = regs[src] + regs[offset]
    elseif opcode == SUB
        rd = regs[src] - regs[offset]
    elseif opcode == SUBI
        rd = regs[src] - offset
    elseif opcode == LSH
        rd = regs[src]*10^offset
    elseif opcode == RSH
        rd = rem(regs[src], 10^offset)
        regs[src] = div(regs[src], 10^offset)
    elseif opcode == BRZ
        if rd == 0
            comp.pc = addr - 1 # Sicne we are increasing later
        end
    elseif opcode == BGT
        if rd > 0
            comp.pc = addr - 1
        end
    elseif opcode == LD
        if addr < 90
            rd = comp.memory[addr+1]
        elseif addr == 90
            if isempty(comp.inputs)
                error("All input data has been read")
            end
            rd = pop!(comp.inputs)
        else
            error("Reading from address $addr not supported")
        end
    elseif opcode == ST
        if addr < 90
            comp.memory[addr+1] = rd
        elseif addr == 91
            push!(comp.outputs, rd)
        else
            error("Writing to address $addr not supported")
        end
    elseif opcode == HLT
        comp.pc -= 1 # To avoid moving forward
    end
    
    # Discard results going to register 0
    if 1 <= dst <= 9
        comp.registers[dst] = rd
    end
        
    print(opcode)
    if opcode in (ADD, SUB)
        println(" x$dst, x$src, x$offset") 
    elseif opcode in (SUBI, LSH, RSH)
        println(" x$dst, x$src, $offset")
    elseif opcode == HLT
        println()
    else
        println(" x$dst, $addr")
    end 
    
    comp.pc += 1
    comp
end

function show(io::IO, computer::Computer)
    println(io, "PC: ", computer.pc)
    regs_header = [lpad("x$i", 5) for i in 1:9]
    println(io, join(regs_header))
    regs = [lpad("$r", 5) for r in computer.registers]
    println(io, join(regs))
    print(io, "Input:  ")
    join(io, computer.inputs, ", ")
    println(io)
    
    print(io, "Output: ")
    join(io, computer.outputs, ", ")
    println(io)
end


function run(comp::Computer)
    for _ in 1:100
        pc = comp.pc
        step(comp)
        
        # Check if we reached halt
        if comp.pc == pc
            break
        end
    end
end