### A Pluto.jl notebook ###
# v0.19.36

using Markdown
using InteractiveUtils

# ╔═╡ c9fe44ec-49d4-11eb-023a-2d887e9efdc5
begin
	using Pkg
	Pkg.activate(".")

	using Revise
	using Tokens

	using StaticArrays
	using BenchmarkTools
end

# ╔═╡ f00c228b-9fca-4d5a-8da2-ceb2ac228f86
md"""
The static vector approach might not work for large bandwidths since we start seeing allocation for some functions of static arrays. See for example `sort` (benchmarks below). This doesn't seem to be an inherent flaw of `StaticVector` though. See benchmark examples below
"""

# ╔═╡ 9568d8d3-fd75-41b9-b1dd-07d6b266630c
@benchmark sort($(@SVector rand(20)))

# ╔═╡ 7095e307-25e9-425d-8129-79dba8675d2a
@benchmark sort($(@SVector rand(21)))

# ╔═╡ a6e161f4-d34f-46fc-b894-7e18e97ead47
N = 30

# ╔═╡ eceef74f-2dcd-4a6f-89ac-884298639a3b


# ╔═╡ f72fd702-9b20-4611-821c-4daa22898142
function right_pad_tuple(t, val, N)
    if N < length(t)
        throw(DomainError(N, "Can't pad tuple of length $(length(t)) to $N elements"))
    end

    padding = ntuple(i->val, N-length(t))
    return (t..., padding...)
end

# ╔═╡ 8065d549-4537-4897-9a00-6f178742091a
begin
	struct StackAllocatedDict{K,V,N} <: AbstractDict{K,V}
	    pairs::NTuple{N,Pair{K,V}}
		n::Int  # Curret number of entries <= N

		function StackAllocatedDict(pairs::NTuple{N, Pair{K,V}}, n::Int)  where {K,V,N}
			return new{K,V,N}(pairs, n)
		end
		
	    function StackAllocatedDict{K,V,N}(pairs::Vararg{Pair}) where {K,V,N}
	        if !allunique(first.(pairs))
	            throw(DomainError(pairs, "keys must be unique"))
	        end

			n = length(pairs)
			pairs = right_pad_tuple(pairs, instance(K)=>instance(V), N)
	        return new{K,V,N}(pairs, n)
	    end
	end
	
	function StackAllocatedDict{N}(pairs::Vararg{Pair}) where N
	    K = typejoin(firsttype.(pairs)...)
	    V = typejoin(secondtype.(pairs)...)
	    return StackAllocatedDict{K,V,N}(pairs...)
	end

	# returns (I, ok)
	function get_key_index(d::StackAllocatedDict, key)
		for i ∈ 1:d.n
			k,v = d.pairs[i]
	        if key == k
	            return i, true
	        end
	    end

		return 0, false
	end

	# Assume the key does not already exist and add it at the end
	function instert(d::StackAllocatedDict, key, val)
		return StackAllocatedDict(
			Base.setindex(d.pairs, key=>val, d.n+1),
			d.n+1,
		)
	end
	
	function Base.get(d::StackAllocatedDict, key, default)
	    I, ok = get_key_index(d, key)
		if ok
			k,v = d.pairs[I]
			return v
		else
			return default
		end
	end

	function Base.setindex(d::StackAllocatedDict, val, key)
		I, ok = get_key_index(d, key)

		if ok
			return StackAllocatedDict(
				Base.setindex(d.pairs, key=>val, I),
				d.n,
			)
		else
			return StackAllocatedDict(
				Base.setindex(d.pairs, key=>val, d.n+1),
				d.n+1,
			)
		end
		
	end
	
	Base.iterate(d::StackAllocatedDict) = iterate(Iterators.take(d.pairs,d.n))
	Base.iterate(d::StackAllocatedDict, state) = iterate(Iterators.take(d.pairs,d.n),state)
	Base.length(d::StackAllocatedDict) = d.n
	
	
	"""
	    merge(d1::StaticDict, d2::StaticDict)
	
	Merge two `StaticDict`. Repeating keys is considered and error. This may
	change in a future version.
	"""
	function Base.merge(d1::StackAllocatedDict{K1,V1,N}, d2::StackAllocatedDict{K2,V2,N}) where {N, K1, K2, V1, V2}
	    return StackAllocatedDict{N}(d1.pairs..., d2.pairs...)
	end
	
	
	"""
	    firsttype(::Pair{T1,T2})
	
	The type of the first element in the pair.
	"""
	firsttype(::Pair{T1,T2}) where {T1,T2} = T1
	
	"""
	    secondtype(::Pair{T1,T2})
	
	The type of the secondtype element in the pair.
	"""
	secondtype(::Pair{T1,T2}) where {T1,T2}  = T2

	instance(T::Type{<:Number}) = zero(T)
	instance(::Type{Symbol}) = Symbol()
	instance(::Type{String}) = ""
end

# ╔═╡ 45a5e8ef-4687-46d5-9765-c6f2bfc8fe49
begin
	function basevector(n, ::Val{N}) where N
	   v = @SVector zeros(N)
	   v = Base.setindex(v, 1, n)
	   return v
   end

	@benchmark basevector($3,$(Val(100)))
end

# ╔═╡ 6e44ec44-99b7-41a3-be6e-70bc42c64fc0
d = StackAllocatedDict{N}([Int(k)=>Float64(k) for k ∈ 1:N]...)

# ╔═╡ 164e0d79-19f2-4002-addb-46b4ed26e3cb
d.n

# ╔═╡ 192fd601-2244-4c59-bdaf-a871b20c46b5
d[3]

# ╔═╡ 27f432b1-403d-4c0d-9e4b-854b0689c494
D = StackAllocatedDict{5}(:a=>1, :b=>2, :c=>3)

# ╔═╡ 8eb8839b-c085-468d-abcd-d4386009b75e
D[:a]

# ╔═╡ 402039e5-202c-46f5-baa1-f046ff7b5801
D[:b]

# ╔═╡ 717ef08b-30d4-4d69-8b9c-314b388cfa52
@benchmark setindex($(ntuple(i->i,32)), $10, $2)

# ╔═╡ d2d9e875-9fc3-4502-8f3f-a6e0287b09df
setindex(d, 10., 3)

# ╔═╡ fcae982c-bb8c-41d1-9150-e867d05abf90
@benchmark setindex($d, $10., $2)

# ╔═╡ f29a9735-10f8-41ef-9df2-d61a0bf3500c
 let
	N = 10
	# large_dict = StackAllocatedDict{N}([Int(k)=>Float64(k) for k ∈ 1:N]...)
	 l = StackAllocatedDict{5}(:a=>1, :b=>2, :c=>3)
	 # large_dict = Dict(:a=>1, :b=>2, :c=>3)
 end

# ╔═╡ b7dca43a-7ef5-42d7-ac11-20592e7aee92
get(d,:d,0)

# ╔═╡ b49bb4fa-cf2b-4f37-825b-a9c07349f178
length(d)

# ╔═╡ 0264e17c-f870-4d80-8a85-321b7773e8bf
t = Tuple(rand(1:10, 10))

# ╔═╡ 557f5e32-2506-4624-8d85-3c83533a4cbd
function swap(t, i, j)
	tᵢ = t[i]
	tⱼ = t[j]

	t = Base.setindex(t,tⱼ,i)
	t = Base.setindex(t,tᵢ,j)

	return t
end

# ╔═╡ 65f9d491-3bc2-4a65-94ef-8e578b84dfda
# Sort the first n elements of t.
function sort_tuple(t, n=length(t); lt=isless, by=identity)
	for k ∈ n:-1:2
		for i ∈ 1:k-1
			if lt(by(t[i+1]), by(t[i]))
				t = swap(t, i, i+1)
			end
		end
	end

	return t
end

# ╔═╡ 6eb6bb2a-e23f-446f-9354-34a16bcb2505
sort_tuple(t)

# ╔═╡ 486426c4-48d9-4b36-ba2e-aa95ea89008e
@benchmark sort_tuple($t)

# ╔═╡ 2f87bb75-c3a4-4b08-8446-87869ac91507
sort_tuple((1,2))

# ╔═╡ 8f0e0108-4ad0-4c73-b973-8eb5c453f901
sort_tuple((2,1))

# ╔═╡ d6550abd-cf21-481a-805d-4a71f89dc45a
# Assume the first n elements of t are sorted and insert val such that the first n+1 elements of the results are sorted.
function insert_sorted(t, n, val; lt=isless, by=identity)
	for i ∈ 1:n
		if isless(by(val), by(t[i]))
			val, t = t[i], Base.setindex(t,val,i)
		end
	end

	t = Base.setindex(t,val,n+1)
	return t
end

# ╔═╡ 1b4388f6-f090-45ac-a867-3b65aad469f2
st = (1,2,4,5,7,8,0,0,0,0)

# ╔═╡ d72aba57-c840-4098-b64a-ebf42f291362
insert_sorted(st, 6, 9)

# ╔═╡ Cell order:
# ╠═c9fe44ec-49d4-11eb-023a-2d887e9efdc5
# ╟─f00c228b-9fca-4d5a-8da2-ceb2ac228f86
# ╠═9568d8d3-fd75-41b9-b1dd-07d6b266630c
# ╠═7095e307-25e9-425d-8129-79dba8675d2a
# ╠═45a5e8ef-4687-46d5-9765-c6f2bfc8fe49
# ╠═a6e161f4-d34f-46fc-b894-7e18e97ead47
# ╠═6e44ec44-99b7-41a3-be6e-70bc42c64fc0
# ╠═27f432b1-403d-4c0d-9e4b-854b0689c494
# ╠═717ef08b-30d4-4d69-8b9c-314b388cfa52
# ╠═164e0d79-19f2-4002-addb-46b4ed26e3cb
# ╠═8eb8839b-c085-468d-abcd-d4386009b75e
# ╠═402039e5-202c-46f5-baa1-f046ff7b5801
# ╠═eceef74f-2dcd-4a6f-89ac-884298639a3b
# ╠═d2d9e875-9fc3-4502-8f3f-a6e0287b09df
# ╠═fcae982c-bb8c-41d1-9150-e867d05abf90
# ╠═f29a9735-10f8-41ef-9df2-d61a0bf3500c
# ╠═192fd601-2244-4c59-bdaf-a871b20c46b5
# ╠═b7dca43a-7ef5-42d7-ac11-20592e7aee92
# ╠═b49bb4fa-cf2b-4f37-825b-a9c07349f178
# ╠═8065d549-4537-4897-9a00-6f178742091a
# ╠═f72fd702-9b20-4611-821c-4daa22898142
# ╠═65f9d491-3bc2-4a65-94ef-8e578b84dfda
# ╠═0264e17c-f870-4d80-8a85-321b7773e8bf
# ╠═6eb6bb2a-e23f-446f-9354-34a16bcb2505
# ╠═486426c4-48d9-4b36-ba2e-aa95ea89008e
# ╠═2f87bb75-c3a4-4b08-8446-87869ac91507
# ╠═8f0e0108-4ad0-4c73-b973-8eb5c453f901
# ╠═557f5e32-2506-4624-8d85-3c83533a4cbd
# ╠═d6550abd-cf21-481a-805d-4a71f89dc45a
# ╠═1b4388f6-f090-45ac-a867-3b65aad469f2
# ╠═d72aba57-c840-4098-b64a-ebf42f291362
