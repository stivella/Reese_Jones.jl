# Reese_Jones.jl
Replication files for Rees-Jones, Alex. 2017. "Mistaken Play in the Deferred Acceptance Algorithm: Implications for Positive Assortative Matching." American Economic Review, 107 (5): 225-29.

Replicate "Mistaken Play in the Deferred
Acceptance Algorithm: Implications for Positive Assortative Matching"


The file is built as follows:

Function schoolsingleiteration(numliars,lyingcondition) takes as inputs the number of liars and the lyingcondition 
    performs a single iteration of the DAA mechanism, with the condition previously defined.
    The output is a dictionary which contains the average student quality per school
    and the aggregate welfare

The second function creates a dataframe containing all the iterations for a single pair of conditions
    (i.e. lyingcondition and numliars)

In the third function all the averages are collected into a single dataframe,
    in order to produce some graphs

Then 2 pairs of functions are introduced.
    Each pair creates a single graph
    Function reshapeforgraph1 prepares the dataset, and plotgraph1 produces graph1.
    Similarly do reshapeforgraph2 and plotgraph2.
