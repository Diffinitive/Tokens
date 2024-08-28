module Tokens

using SparseArrays
using SparseArrayKit

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

include("token.jl")
include("to_matrix.jl")

end # module
