using Test
using Tokens
using SparseArrays

@testset "ScalarToken" begin
    @test ScalarToken('a') isa Token
    t = ScalarToken((1, "a"))
    @test t isa ScalarToken{Tuple{Int,String}}
    @test t.symbol === (1, "a")
    @test symbol(t) === t.symbol
    name_cases = (
        (Symbol, :name, :other, "name"),
        (Char, 'α', 'β', "α"),
        (String, "name", "other", "name"),
    )
    @testset "$T names" for (T, name, other, display_name) in name_cases
        token = ScalarToken(name)
        @test token isa ScalarToken{T}
        @test token.symbol == name
        @test symbol(token) == name
        @test repr("text/plain", token) == display_name
        @test token == ScalarToken(name)
        @test token != ScalarToken(other)
        @test terms(token) == (token=>1,)
    end
end

@testset "Token and array arithmetic" begin
    a = ScalarToken('a')
    b = ScalarToken('b')
    A = [2 -3; 0 4]
    @test a * A == [2a -3a; 0a 4a]
    @test A * a == [2a -3a; 0a 4a]

    t = a + b
    v = [1//2, -2//1]
    @test t * v == [1//2*(a+b), -2//1*(a+b)]
    @test v * t == [1//2*(a+b), -2//1*(a+b)]
end

@testset "Token division by a number" begin
    a = ScalarToken('a')
    @test a / 2 == 0.5a
    @test 2 \ a == 0.5a

    v = IndexedToken('v', 1)
    @test v / (2//3) == 3//2*v
    @test (2//3) \ v == 3//2*v

    @test (a + v) / (2//3) == 3//2*a + 3//2*v
    @test (2//3) \ (a + v) == 3//2*a + 3//2*v
end

@testset "ArrayToken" begin
    A = ArrayToken('A', 3, 3)
    @test A isa AbstractArray{IndexedToken{ScalarToken{Char},2}, 2}
    @test size(A) == (3, 3)

    @test A[1,2] isa Token
    @test repr("text/plain", A[1,2]) == "A[1,2]"
    @test repr("text/plain", A[3,3]) == "A[3,3]"

    @testset "type stability" begin
        v = ArrayToken('v', 10)
        @inferred v[1]
    end

    @testset "symbol" begin
        @test symbol(ArrayToken('A', 3, 3)) == 'A'
        @test symbol(ArrayToken('b', 3)) == 'b'
    end
end

@testset "IndexedToken" begin
    @test IndexedToken('v', 1) isa IndexedToken{ScalarToken{Char}, 1}
    @test IndexedToken('v', 1,2) isa IndexedToken{ScalarToken{Char}, 2}
    t = IndexedToken("v", 2)
    @test t isa IndexedToken{ScalarToken{String}, 1}
    @test symbol(t) == "v"
    @test index(t) == (2,)

    @testset "index" begin
        @test index(IndexedToken('v', 1)) == (1,)
        @test index(IndexedToken('w', 2,1)) == (2,1)
    end

    @testset "terms" begin
        @test terms(IndexedToken('v', 1)) == (IndexedToken('v', 1)=>1,)
        @test terms(IndexedToken('w', 2,1)) == (IndexedToken('w', 2, 1)=>1,)
    end

    @testset "symbol" begin
        @test symbol(ArrayToken('v', 3)[2]) == 'v'
        @test symbol(ArrayToken('w', 2)[1]) == 'w'
    end
end

@testset "LinearCombination" begin
    a = ScalarToken('a')
    b = ScalarToken('b')
    c = ScalarToken('c')

    @test LinearCombination(a=>1) == LinearCombination(Dict(a=>1))
    @test LinearCombination(a=>2, b=>3) == LinearCombination(Dict(a=>2, b=>3))

    @test repr("text/plain", LinearCombination{Token,Int}()) == "0"

    @test a + b isa LinearCombination
    @test repr("text/plain", a+b) == "a + b"
    @test repr("text/plain", b+a) == "a + b"


    @test 2a isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", 2a) == "2a"

    @test 2a+b isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", 2a+b) == "2a + b"

    @test -2a+b isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", -2a+b) == "-2a + b"

    @test 2a - b isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", 2a-b) == "2a - b"

    @test a - b isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", a-b) == "a - b"

    @test a - 2b isa LinearCombination{ScalarToken{Char}, Int}
    @test repr("text/plain", a-2b) == "a - 2b"

    @test 2.0a isa LinearCombination{ScalarToken{Char}, Float64}
    @test repr("text/plain", 2.0a) == "2.0a"

    @test 2.0a+b isa LinearCombination{ScalarToken{Char}, Float64}
    @test repr("text/plain", 2.0a+b) == "2.0a + b"


    v = ArrayToken('v',15)
    @test repr("text/plain", v[1]+v[2]+v[3]) == "v[1] + v[2] + v[3]"
    @test repr("text/plain", v[10]+v[11]+v[12]) == "v[10] + v[11] + v[12]"
    @test repr("text/plain", v[9]+v[10]+v[11]) == "v[9] + v[10] + v[11]"

    @test repr("text/plain", a + v[1]) == "a + v[1]"
    @test repr("text/plain", v[1] + ScalarToken('w')) == "v[1] + w"

    @test termtype(2.0a) == ScalarToken{Char}
    @test termtype(2a) == ScalarToken{Char}
    @test termtype(LinearCombination{ScalarToken{Char}, Float64}) == ScalarToken{Char}

    @test weighttype(2.0a) == Float64
    @test weighttype(2a) == Int64
    @test weighttype(LinearCombination{ScalarToken{Char}, Float64}) == Float64

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

        @test 2(a+b) == LinearCombination(a=>2, b=>2)
        @test .2(a+b) == LinearCombination(a=>.2, b=>.2)
        @test (a+b)/2 == LinearCombination(a=>.5, b=>.5)
        @test (a+b)/.5 == LinearCombination(a=>2.0, b=>2.0)

        @test 2*LinearCombination(a=>1., b=>2.) == LinearCombination(a=>2., b=>4.)
        @test LinearCombination(a=>1) + LinearCombination(b=>1.) == LinearCombination(a=>1., b=>1.)
    end

    @testset "zero" begin
        z = zero(Token)

        @test z + z  == z
        @test 1a + z == 1a

        @test zero(ScalarToken{Char}) == z
        @test zero(ScalarToken('a')) == z

        @test zeros(Token, 3) == [z,z,z]

        @test zero(LinearCombination{ScalarToken{Char},Int}) isa LinearCombination{ScalarToken{Char},Int}
        @test zero(LinearCombination{ScalarToken{Char},Float64}) isa LinearCombination{ScalarToken{Char},Float64}

        z = zero(LinearCombination{ScalarToken{Char},Int})
        @test z + z  == z
        @test 1a + z == 1a
        @test zero(ScalarToken{Char}) == z
        @test zero(ScalarToken('a')) == z
    end

    @testset "terms" begin
        @test issetequal(terms(2a), [a=>2])
        @test issetequal(terms(a+b), [a=>1, b=>1])
        @test issetequal(terms(a+2b+3c), [a=>1, b=>2, c=>3])
    end

    @testset "type stability" begin
        a = ScalarToken('a')
        l = 1a
        @inferred l.d[a]
    end
end

@testset "convert" begin
    a = ScalarToken('a')
    b = ScalarToken('b')
    c = ScalarToken('c')
    v = ArrayToken('v', 4)

    T = typeof(v[1])
    cases = @NamedTuple{input, T, target}.([
        (a, LinearCombination{ScalarToken{Char}, Int}, 1a),
        (a, LinearCombination{ScalarToken{Char}, Float64}, 1.0a),

        (v[1], LinearCombination{IndexedToken, Int}, 1v[1]),
        (v[2], LinearCombination{IndexedToken, Float64}, 1.0v[2]),

        (v[1], LinearCombination{T, Int}, 1v[1]),
        (v[2], LinearCombination{T, Float64}, 1.0v[2]),

        (1a, LinearCombination{ScalarToken{Char}, Int}, 1a),
        (1a, LinearCombination{ScalarToken{Char}, Float64}, 1.0a),
        (1.0a, LinearCombination{ScalarToken{Char}, Int}, 1a),
        (1.0a, LinearCombination{ScalarToken{Char}, Float64}, 1.0a),

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
    @test promote_type(ScalarToken{Char}, LinearCombination{ScalarToken{Char}, Int}) == LinearCombination{ScalarToken{Char}, Int}
    @test promote_type(ScalarToken{Char}, LinearCombination{ScalarToken{Char}, Float64}) == LinearCombination{ScalarToken{Char}, Float64}

    @test promote_type(IndexedToken, LinearCombination{IndexedToken, Int}) == LinearCombination{IndexedToken, Int}
    @test promote_type(IndexedToken, LinearCombination{IndexedToken, Float64}) == LinearCombination{IndexedToken, Float64}

    @test promote_type(IndexedToken{ScalarToken{Char},1}, LinearCombination{IndexedToken{ScalarToken{Char},1}, Int}) == LinearCombination{IndexedToken{ScalarToken{Char},1}, Int}
    @test promote_type(IndexedToken{ScalarToken{Char},1}, LinearCombination{IndexedToken{ScalarToken{Char},1}, Float64}) == LinearCombination{IndexedToken{ScalarToken{Char},1}, Float64}

    @test promote_type(LinearCombination{IndexedToken,Int}, IndexedToken{ScalarToken{Char},1}) == LinearCombination{IndexedToken,Int}

    @test promote_type(LinearCombination{ScalarToken{Char}, Int}, LinearCombination{ScalarToken{Char},Float64}) == LinearCombination{ScalarToken{Char},Float64}
    @test promote_type(LinearCombination{IndexedToken, Int}, LinearCombination{IndexedToken,Float64}) == LinearCombination{IndexedToken,Float64}
    @test promote_type(LinearCombination{IndexedToken, Int}, LinearCombination{IndexedToken{ScalarToken{Char}},Float64}) == LinearCombination{IndexedToken,Float64}
end


@testset "token array construction" begin
    a = ScalarToken('a')
    b = ScalarToken('b')
    c = ScalarToken('c')

    @test eltype([a,b,c]) == ScalarToken{Char}
    @test eltype([a+b,b, c]) == LinearCombination{ScalarToken{Char}, Int}
    @test eltype([a+b,b, 1.0c]) == LinearCombination{ScalarToken{Char}, Float64}
    @test eltype([zero(ScalarToken{Char}), a, c]) == LinearCombination{ScalarToken{Char}, Int}
    @test eltype([zero(ScalarToken{Char}), a, 1.0c]) == LinearCombination{ScalarToken{Char}, Float64}
    @test eltype([zero(ScalarToken{Char}), a+b, c]) == LinearCombination{ScalarToken{Char}, Int}
    @test eltype([zero(ScalarToken{Char}), a+b, 1.0c]) == LinearCombination{ScalarToken{Char}, Float64}
end

