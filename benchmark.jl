using BenchmarkTools
using Tokens

function D1(v, h=1)
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

res_func_application = @benchmark D1($v)
res_matrix_conversion = @benchmark get_matrix($vₓ)

println()
println("Function application:")
display(res_func_application)
println()
println("Matrix conversion:")
display(res_matrix_conversion)
