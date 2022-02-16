using BenchmarkTools
using Tokens

function D1(v, h)
    N = length(v)
    vₓ = similar(v)

    vₓ[1] = (v[2] - v[1])/h

    for i ∈ 2:N-1
       vₓ[i] = (v[i+1] - v[i-1])/2h
    end

    vₓ[N] = (v[N] - v[N-1])/h

    return vₓ
end

v = ArrayToken(:v, 4000);
vₓ = D1(v,1)

bd1 = @benchmark D1($v,1)
bget_matrix = @benchmark get_matrix($vₓ)

display(bd1)
display(bget_matrix)
