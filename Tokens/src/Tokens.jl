module Tokens

using SparseArrays

export Token
export ScalarToken
export ArrayToken
export IndexedToken

export get_matrix

abstract type Token end

struct ScalarToken <: Token
    s::Symbol
end

Base.show(io::IO, ::MIME"text/plain", t::ScalarToken) = print(io, t.s)

struct IndexedToken <: Token
    t::Token
    I
end

IndexedToken(s::Symbol, I) = IndexedToken(ScalarToken(s),I)

function Base.show(io::IO, ::MIME"text/plain", t::IndexedToken)
    show(io, MIME"text/plain"(), t.t)
    print(io, "[")
    join(io, t.I, ",")
    print(io, "]")
end

struct ArrayToken{D} <: AbstractArray{Token,D}
    s::Token
    size::NTuple{D,Int}
end

ArrayToken(s, sz...) = ArrayToken{length(sz)}(ScalarToken(s), sz)

Base.size(a::ArrayToken) = a.size

function Base.getindex(a::ArrayToken, I...)
    checkbounds(a, I...)

    return IndexedToken(a.s, I)
end

struct LinearCombination <: Token
    d::Dict{Token, Real}
end

LinearCombination() = LinearCombination(Dict{Token,Real}())
LinearCombination(t::Token) = LinearCombination(Dict(t=>1))

Base.:(==)(a::LinearCombination, b::LinearCombination) = all(==(p...) for p ∈ zip(a.d, b.d))

function Base.show(io::IO, mime::MIME"text/plain", lc::LinearCombination)
    pairs = collect(lc.d)
    sort!(pairs, by=p->string(p[1]))

    show_term(io, mime, pairs[1])
    for i ∈ 2:length(pairs)
        print(io, " + ")
        show_term(io, mime, pairs[i])
    end
end

function show_term(io::IO, mime, pair)
    t = pair[1]
    λ = pair[2]
    if isone(λ)
        show(io,mime,t)
    else
        show(io,mime,λ)
        print(io, "*")
        show(io, mime, t)
    end
end

function pair2string(p)
    t = p[1]
    λ = p[2]
    if isone(λ)
        return string(t)
    else
        return "$λ*$t"
    end
end

Base.:*(λ::Real, t::Token) = LinearCombination(Dict(t=>λ))
Base.:*(t::Token, λ::Real) = Base.:*(λ,t)
Base.:-(t::Token) = -1*t

function Base.:+(lc1::LinearCombination, lc2::LinearCombination)
    d = mergewith(+, lc1.d, lc2.d)
    return LinearCombination(d)
end

function Base.:-(lc1::LinearCombination, lc2::LinearCombination)
    d = mergewith(-, lc1.d, lc2.d)
    return LinearCombination(d)
end

Base.:-(lc::LinearCombination) = LinearCombination(Dict(k=>-v for (k,v) in lc.d))

Base.:+(lc::LinearCombination, t::Token) = lc + LinearCombination(t)
Base.:+(t::Token, lc::LinearCombination) = LinearCombination(t) + lc
Base.:+(t1::Token, t2::Token) = LinearCombination(t1)+t2

Base.:-(t1::Token, t2::Token) = t1+(-t2)

Base.:/(lc::LinearCombination, δ::Real) = LinearCombination(Dict(k=>v/δ for (k,v) in lc.d))

Base.zero(::Type{<:Token}) = LinearCombination()
Base.zero(::Token) = LinearCombination()

function get_matrix(v)
    v = Vector{LinearCombination}(v)

    I = Int[]
    J = Int[]
    V = Float64[]

    for i ∈ eachindex(v)
        for (e,λ) ∈ v[i].d
            push!(I, i)
            push!(J, e.I[1])
            push!(V, λ)
        end
    end

    return sparse(I,J,V)
end

# TODO: change get_matrix to get_array or get_sparse_array and allow higher order tensors
# TODO: add function for getting all the tokens of an "expression".
# TODO: Fix broken tests.

end # module
