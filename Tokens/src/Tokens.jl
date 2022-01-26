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

Base.show(io::IO, ::MIME"text/plain", t::ScalarToken) = print(io, t)
Base.print(io::IO, t::ScalarToken) = print(io, t.s)

struct IndexedToken <: Token
    t::Token
    I
end

IndexedToken(s,I) = IndexedToken(ScalarToken(s),I)

function Base.show(io::IO, ::MIME"text/plain", t::IndexedToken)
    print(io, t.t)
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

LinearCombination(t::Token) = LinearCombination(Dict(t=>1))

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

function get_matrix(v)
    N = length(v)
    A = spzeros(N,N)

    for i ∈ eachindex(v)
        for (e,λ) ∈ v[i].d
            A[i, e.I[1]] = λ
        end
    end

    return A
end

# TODO: add a zero token and a zero method to allow zeros(Token, N,N)
# TODO: change get_matrix to get_array or get_sparse_array and allow higher order tensors
# TODO: add function for getting all the tokens of an "expression".
# TODO: Clean up printing of negative terms in LinearCombination.
# TODO: Allow tests in src/

end # module
