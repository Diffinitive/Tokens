function to_matrix(f, n, m=n)
    v = ArrayToken(:v, m)
    w = f(v)
    return _to_matrix(w, n, m)
end

# To simplify writing of tests
function _to_matrix(v::AbstractArray{<:Token}, n, m)
    I = Int[]
    J = Int[]

    V = Union{}[]

    for i ∈ eachindex(v)
        for (e,λ) ∈ terms(v[i])
            push!(I, i)
            push!(J, index(e)[1])

            try
                push!(V, λ)
            catch
                T = Base.promote_typejoin(eltype(V), typeof(λ))
                V = convert(Vector{T}, V)
                push!(V,λ)
            end
        end
    end

    return sparse(I, J, V, n, m)
end
