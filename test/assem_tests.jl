datadir = joinpath(dirname(@__FILE__), "data")

@testset "Assembler tests" begin
    @testset "Only Labels" begin
        syms = open(readsymtable, joinpath(datadir, "labels-nocode.ct33"))
        ks = ["alpha", "epsilon", "gamma", "delta", "beta"]
        Base.haskey(key) = haskey(syms, key)
        @test all(haskey, ks)
    end
    
    @testset "Regression tests" begin
        files = readdir(datadir)
        paths = joinpath.(datadir, files)
        srcfiles = filter(endswith(".ct33"), paths)
        for src in srcfiles
            binary = replace(src, "ct33" => "machine")
            if !isfile(binary)
               error(binary, " file is missing")             
            end
            expected = read(binary, String)
            @test sprint(assemble, src) == expected
        end
    end
end