module Tokens

using SparseArrays

export Token
export ScalarToken
export ArrayToken
export IndexedToken
export LinearCombination

export symbol
export terms
export index
export termtype
export weighttype

export to_matrix

abstract type Token end

Base.broadcastable(t::Token) = Ref(t)
Base.eltype(::Type{T}) where T<:Token = T # RecursiveArrayTools relies on this to give the correct element type of ArrayPartition()?

struct ScalarToken <: Token
    s::Symbol
end

terms(t::ScalarToken) = (t=>1,)

Base.show(io::IO, ::MIME"text/plain", t::ScalarToken) = print(io, t.s)

symbol(t::ScalarToken) = t.s

struct IndexedToken{T<:Token,D} <: Token
    t::T
    I::NTuple{D,Int}
end

IndexedToken(t::Token, I...) = IndexedToken{typeof(t),length(I)}(t,I)
IndexedToken(s::Symbol, I...) = IndexedToken(ScalarToken(s),I...)

index(t::IndexedToken) = t.I
terms(t::IndexedToken) = (t=>1,)
symbol(t::IndexedToken) = symbol(t.t)

function Base.show(io::IO, ::MIME"text/plain", t::IndexedToken)
    show(io, MIME"text/plain"(), t.t)
    print(io, "[")
    join(io, t.I, ",")
    print(io, "]")
end

struct ArrayToken{T<:Token, D} <: AbstractArray{IndexedToken{T,D},D}
    s::T
    size::NTuple{D,Int}
end

symbol(t::ArrayToken) = symbol(t.s)

ArrayToken(s, sz...) = ArrayToken(ScalarToken(s), sz)

Base.size(a::ArrayToken) = a.size

function Base.getindex(a::ArrayToken, I::Vararg{Int})
    checkbounds(a, I...)

    return IndexedToken(a.s, I...)
end

# For when when someone (show(::AbstractArray)) indexes a vector with two indecies.
function Base.getindex(a::ArrayToken{T,1} where T, i::Int,j::Int)
    checkbounds(a, i, j)

    return IndexedToken(a.s, i)
end

Base.similar(v::ArrayToken) = Base.similar(v, LinearCombination{eltype(v),Float64})

struct LinearCombination{T<:Token,S<:Number} <: Token
    d::Dict{T,S}
end

LinearCombination{T,S}() where {T,S} = LinearCombination(Dict{T,S}())
LinearCombination(t::Token) = LinearCombination(Dict(t=>1))
LinearCombination(terms::Vararg{Pair}) = LinearCombination(Dict(terms...))

termtype(::Type{LinearCombination{T,S}}) where {T,S} = T
termtype(t::LinearCombination) = termtype(typeof(t))

weighttype(::Type{LinearCombination{T,S}}) where {T,S} = S
weighttype(t::LinearCombination) = weighttype(typeof(t))

terms(t::LinearCombination) = t.d

Base.:(==)(a::LinearCombination, b::LinearCombination) = (a.d == b.d)

function Base.show(io::IO, mime::MIME"text/plain", lc::LinearCombination)
    if isempty(lc.d)
        print(io, "0")
        return
    end
    pairs = collect(lc.d)
    function sort_value(p)
        t = p[1]

        if t isa ScalarToken
            (symbol(t),)
        elseif t isa IndexedToken
            (symbol(t), index(t))
        end
    end
    sort!(pairs, by=sort_value)

    first, rest = Iterators.peel(pairs)
    show_term(io, mime, first)
    foreach(rest) do p
        if p[2] >= 0
            print(io, " + ")
            show_term(io, mime, p)
        else
            print(io, " - ")
            show_term(io, mime, p[1]=>-p[2])
        end
    end
end

function show_term(io::IO, mime, pair)
    t = pair[1]
    λ = pair[2]
    if isone(λ)
        show(io,mime,t)
    else
        show(io,mime, λ)
        show(io, mime, t)
    end
end

Base.:*(λ::Number, t::Token) = LinearCombination(Dict(t=>λ))
Base.:*(t::Token, λ::Number) = Base.:*(λ,t)
Base.:-(t::Token) = -1*t

function Base.:+(lc1::LinearCombination, lc2::LinearCombination)
    d = mergewith(+, lc1.d, lc2.d)
    return LinearCombination(d)
end

function Base.:-(lc1::LinearCombination, lc2::LinearCombination)
    d = _mergewith(-, lc1.d, lc2.d, zero(weighttype(lc1)))
    return LinearCombination(d)
end

# Base.mergewith only applies the combining function when the key is missing
# from one of the dicitionaries. This doesn't work if we want to subtract
# dicts.
function _mergewith(op, d1::AbstractDict, d2::AbstractDict, default)
    # Code below is taken from Base and modified
    d = Base._typeddict(d1,d2)
    for (k, v) in d2
        k = convert(keytype(d), k)
        d[k] = op(get(d1,k,default), d2[k])
    end
    return d
end





Base.:+(lc::LinearCombination, t::Token) = lc + LinearCombination(t)
Base.:+(t::Token, lc::LinearCombination) = LinearCombination(t) + lc
Base.:+(t1::Token, t2::Token) = LinearCombination(t1)+t2

Base.:-(lc::LinearCombination) = LinearCombination(Dict(k=>-v for (k,v) in lc.d))
Base.:-(t1::Token, t2::Token) = t1+(-t2)

Base.:*(δ::Number, lc::LinearCombination) = LinearCombination(Dict(k=>δ*v for (k,v) in lc.d))
Base.:*(lc::LinearCombination, δ::Number) = *(δ, lc)

Base.:/(lc::LinearCombination, δ::Number) = LinearCombination(Dict(k=>v/δ for (k,v) in lc.d))

Base.zero(T::Type{<:Token}) = LinearCombination{T,Int}()
Base.zero(T::Type{<:LinearCombination}) = LinearCombination{termtype(T), weighttype(T)}()
Base.zero(t::Token) = zero(typeof(t))


function Base.convert(L::Type{<:LinearCombination{T,S}}, t::T) where {T<:Token,S}
    return LinearCombination{T,S}(Dict(t=>one(S)))
end

function Base.convert(L::Type{<:LinearCombination{T,S}}, t::LinearCombination) where {T<:Token,S}
    return LinearCombination{T,S}(convert(Dict{T,S},t.d))
end

function Base.promote_rule(::Type{T1},::Type{LinearCombination{T2,S}}) where {T1<:Token, T2<:Token, S}
    T = promote_type(T1,T2)
    return LinearCombination{T,S}
end

function Base.promote_rule(::Type{LinearCombination{T1,S1}}, ::Type{LinearCombination{T2,S2}}) where {T1<:Token,T2<:Token,S1,S2}
    T = promote_type(T1,T2)
    S = promote_type(S1,S2)
    return LinearCombination{T,S}
end

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


end # module
