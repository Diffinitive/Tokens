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


    @testset "symbol" begin
        @test symbol(ScalarToken(:a)) == :a
        @test symbol(ScalarToken(:abc)) == :abc
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

    @testset "symbol" begin
        @test symbol(ArrayToken(:A, 3, 3)) == :A
        @test symbol(ArrayToken(:b, 3)) == :b
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

    @testset "symbol" begin
        @test symbol(ArrayToken(:v, 3)[2]) == :v
        @test symbol(ArrayToken(:w, 2)[1]) == :w
    end
end

@testset "LinearCombination" begin
    a = ScalarToken(:a)
    b = ScalarToken(:b)
    c = ScalarToken(:c)

    @test LinearCombination(a=>1) == LinearCombination(Dict(a=>1))
    @test LinearCombination(a=>2, b=>3) == LinearCombination(Dict(a=>2, b=>3))

    @test repr("text/plain", LinearCombination{Token,Int}()) == "0"

    @test a + b isa LinearCombination
    @test repr("text/plain", a+b) == "a + b"
    @test repr("text/plain", b+a) == "a + b"


    @test 2a isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", 2a) == "2a"

    @test 2a+b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", 2a+b) == "2a + b"

    @test -2a+b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", -2a+b) == "-2a + b"

    @test 2a - b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", 2a-b) == "2a - b"

    @test a - b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", a-b) == "a - b"

    @test a - 2b isa LinearCombination{ScalarToken, Int}
    @test repr("text/plain", a-2b) == "a - 2b"

    @test 2.0a isa LinearCombination{ScalarToken, Float64}
    @test repr("text/plain", 2.0a) == "2.0a"

    @test 2.0a+b isa LinearCombination{ScalarToken, Float64}
    @test repr("text/plain", 2.0a+b) == "2.0a + b"


    v = ArrayToken(:v,15)
    @test repr("text/plain", v[1]+v[2]+v[3]) == "v[1] + v[2] + v[3]"
    @test repr("text/plain", v[10]+v[11]+v[12]) == "v[10] + v[11] + v[12]"
    @test repr("text/plain", v[9]+v[10]+v[11]) == "v[9] + v[10] + v[11]"

    @test repr("text/plain", a + v[1]) == "a + v[1]"
    @test repr("text/plain", v[1] + ScalarToken(:w)) == "v[1] + w"

    @test termtype(2.0a) == ScalarToken
    @test termtype(2a) == ScalarToken
    @test termtype(LinearCombination{ScalarToken, Float64}) == ScalarToken

    @test weighttype(2.0a) == Float64
    @test weighttype(2a) == Int64
    @test weighttype(LinearCombination{ScalarToken, Float64}) == Float64

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

    @testset "arithmetic" begin
        @test a-b == LinearCombination(a=>1, b=>-1)
        @test a+b == LinearCombination(a=>1, b=>1)
        @test -(a+b) == LinearCombination(a=>-1, b=>-1)
        @test (a+b) + a == LinearCombination(a=>2, b=>1)
        @test (a+b) - a == LinearCombination(a=>0, b=>1)
        @test a-(a+b) == LinearCombination(a=>0, b=>-1)
        @test a+(a+b) == LinearCombination(a=>2, b=>1)
        @test (a+b) + (b+c) == LinearCombination(a=>1, b=>2, c=>1)
        @test (a-b) + (b-c) == LinearCombination(a=>1, b=>0, c=>-1)
        @test (a+b) - (b+c) == LinearCombination(a=>1, b=>0, c=>-1)
        @test (c-b) - (b-a) == LinearCombination(a=>1, b=>-2, c=>1)

        @test 1a+1b == LinearCombination(a=>1, b=>1)
        @test 1a-1b == LinearCombination(a=>1, b=>-1)
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

    T = typeof(v[1])
    cases = @NamedTuple{input, T, target}.([
        (a, LinearCombination{ScalarToken, Int}, 1a),
        (a, LinearCombination{ScalarToken, Float64}, 1.0a),

        (v[1], LinearCombination{IndexedToken, Int}, 1v[1]),
        (v[2], LinearCombination{IndexedToken, Float64}, 1.0v[2]),

        (v[1], LinearCombination{T, Int}, 1v[1]),
        (v[2], LinearCombination{T, Float64}, 1.0v[2]),

        (1a, LinearCombination{ScalarToken, Int}, 1a),
        (1a, LinearCombination{ScalarToken, Float64}, 1.0a),
        (1.0a, LinearCombination{ScalarToken, Int}, 1a),
        (1.0a, LinearCombination{ScalarToken, Float64}, 1.0a),

        (1v[1], LinearCombination{T, Int}, 1v[1]),
        (1v[1], LinearCombination{T, Float64}, 1.0v[1]),
        (1.0v[1], LinearCombination{T, Int}, 1v[1]),
        (1.0v[1], LinearCombination{T, Float64}, 1.0v[1]),
    ])

    @testset "convert($(c.T), $(c.input))" for c ∈ cases
        @test convert(c.T, c.input) isa c.T
        @test convert(c.T, c.input) == c.target
    end
end

@testset "promotion" begin
    @test promote_type(ScalarToken, LinearCombination{ScalarToken, Int}) == LinearCombination{ScalarToken, Int}
    @test promote_type(ScalarToken, LinearCombination{ScalarToken, Float64}) == LinearCombination{ScalarToken, Float64}

    @test promote_type(IndexedToken, LinearCombination{IndexedToken, Int}) == LinearCombination{IndexedToken, Int}
    @test promote_type(IndexedToken, LinearCombination{IndexedToken, Float64}) == LinearCombination{IndexedToken, Float64}

    @test promote_type(IndexedToken{ScalarToken,1}, LinearCombination{IndexedToken{ScalarToken,1}, Int}) == LinearCombination{IndexedToken{ScalarToken,1}, Int}
    @test promote_type(IndexedToken{ScalarToken,1}, LinearCombination{IndexedToken{ScalarToken,1}, Float64}) == LinearCombination{IndexedToken{ScalarToken,1}, Float64}

    @test promote_type(LinearCombination{IndexedToken,Int}, IndexedToken{ScalarToken,1}) == LinearCombination{IndexedToken,Int}

    @test promote_type(LinearCombination{ScalarToken, Int}, LinearCombination{ScalarToken,Float64}) == LinearCombination{ScalarToken,Float64}
    @test promote_type(LinearCombination{IndexedToken, Int}, LinearCombination{IndexedToken,Float64}) == LinearCombination{IndexedToken,Float64}
    @test promote_type(LinearCombination{IndexedToken, Int}, LinearCombination{IndexedToken{ScalarToken},Float64}) == LinearCombination{IndexedToken,Float64}
end


@testset "token array construction" begin
    a = ScalarToken(:a)
    b = ScalarToken(:b)
    c = ScalarToken(:c)

    @test eltype([a,b,c]) == ScalarToken
    @test eltype([a+b,b, c]) == LinearCombination{ScalarToken, Int}
    @test eltype([a+b,b, 1.0c]) == LinearCombination{ScalarToken, Float64}
    @test eltype([zero(ScalarToken), a, c]) == LinearCombination{ScalarToken, Int}
    @test eltype([zero(ScalarToken), a, 1.0c]) == LinearCombination{ScalarToken, Float64}
    @test eltype([zero(ScalarToken), a+b, c]) == LinearCombination{ScalarToken, Int}
    @test eltype([zero(ScalarToken), a+b, 1.0c]) == LinearCombination{ScalarToken, Float64}
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
