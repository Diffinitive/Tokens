using Test
using Tokens
using Tokens: _to_matrix
using SparseArrays

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

        ## Other types
        v = ArrayToken(:v, 3)
        Av = [1//1*v[1]+1//1*v[2], 1//1*v[2]+1//1*v[3]]
        @test eltype(_to_matrix(Av, 2, 3)) == Rational{Int}
        @test _to_matrix(Av, 2, 3) == sparse([
            1//1 1//1 0//1;
            0//1 1//1 1//1;
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

        @test to_matrix(example_function, 4) == to_matrix(example_function,4, 4)

    end
end
