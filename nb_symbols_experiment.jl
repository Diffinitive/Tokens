### A Pluto.jl notebook ###
# v0.17.7

using Markdown
using InteractiveUtils

# ╔═╡ 8b91198c-32f0-11eb-0090-23ce70fcf0ad
using Statistics

# ╔═╡ 64782676-3316-11eb-1b4d-5964b76bba1a
using SparseArrays

# ╔═╡ ac903eaa-32e7-11eb-20e9-1b9977c69afb
begin
	struct Token{T,D}
		name::Symbol
		coeff::T
		index::NTuple{D,Int}
	end
	
	Token{T}(name, index::Vararg{Int}) where T = Token(name, one(T), index)
	Token(name, index::Vararg{Int}) = Token{Float64}(name, index...)
	
	Base.zero(::Token{T}) where T = Token(Symbol(0), zero(T), ())
	
	Base.:*(a,b::Token) = Token(b.name,a*b.coeff,b.index)
	Base.:*(a::Token,b) = b*a
	Base.:/(a::Token,b) = Token(a.name,a.coeff/b,a.index)
	
	function Base.show(io::IO, t::Token)
		if !isone(t.coeff)
			print(io, t.coeff)
			print(io, "×")
		end
		print(io, string(t.name))
		if length(t.index) > 0 
			print(io,"["*join(t.index,",")*"]")
		end
	end
end

# ╔═╡ 6366974a-3311-11eb-0223-5fd68b958ba2
Token(:x,3,2)

# ╔═╡ 4ffc17b0-32e8-11eb-295f-0bb9a40f914a
begin
	struct TokenSum{T,D,N}
		terms::NTuple{N,Token{T,D}}
	end
	TokenSum(a...) = TokenSum(a)
	
	Base.zero(::Type{TokenSum{T,D,N}}) where {T,D,N} = TokenSum{T,D,0}(())
	Base.zero(::TokenSum{T,D,N}) where {T,D,N} = TokenSum{T,D,0}(())
	
	Base.:*(a, B::TokenSum) = TokenSum(a.*B.terms)
	Base.:*(A::TokenSum, b) = TokenSum(A.terms.*b)
	Base.:/(A::TokenSum, b) = TokenSum(A.terms./b)
end

# ╔═╡ c5a7894e-3318-11eb-39bb-471d61adac9e
zero(Token{Float64})

# ╔═╡ 4914588c-3318-11eb-3b43-1bf4495e3bd9
c = Token(:c,1)

# ╔═╡ 5a764f52-3318-11eb-2da7-2756a5e0e0a3
zero(c)

# ╔═╡ 447ea418-32e8-11eb-2e0b-d1820db5f0c0
begin
	Base.:+(a::Token, b::Token) = TokenSum(a, b)
	Base.:+(a::Token, B::TokenSum) = TokenSum(a, B.terms...)
	Base.:+(A::TokenSum, b::Token) = TokenSum(A.terms..., b)
	Base.:+(A::TokenSum, B::TokenSum) = TokenSum(A.terms..., B.terms...) 
end

# ╔═╡ a036dabc-32ea-11eb-00fe-59b925dc881b
begin
	Base.:-(a::Token) = Token(a.name,-a.coeff, a.index)
	Base.:-(ts::TokenSum) = TokenSum(ts.name,Base.:-.(ts.terms))
	
	Base.:-(a::Token, b) = a + (-b)
	Base.:-(a::TokenSum, b) = a + (-b)
end

# ╔═╡ caa37088-32e7-11eb-3a84-412e2a39f47a
begin
	struct TokenArray{T,D} <:AbstractArray{Token{T,D},D}
		name::Symbol
		size::NTuple{D,Int}
	end
	
	TokenArray{T}(name, sz::Vararg{Int,D}) where {T,D} = TokenArray{T,D}(name,sz)
	TokenArray(name, sz::Vararg{Int}) = TokenArray{Float64}(name,sz...)
	
	Base.size(tv::TokenArray) = tv.size
	Base.getindex(tv::TokenArray{T,D}, I::Vararg{Int,D}) where {T,D} = Token{T}(tv.name, I...)
end

# ╔═╡ da682c44-3313-11eb-1e02-b9e3a4474294
# begin
# 	struct TokenTensor()
# 		name::Symbol
		
# 	end
	
# end

# ╔═╡ 313767a4-32f3-11eb-004f-792bd4ef7813
function get_matrix(y::AbstractArray{<:TokenSum}, x::TokenArray)
	M = zeros(size(y)..., size(x)...)
	
	for i ∈ CartesianIndices(y)
		ts = y[i]
		for t ∈ ts.terms
			j = t.index
			M[Tuple(i)..., j...] = t.coeff
		end
	end
	
	return M
end

# ╔═╡ 714a98ca-3320-11eb-3c4a-af380043ab62
md"""
To be able to solve for 2d operators we need to support sparsity patterns in TokenArray
"""

# ╔═╡ 86e8ecf0-32ed-11eb-3c04-13b85d4309c4
TokenArray(:v,2,4)

# ╔═╡ a5e9101c-32e8-11eb-2b3b-1179435b3edf
a = Token(:x,2, (1,2,3))

# ╔═╡ cdcfce70-3317-11eb-3092-35f89a0e566a
a+a

# ╔═╡ c077e37a-3317-11eb-010d-3bb84ecdc103
zero(a+a)

# ╔═╡ a7fad7e0-32f0-11eb-3ac6-2b9ac6ea0e8e
a*2

# ╔═╡ 07ca6cce-32ec-11eb-168d-f59428f6a5b4
2*a

# ╔═╡ d44c56fa-32f0-11eb-1f78-4ffdf685ab53
a/4

# ╔═╡ 6a9e864c-32f0-11eb-2c45-c782f5fd856f
mean(TokenArray(:x,4))

# ╔═╡ 4a362976-32ed-11eb-177f-21b3bb68831c
2*(a+a)

# ╔═╡ 610a3562-3300-11eb-20a6-61421033312b
function cdiff!(Dv,v,h)
	n = length(v)
	
	Dv[1] = (v[2]-v[1])/h
	
	for i ∈ 2:n-1
		Dv[i] = (v[i+1] - v[i-1])/2h
	end
	
	Dv[n] = (v[n] - v[n-1])/h

	return Dv
end

# ╔═╡ 1ec1509e-3302-11eb-3783-41297f66d1c9
let
	x = TokenArray(:x,10)
	y = Array{Any}(zeros(10))
	y = cdiff!(y,x,0.1)
	y = Array{TokenSum}(y)
	
	M = get_matrix(y,x)
end

# ╔═╡ 05968c52-3306-11eb-385b-7bff76a51711
Array{Any}(zeros(10))

# ╔═╡ cee71c40-32fa-11eb-33fd-2f9790992067
let
	x = TokenArray(:x,3)
	A = rand(3,3)
	y = A*x
	
	# M = get_matrix(y,x)
end

# ╔═╡ 724c1f34-3317-11eb-0f38-f93e147c0caf
A = spzeros(TokenSum, 10,10)

# ╔═╡ 85333b84-3317-11eb-34a8-0fd0cf0c92e0
A[1,1] = a+a

# ╔═╡ 124d8ef0-3318-11eb-0b27-dd4f533ccdd3
A[1,1]

# ╔═╡ 4be40262-3319-11eb-2773-c90e2dbc53f9
A[2,2]

# ╔═╡ 00000000-0000-0000-0000-000000000001
PLUTO_PROJECT_TOML_CONTENTS = """
[deps]
SparseArrays = "2f01184e-e22b-5df5-ae63-d93ebab69eaf"
Statistics = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"
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

[[deps.Statistics]]
deps = ["LinearAlgebra", "SparseArrays"]
uuid = "10745b16-79ce-11e8-11f9-7d13ad32a3b2"

[[deps.libblastrampoline_jll]]
deps = ["Artifacts", "Libdl", "OpenBLAS_jll"]
uuid = "8e850b90-86db-534c-a0d3-1478176c7d93"
"""

# ╔═╡ Cell order:
# ╠═ac903eaa-32e7-11eb-20e9-1b9977c69afb
# ╠═6366974a-3311-11eb-0223-5fd68b958ba2
# ╠═c5a7894e-3318-11eb-39bb-471d61adac9e
# ╠═4ffc17b0-32e8-11eb-295f-0bb9a40f914a
# ╠═cdcfce70-3317-11eb-3092-35f89a0e566a
# ╠═4914588c-3318-11eb-3b43-1bf4495e3bd9
# ╠═5a764f52-3318-11eb-2da7-2756a5e0e0a3
# ╠═c077e37a-3317-11eb-010d-3bb84ecdc103
# ╠═447ea418-32e8-11eb-2e0b-d1820db5f0c0
# ╠═a036dabc-32ea-11eb-00fe-59b925dc881b
# ╠═caa37088-32e7-11eb-3a84-412e2a39f47a
# ╠═da682c44-3313-11eb-1e02-b9e3a4474294
# ╠═313767a4-32f3-11eb-004f-792bd4ef7813
# ╠═714a98ca-3320-11eb-3c4a-af380043ab62
# ╠═86e8ecf0-32ed-11eb-3c04-13b85d4309c4
# ╠═a5e9101c-32e8-11eb-2b3b-1179435b3edf
# ╠═a7fad7e0-32f0-11eb-3ac6-2b9ac6ea0e8e
# ╠═07ca6cce-32ec-11eb-168d-f59428f6a5b4
# ╠═d44c56fa-32f0-11eb-1f78-4ffdf685ab53
# ╠═8b91198c-32f0-11eb-0090-23ce70fcf0ad
# ╠═6a9e864c-32f0-11eb-2c45-c782f5fd856f
# ╠═4a362976-32ed-11eb-177f-21b3bb68831c
# ╠═610a3562-3300-11eb-20a6-61421033312b
# ╠═1ec1509e-3302-11eb-3783-41297f66d1c9
# ╠═05968c52-3306-11eb-385b-7bff76a51711
# ╠═cee71c40-32fa-11eb-33fd-2f9790992067
# ╠═64782676-3316-11eb-1b4d-5964b76bba1a
# ╠═724c1f34-3317-11eb-0f38-f93e147c0caf
# ╠═85333b84-3317-11eb-34a8-0fd0cf0c92e0
# ╠═124d8ef0-3318-11eb-0b27-dd4f533ccdd3
# ╠═4be40262-3319-11eb-2773-c90e2dbc53f9
# ╟─00000000-0000-0000-0000-000000000001
# ╟─00000000-0000-0000-0000-000000000002
