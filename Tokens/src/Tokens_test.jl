using Test
using Tokens
using Tokens: _to_matrix
using SparseArrays

@testset "ScalarToken" begin
    @test ScalarToken(:a) isa Token

    @test repr("text/plain", ScalarToken(:a)) == "a"
    @test repr("text/plain", ScalarToken(:name)) == "name"

    @test ScalarToken(:a) == ScalarToken(:a)
    @test ScalarToken(:b) != ScalarToken(:a)

    @testset "terms" begin
        @test terms(ScalarToken(:a)) == (ScalarToken(:a)=>1,)
        @test terms(ScalarToken(:b)) == (ScalarToken(:b)=>1,)
    end
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

    @testset "index" begin
        @test index(IndexedToken(:v, 1)) == (1,)
        @test index(IndexedToken(:w, 2,1)) == (2,1)
    end

    @testset "terms" begin
        @test terms(IndexedToken(:v, 1)) == (IndexedToken(:v, 1)=>1,)
        @test terms(IndexedToken(:w, 2,1)) == (IndexedToken(:w, 2, 1)=>1,)
    end
end

@testset "LinearCombination" begin
    a = ScalarToken(:a)
    b = ScalarToken(:b)
    c = ScalarToken(:c)

    @test repr("text/plain", LinearCombination()) == "0"

    @test a + b isa LinearCombination
    @test repr("text/plain", a+b) == "a + b"
    @test repr("text/plain", b+a) == "a + b"


    @test 2a isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", 2a) == "2*a"

    @test 2a+b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", 2a+b) == "2*a + b"

    @test -2a+b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", -2a+b) == "-2*a + b"

    @test 2a - b isa LinearCombination{ScalarToken, Int}
    @test_broken repr("text/plain", -2a+b) == "2*a - b"


    @test 2.0a isa LinearCombination{ScalarToken, Float64}
    @test repr("text/plain", 2.0a) == "2.0*a"

    @test 2.0a+b isa LinearCombination{ScalarToken, Float64}
    @test repr("text/plain", 2.0a+b) == "2.0*a + b"


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

    @testset "terms" begin
        @test issetequal(terms(2a), [a=>2])
        @test issetequal(terms(a+b), [a=>1, b=>1])
        @test issetequal(terms(a+2b+3c), [a=>1, b=>2, c=>3])
    end

    @testset "type stability" begin
        a = ScalarToken(:a)
        l = 1a
        @inferred l.d[a]
    end
end

@testset "convert" begin
    a = ScalarToken(:a)
    b = ScalarToken(:b)
    c = ScalarToken(:c)
    v = ArrayToken(:v, 4)

    function test_convert(a, T, aT)
        @test convert(T, a) isa T
        @test convert(T, a) == aT
    end

    @testset test_convert(a, LinearCombination{ScalarToken, Int}, 1a)
    @testset test_convert(a, LinearCombination{ScalarToken, Float64}, 1.0a)

    @testset test_convert(v[1], LinearCombination{IndexedToken, Int}, 1v[1])
    @testset test_convert(v[2], LinearCombination{IndexedToken, Float64}, 1.0v[2])
end

@testset "to_matrix" begin
    @testset "vector of linear combinations" begin
        @test _to_matrix(LinearCombination[], 0, 0) == spzeros(0,0)

        @test _to_matrix([1IndexedToken(:v,1)], 1, 1) == sparse(ones(1,1))
        @test _to_matrix([2IndexedToken(:v,1)], 1, 1) == sparse(2ones(1,1))

        v = ArrayToken(:v, 2)
        @test _to_matrix([v[1]+2v[2], -v[2]], 2, 2) == sparse([
            1 2;
            0 -1;
        ])

        v = ArrayToken(:v, 3)
        @test _to_matrix([v[1]+v[2], v[2]+v[3]], 2, 3) == sparse([
            1 1 0;
            0 1 1;
        ])

        v = ArrayToken(:v, 2)
        @test _to_matrix([v[1]+v[2], v[2], -v[1]], 3, 2) == sparse([
             1 1;
             0 1;
            -1 0;
        ])

        v = ArrayToken(:v, 3)
        @test _to_matrix([v[1], v[2], v[3]], 3, 3) == sparse([
            1 0 0;
            0 1 0;
            0 0 1;
        ])

        v = ArrayToken(:v, 3)
        @test _to_matrix([zero(Token), v[2], zero(Token)], 3, 3) == sparse([
            0 0 0;
            0 1 0;
            0 0 0;
        ])

        v = ArrayToken(:v, 3)
        @test _to_matrix([zero(Token), v[2]+v[1], zero(Token)], 3, 3) == sparse([
            0 0 0;
            1 1 0;
            0 0 0;
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
        @test Array(to_matrix(example_function,4, 4)) == [
              -1    1   0   0;
            -1/2    0 1/2   0;
               0 -1/2   0 1/2;
               0    0  -1   1;
        ]

    end
end
