export readsymtable, assemble, disassemble

using InteractiveUtils

"""
    readsymtable(io::IO)
    
Assume there is some Calcutron33 (Ct33) assembly code on the `io` input
and reads it looking for labels. Below you can see an example of Ct33 assembly
code with the labels `loop`, `second` and `first`. 

    loop:
        INP x1
        INP x2
        SUB x1, x1, x2
        BGT x1, first

    second:
        OUT x2
        BRA loop
    
    first:
        OUT x1
        BRA loop      
"""
function readsymtable(io::IO)
    labels = Dict{String, String}()
    address = 0
    while !eof(io)
        line = readline(io)
        words = split(line)
        if isempty(words)
            continue
        end
        
        label = words[1]
        
        if endswith(label, ':')
            labels[label[1:end-1]] = lpad(address, 2, '0')
            # if label is on separate line, then we can't increase address
            if length(words) == 1
                continue
            end
        end
        
        address += 1
    end
    labels
end

readsymtable(filename::AbstractString) = open(readsymtable, filename)

# Standard names for registers as well as user created ones
regnames = Dict("x$n" => n for n in 1:9)

const mnemonics = ["ADD", "SUB", "SUBI", "LSH", "RSH", "BRZ", "BGT", "LD", "ST"]
to_machinecode(mnemonic) = findfirst(==(mnemonic), mnemonics)

function to_address(label::AbstractString, labels::Dict)
    if haskey(regnames, label)
        return label
    end
    
    if all(isnumeric, label)
        return label
    end
    
    labels[label]
end

function writeoperands(io::IO, labels::Dict, rd, rs, offset)
    print(io, regnames[rd], regnames[rs])
    if all(isnumeric, offset)
        print(io, offset)
    else
        print(io, regnames[offset])    
    end
end

function writeoperands(io::IO, labels::Dict, rd, src)
    print(io, regnames[rd])
    if all(isnumeric, src)
        print(io, src)
    elseif haskey(regnames, src)
        print(io, regnames[rd])
        print(io, regnames[src])
    else
        print(io, labels[src])  
    end 
end

function assemble(filename::AbstractString; kwargs...)
    open(filename) do io
        assemble(io; kwargs...)
    end
end

function readfile(fn::Function, outfile::AbstractString, infile::AbstractString; kwargs...)
    outs = open(outfile, "w")
    readfile(fn, outs, infile; kwargs...)
    close(outs)    
end

function readfile(fn::Function, outs::IO, infile::AbstractString; kwargs...)
    ins  = open(infile)
    fn(outs, ins; kwargs...)
    close(ins)
end

function assemble(out, infile::AbstractString; kwargs...)
    readfile(assemble, out, infile; kwargs...)
end

function disassemble(out, infile::AbstractString; kwargs...)
    readfile(disassemble, out, infile; kwargs...)
end


"""
Split up a line like:

    loop: ADD x1, x1 # doubling value
    
Into an array of all significant parts:

    ["ADD", "x1", "x1"]

We remove the label because you will not need it here.
"""
function splitup_code_line(line::AbstractString)
    codeline = split(line, in("#;/")) |> first |> strip
    words = split(codeline, in(" ,"), keepempty=false)
    
    if !isempty(words) && endswith(words[1], ':')
        words[2:end]
    else
        words    
    end   
end


function assemble(codebuf::IO, io::IO; verbose=false)
    mark(io) # remember position in stream
    labels = readsymtable(io)
    reset(io) # Get back to mark, so we can read file over again
    
    for line in eachline(io)
        words = splitup_code_line(line)
        
        if isempty(words)
            continue
        end
                        
        mnemonic = uppercase(words[1])
        
        if mnemonic == "DAT"
            print(codebuf, lpad(words[2], 4, '0'))
        elseif mnemonic == "HLT"
            print(codebuf, "0000")
        else
            # Finally regular assembly to deal with
            operands = words[2:end]
            rd = operands[1]
        
            machinecode = to_machinecode(mnemonic)
            if machinecode != nothing
                print(codebuf, machinecode)
                writeoperands(codebuf, labels, operands...)
                
            # Pseudo instructions
            elseif "INP" == mnemonic
                print(codebuf, to_machinecode("LD"))
                print(codebuf, regnames[rd], "90")
            elseif "OUT" == mnemonic
                print(codebuf, to_machinecode("ST"))
                print(codebuf, regnames[rd], "91")
            elseif "MOV" == mnemonic
                print(codebuf, to_machinecode("ADD"))
                print(codebuf, regnames[rd], "0", regnames[operands[2]])
            elseif "CLR" == mnemonic
                print(codebuf, to_machinecode("ADD"))
                print(codebuf, regnames[rd], "00")
            elseif "DEC" == mnemonic
                print(codebuf, to_machinecode("SUB"))
                print(codebuf, regnames[rd], regnames[rd], '1')
            elseif "BRA" == mnemonic
                print(codebuf, to_machinecode("BRZ"))
                print(codebuf, '0', to_address(operands[1], labels))
            end            
        end
        
       
        verbose && print(codebuf, ": ", strip(line))
        
        println(codebuf)
    end
    
    nothing
end

assemble(io::IO; kwargs...) = assemble(stdout, io; kwargs...)

disassemble(filename::AbstractString; kwargs...) = open(disassemble, filename)
disassemble(;kwargs...) = disassemble(stdout, IOBuffer(clipboard()))

function disassemble(codebuf::IO, io::IO; verbose=false)
    for (i, rawline) in enumerate(eachline(io))
        line = strip(rawline)
        numeric = parse(Int, line[1])
        opcode = Opcode(numeric)
        print(codebuf, lpad(i-1, 2, '0'), ": ")
        
        if opcode == HLT
            println(codebuf, "HLT")
            continue
        end
        
        print(codebuf, rpad(mnemonics[numeric], 5), "x$(line[2])")

        if opcode in (BRZ, BGT, LD, ST)
            print(codebuf, ", ", line[3:4])
        elseif opcode in (SUBI, LSH, RSH)
            print(codebuf, ", x", line[3], ", ", line[4])            
        else
            print(codebuf, ", x", line[3], ", x", line[4])
        end
        
        println(codebuf)
    end
end

disassemble(io::IO; kwargs...) = disassemble(stdout, io; kwargs...)
