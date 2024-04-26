# TODO
* Check type stability
* Add documentation
* Find a good package name
* Support LinearMaps (Should use a package extension)
* add function for getting all the tokens of an "expression".
* Find a way to allow higher order tensors
* Handle both f and f! as input to the matrix converter

How to think about resusing objects in linear combinations? For example when doing `2*lc` do we have to allocate a new dict for the return object? When can things break? When will they not break?
Would it work to reuse but never modify the used storage?
    This would not allow optimizing `+(::LinearCombination,::Token)`
    It would allow optimizing `*(a::Number, t::Token)` by implementing a
    `ScaledToken` which simply holds `a` and `t`. Thus skipping one layer of allocation. Introducing this such a type would not have to impact the underlying storage of `LinearCombination` but should impact the interface (terms for exmpale should be an iterator over ScaledTokens)


Could we pre allocate the size of the LinearCombinations in some way?
We can implement `+(a...)` to cut down on the number of allocations


Static linear combinations could perhaps be simplified using https://matthias314.github.io/SmallCollections.jl/stable/
