using Tokens

using BenchmarkTools
using ProfileView

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

# More stencil like
function D2(v, h=1)
    N = length(v)
    vₓ = similar(v)

    vₓ[1] = (1v[1] - 2v[1] + 1v[3])/h

    for i ∈ 2:N-1
       vₓ[i] = (1v[i-1] -2v[i] + 1v[i-1])/2h
    end

    vₓ[N] = (1v[N-2] -2v[N-1] + 1v[N])/h

    return vₓ
end


function profile_run(N)
    for i ∈ 1:N
        to_matrix(D1,2000)
    end
end

profile_run(1)
@profview profile_run(100)
