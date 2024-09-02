# Tokens

**WIP**

Methods for efficiently assembling sparse matrices or tensors for linear operators defined by their action. See the implementation and tests for `to_matrix`, `_to_matrix`, and `to_tensor` for usage.

The implementation builds on a very lightweight implementation of symbolics, which allows tracking the action of a particular linear operator by applying the operator to an array of these simple symbolics.
