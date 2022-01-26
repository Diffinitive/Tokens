### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ c9fe44ec-49d4-11eb-023a-2d887e9efdc5
using SparseArrays

# ╔═╡ 8d42817c-3d80-11eb-3889-d5deb0162e15
abstract type Token end

# ╔═╡ a91e2286-3ddd-11eb-3ebe-9d5236eac8f8
begin
	struct ScalarToken <: Token
		s::Symbol
	end
	
	Base.show(io::IO, ::MIME"text/plain", t::ScalarToken) = print(io, t)
	Base.print(io::IO, t::ScalarToken) = print(io, t.s)
end

# ╔═╡ 9c2a4e22-3d80-11eb-1fbb-85a257b34fc1
begin
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
end

# ╔═╡ 23146d14-3d81-11eb-1edf-2f4af38ce24f
begin
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
end

# ╔═╡ ce25db0c-3d81-11eb-1f50-3f37d06d68f8
begin
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
end

# ╔═╡ 0c89070c-3de6-11eb-2399-d108ce5e2d47
IndexedToken(:a,(1,2))

# ╔═╡ b893d32a-3de5-11eb-3683-f3ed39735bc7
a = ArrayToken(:a, 3)

# ╔═╡ 556f849e-3de8-11eb-355a-e3a8f9d6ce41
a[1]

# ╔═╡ 67a5440a-49c8-11eb-2878-5b58a5308570
dump(a[1])

# ╔═╡ 9ca7110c-3de7-11eb-201f-113c61f2e00b
ArrayToken(:a, 3,2)

# ╔═╡ e5d088b8-49d1-11eb-0a86-294e136b23fe
-a

# ╔═╡ d7e8237a-3dec-11eb-23bd-75df6d454f9c
x = ScalarToken(:x)

# ╔═╡ e63e5744-3dec-11eb-3129-d187918866da
y = ScalarToken(:y)

# ╔═╡ 0640b744-3ded-11eb-2009-2f0fd7b30a1c
z = x+2*y

# ╔═╡ a410b3b6-49c8-11eb-0d18-1d87a0d950b8
dump(z)

# ╔═╡ 490a50ac-49c9-11eb-0a62-fb39771c8b84
v = ArrayToken(:v, 10)

# ╔═╡ bf841c82-49c8-11eb-14a9-69253453f68f
function D1(v, h)
	N = length(v)
	vₓ = similar(v)
	
	vₓ[1] = (v[2] - v[1])/h
	
	for i ∈ 2:N-1
		vₓ[i] = (v[i+1] - v[i-1])/2h
	end
		
	vₓ[N] = (v[N] - v[N-1])/h
	
	return vₓ
end;

# ╔═╡ 6a40dd18-49c9-11eb-22f7-63445b566318
vₓ = D1(v,1)

# ╔═╡ 971ae9f6-49d2-11eb-20be-59e080aec06e
vₓ[1]

# ╔═╡ eaef5eee-49d3-11eb-252f-876c514c421f
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

# ╔═╡ af9facdc-49d4-11eb-2694-7b169fa80c3b
Array(get_matrix(vₓ))

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
"""

# ╔═╡ 00000000-0000-0000-0000-000000000002
PLUTO_MANIFEST_TOML_CONTENTS = """
# This file is machine-generated - editing it directly is not advised

julia_version = "1.7.1"
manifest_format = "2.0"

[[deps.Artifacts]]
uuid = "56f22d72-fd6d-98f1-02f0-08ddc0907c33"

[[deps.CompilerSupportLibraries_jll]]
deps = ["Artifacts", "Libdl"]
uuid = "e66e0078-7015-5450-92f7-15fbd957f2ae"

[[deps.Libdl]]
uuid = "8f399da3-3557-5675-b5ff-fb832c97cbdb"

[[deps.LinearAlgebra]]
deps = ["Libdl", "libblastrampoline_jll"]
uuid = "37e2e46d-f89d-539d-b4ee-838fcccc9c8e"

[[deps.OpenBLAS_jll]]
deps = ["Artifacts", "CompilerSupportLibraries_jll", "Libdl"]
uuid = "4536629a-c528-5b80-bd46-f80d51c5b363"

[[deps.Random]]
deps = ["SHA", "Serialization"]
uuid = "9a3f8284-a2c9-5f02-9a11-845980a1fd5c"

[[deps.SHA]]
uuid = "ea8e919c-243c-51af-8825-aaa63cd721ce"

[[deps.Serialization]]
uuid = "9e88b42a-f829-5b0c-bbe9-9e923198166b"

[[deps.SparseArrays]]
deps = ["LinearAlgebra", "Random"]
uuid = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
"""

# ╔═╡ Cell order:
# ╠═c9fe44ec-49d4-11eb-023a-2d887e9efdc5
# ╠═8d42817c-3d80-11eb-3889-d5deb0162e15
# ╠═a91e2286-3ddd-11eb-3ebe-9d5236eac8f8
# ╠═23146d14-3d81-11eb-1edf-2f4af38ce24f
# ╠═9c2a4e22-3d80-11eb-1fbb-85a257b34fc1
# ╠═ce25db0c-3d81-11eb-1f50-3f37d06d68f8
# ╠═0c89070c-3de6-11eb-2399-d108ce5e2d47
# ╠═b893d32a-3de5-11eb-3683-f3ed39735bc7
# ╠═556f849e-3de8-11eb-355a-e3a8f9d6ce41
# ╠═67a5440a-49c8-11eb-2878-5b58a5308570
# ╠═9ca7110c-3de7-11eb-201f-113c61f2e00b
# ╠═e5d088b8-49d1-11eb-0a86-294e136b23fe
# ╠═d7e8237a-3dec-11eb-23bd-75df6d454f9c
# ╠═e63e5744-3dec-11eb-3129-d187918866da
# ╠═0640b744-3ded-11eb-2009-2f0fd7b30a1c
# ╠═a410b3b6-49c8-11eb-0d18-1d87a0d950b8
# ╠═490a50ac-49c9-11eb-0a62-fb39771c8b84
# ╠═6a40dd18-49c9-11eb-22f7-63445b566318
# ╠═971ae9f6-49d2-11eb-20be-59e080aec06e
# ╠═af9facdc-49d4-11eb-2694-7b169fa80c3b
# ╠═bf841c82-49c8-11eb-14a9-69253453f68f
# ╠═eaef5eee-49d3-11eb-252f-876c514c421f
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
