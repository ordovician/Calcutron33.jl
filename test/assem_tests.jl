datadir = joinpath(dirname(@__FILE__), "data")

@testset "Assembler tests" begin
    @testset "Only Labels" begin
        syms = open(readsymtable, joinpath(datadir, "labels-nocode.ct33"))
        ks = ["alpha", "epsilon", "gamma", "delta", "beta"]
        Base.haskey(key) = haskey(syms, key)
        @test all(haskey, ks)
    end
end