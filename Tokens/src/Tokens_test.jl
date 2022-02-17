using Test
using Tokens
using SparseArrays

@testset "ScalarToken" begin
    @test ScalarToken(:a) isa Token

    @test repr("text/plain", ScalarToken(:a)) == "a"
    @test repr("text/plain", ScalarToken(:name)) == "name"

    @test ScalarToken(:a) == ScalarToken(:a)
    @test ScalarToken(:b) != ScalarToken(:a)
end

@testset "ArrayToken" begin
    A = ArrayToken(:A, 3, 3)
    @test A isa AbstractArray{IndexedToken{ScalarToken,2}, 2}
    @test size(A) == (3, 3)

    @test A[1,2] isa Token
    @test repr("text/plain", A[1,2]) == "A[1,2]"
    @test repr("text/plain", A[3,3]) == "A[3,3]"

    @testset "type stability" begin
        v = ArrayToken(:v, 10)
        @inferred v[1]
    end
end

@testset "IndexedToken" begin
    @test IndexedToken(:v, 1) isa IndexedToken{ScalarToken, 1}
    @test IndexedToken(:v, 1,2) isa IndexedToken{ScalarToken, 2}
end

@testset "LinearCombination" begin
    a = ScalarToken(:a)
    b = ScalarToken(:b)
    c = ScalarToken(:c)

    @test repr("text/plain", Tokens.LinearCombination()) == "0"

    @test a + b isa Tokens.LinearCombination
    @test repr("text/plain", a+b) == "a + b"
    @test repr("text/plain", b+a) == "a + b"


    @test 2a isa Tokens.LinearCombination
    @test repr("text/plain", 2a) == "2*a"

    @test 2a+b isa Tokens.LinearCombination
    @test repr("text/plain", 2a+b) == "2*a + b"

    @test -2a+b isa Tokens.LinearCombination
    @test repr("text/plain", -2a+b) == "-2*a + b"

    @test 2a - b isa Tokens.LinearCombination
    @test_broken repr("text/plain", -2a+b) == "2*a - b"

    @testset "equality" begin
        @test 1a == 1a
        @test 2a == 2a
        @test 1a != -1a
        @test 1a != 2a
        @test 1a != 1b

        @test (a+b) + (b+c) == a + 2b + c
        @test (a+b) + (b+c) != a + b + c
        @test (a+b) + (c+c) != a + 2b + c

        @test a-a == 0a
    end

    @testset "zero" begin
        z = zero(Token)

        @test z + z  == z
        @test 1a + z == 1a

        @test zero(ScalarToken) == z
        @test zero(ScalarToken(:a)) == z

        @test zeros(Token, 3) == [z,z,z]
    end

    @testset "type stability" begin
        a = ScalarToken(:a)
        l = 1a
        @inferred l.d[a]
    end
end

@testset "to_matrix" begin
    @testset "vector of linear combinations" begin
        @test to_matrix(Tokens.LinearCombination[]) == spzeros(0,0)

        @test to_matrix([1IndexedToken(:v,1)]) == sparse(ones(1,1))
        @test to_matrix([2IndexedToken(:v,1)]) == sparse(2ones(1,1))

        v = ArrayToken(:v, 2)
        @test to_matrix([v[1]+2v[2], -v[2]]) == sparse([
            1 2;
            0 -1;
        ])

        v = ArrayToken(:v, 3)
        @test to_matrix([v[1]+v[2], v[2]+v[3]]) == sparse([
            1 1 0;
            0 1 1;
        ])

        v = ArrayToken(:v, 2)
        @test_broken to_matrix([v[1]+v[2], v[2], -v[1]]) == sparse([
             1 1;
             0 1;
            -1 0;
        ])
    end

    function example_function(v, h=1)
        N = length(v)
        vₓ = similar(v)

        vₓ[1] = (v[2] - v[1])/h

        for i ∈ 2:N-1
            vₓ[i] = (v[i+1] - v[i-1])/2h
        end

        vₓ[N] = (v[N] - v[N-1])/h

        return vₓ
    end

    @testset "function" begin
        @test Array(to_matrix(example_function,4)) == [
              -1    1   0   0;
            -1/2    0 1/2   0;
               0 -1/2   0 1/2;
               0    0  -1   1;
        ]

    end
end
