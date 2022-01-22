using Test, Reese_Jones_with_functions

@test hello("Julia") == "Hello, Julia"
@test domath(2.0) ≈ 7.0
