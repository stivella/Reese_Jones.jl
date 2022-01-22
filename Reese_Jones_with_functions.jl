"""

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

"""

## set seed
using Random, Distributions, Plots, DataFrames, ColorSchemes, Colors
Random.seed!(12345)

"""
    schoolsingleiteration(numliars,lyingcondition)

Computes a single iteration of the DAA mechanism with liars and three possible values of the lying condition 

Returns a dictionary which contains welfare, the average schooling quality for every school, the number of liars and the lying condition

# Examples
```julia-repl
julia> schoolsingleiteration(10,0)
Dict{String, Real} with 13 entries:
  "numliars"          => 10
  "avgstudquality_2"  => 46.4
  "avgstudquality_4"  => 51.2
  "avgstudquality_1"  => 27.9
  "avgstudquality_8"  => 55.5
  "avgstudquality_10" => 57.5
  ⋮                   => ⋮
"""


function schoolsingleiteration(numliars,lyingcondition)
    
    numstudents=100;
    numprograms=10; 
    noisevariance = 100; #as it was set in the original file

    spreftrue=fill(Int[], numstudents); #the way students rank schools, without lies
    ppref=fill(Int[], numprograms); #the way schools rank students, as they perceive them (with noise)
    waitlist=fill(Int[], numprograms);
    quota=10*ones(Int,numprograms); 

    #Assigning true preferences for students
    for i=1:numstudents  
        spreftrue[i]=[h for h in 1:numprograms]; 
    end

            
    ##the way students rank schools, with lies
    spref=copy(spreftrue); 

    #generate noise
    d = Normal(0,noisevariance);
    tempnoise=rand(d,numstudents);

    #abilityestimate, rank the students according to their true ability, that is just the ordering
    studentsrank = [h for h in 1:numstudents];
    #add the noise previously generated
    abilitynoise = studentsrank + tempnoise; 
    #now sort them by the noise they perceive
    p = sortperm(abilitynoise);
    abilitynoiseranked = abilitynoise[p];
    newstudentsrank = studentsrank[p];
    #abilityestimate=[[1:numstudents]+tempnoise;[1:numstudents]];

    #now apply the ordering to the schools
    for i=1:numprograms  
        ppref[i]=newstudentsrank; 
    end

    #then consider the three lying conditions.
    #lying condition = 0 implies that lying is Random
    #lying condition = 1 implies that the best students lie
    #lying condition = 2 implies that the worst students lie

    if lyingcondition==0
        tempstudentlist=randperm(numstudents);

    elseif lyingcondition==1
        #for case when best students lie. 
        tempstudentlist=studentsrank;
        
    elseif lyingcondition==2
        #for case when worst students lie. 
        tempstudentlist=sort(studentsrank, rev=true);
    end

    #First, I assign the true preferences to all elements. Then I go through
    #the list of ids randomly assigned to "liar" status, and replace their
    #preferences with a random permutation. I also use the vector "liarvec" to
    #keep track of who is and is not assigned. A 1 in entry i of this vector
    #means student i is assigned to the lying condition. 


    if numliars>0
        liarvec=zeros(Bool, numstudents); #with the boolcondition it is faster
    for i=tempstudentlist[1:numliars] #take the list of students, ranked by the condition, and take only the liars
        spref[i] = randperm(numprograms);
        liarvec[i]=1;
    end
    end


    progapnumber=ones(Int,numstudents); 
    unmatched=ones(Int,numstudents); 
    waitlist_index=fill(Int[], numprograms); # in order to keep track of the indexes 
    #this is the part in which the proper DAA algorithm is run

    while maximum(unmatched)>0
        
        #Assigning unmatched students to the highest ranked program where they
        #have not been rejected
        for i=1:numstudents
        
            if progapnumber[i]>numprograms
            unmatched[i]=0; 
            end
            if unmatched[i]==1 && findall(ppref[spref[i][progapnumber[i]]].==i)!=0 
                if waitlist[spref[i][progapnumber[i]]] == Any[]
                    #inizializzo la waiting list di una scuola
                    waitlist[spref[i][progapnumber[i]]] = findall(ppref[spref[i][progapnumber[i]]].==i);
                    waitlist_index[spref[i][progapnumber[i]]] = [i];
                else
                    append!(waitlist[spref[i][progapnumber[i]]],findall(ppref[spref[i][progapnumber[i]]].==i)[1])
                    append!(waitlist_index[spref[i][progapnumber[i]]],i)
                end
                unmatched[i]=0;             
            end
        end
        
        #Schools choosing the best individuals off their waitlist
        for j=1:numprograms
        if  length(waitlist[j]) > 0
                #quindi devo ordinare la waitlist, e poi i loro indici per fare un accoppiamento giusto
                #perm = sortperm(waitlist[j]);
                waitlist_index[j] = waitlist_index[j][sortperm(waitlist[j])]
                sort!(waitlist[j]);
            if length(waitlist[j]) > quota[j]          
            startofdroppedguys=quota[j]+1;
                for k=startofdroppedguys:length(waitlist[j])
                    unmatched[waitlist_index[j][k]]=1;
                end
            waitlist[j]=waitlist[j][1:quota[j]];
            waitlist_index[j]=waitlist_index[j][1:quota[j]];
            end
        end
        
        end
    
        progapnumber+=unmatched; 
    end


    #here we compute, as they do in the do file, welfare and average student quality
    
    avgstudquality = mean(waitlist_index[j] for j in 1:numprograms) #1 by 10 array with the average student quality per school

    #compute the welfare created by every school, then sum it up
    schoolwelfare = zeros(Float64,numprograms)
    for i=1:numprograms
        q_i = (11-i)/numprograms;
        for j=1:quota[i]
             schoolwelfare[i] += q_i*(101 - waitlist_index[i][j])/100 ;
        end
    end
    welfare = sum(schoolwelfare)/30.02;

    
    
    return Dict("numliars" => numliars, "lyingcondition" => lyingcondition, "welfare" => welfare, "avgstudquality_1" => avgstudquality[1], "avgstudquality_2" => avgstudquality[2], "avgstudquality_3" => avgstudquality[3], "avgstudquality_4" => avgstudquality[4], "avgstudquality_5" => avgstudquality[5], "avgstudquality_6" => avgstudquality[6], "avgstudquality_7" => avgstudquality[7], "avgstudquality_8" => avgstudquality[8], "avgstudquality_9" => avgstudquality[9], "avgstudquality_10" => avgstudquality[10])
    #return Dict("numliars" => numliars, "lyingcondition" => lyingcondition, "School_1" => waitlist[1], "School_2" => waitlist[2], "School_3" => waitlist[3], "School_4" => waitlist[4], "School_5" => waitlist[5], "School_6" => waitlist[6], "School_7" => waitlist[7], "School_8" => waitlist[8], "School_9" => waitlist[9], "School_10" => waitlist[10])
end



"""
        multipleiterations(numliars,lyingcondition,niterations)

        Iterates the algorithm in schoolsingleiteration(numliars,lyingcondition).
        Returns a DataFrame of size (niterations+1)x13.
        Each column is an element of the dictionary.
        The last row contains the average of the previous ones.

# Examples
```julia-repl
julia> multipleiterations(20,1,100)   
101×13 DataFrame
 Row │ avgstudquality_1  avgstudquality_10  avgstudquality_2  avgstudquality_3  avgstudquality_4  avgstudquality_5  avgstudquali ⋯
     │ Float64           Float64            Float64           Float64           Float64           Float64           Float64      ⋯
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │           13.6               61.7              41.5              49.3              45.1              61.4              57 ⋯
  ⋮  │        ⋮                  ⋮                 ⋮                 ⋮                 ⋮                 ⋮                 ⋮     ⋱
 101 │           23.031             59.516            33.612            44.002            51.514            56.014            58
         
"""


function multipleiterations(numliars,lyingcondition,niterations)   
    #create the dataframe from the first iteration
        mino = DataFrame(schoolsingleiteration(numliars,lyingcondition))
    for i=2:niterations
        push!(mino,schoolsingleiteration(numliars,lyingcondition))
    end
    #as the last row I have the averages by column
    push!(mino,mean.(eachcol(mino)))
    return mino
end    


"""
        averageiterations(nit=1000)

        Performs multipleiterations(numliars,lyingcondition,niterations)
        As a default, the number of iterations is set to 1000.
        for all the possible values of numliars (6 different ones) and lyingcondition (3).
        Returns a DataFrame of size 18x13.
        Each row is the average of all the iterations for a given condition (e.g. lyingcondition=0, numliars=10)

# Examples
```julia-repl
julia> averageiterations(100)
18×13 DataFrame
 Row │ avgstudquality_1  avgstudquality_10  avgstudquality_2  avgstudquality_3  avgstudquality_4  avgstudquality_5  avgstudquali ⋯
     │ Float64           Float64            Float64           Float64           Float64           Float64           Float64      ⋯
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │           48.394             51.351            49.5              50.692            50.347            50.606            49 ⋯
  ⋮  │        ⋮                  ⋮                 ⋮                 ⋮                 ⋮                 ⋮                 ⋮     ⋱
  18 │           62.086             45.148            57.431            55.019            52.408            50.736            46

"""


function averageiterations(nit=1000)
        #all the averages are collected into a single dataframe, in order to produce some graphs
        #initialize the dataframe
        df =multipleiterations(10,1,1)
        #then I will trash the first two rows

        #iterate through the conditions on numliars and lyingcondition
        for lyingcondition=0:2
            for numliars=0:10:50
                push!(df,multipleiterations(numliars,lyingcondition,nit)[nit+1,:])
            end
        end
        #delete the first two rows, that were used only to initialize the dataframe
        delete!(df, [1,2]) 
    return df
end





################ MAKING graphs


######## GRAPH 1 ###########



"""
        reshapeforgraph1(df)

        Reshape the output of averageiterations() in order to produce graph1.
        Returns a 6x4 dataframe

# Examples
```julia-repl
julia> reshapeforgraph1(analisi)
6×4 DataFrame
 Row │ numliars  welfare   welfare_2  welfare_3 
     │ Int64     Float64   Float64    Float64   
─────┼──────────────────────────────────────────
   1 │        0  1.00091    0.999083   0.999605
  ⋮  │    ⋮         ⋮          ⋮          ⋮
   6 │       50  0.972569   0.844878   1.09065   
"""



function reshapeforgraph1(df)
    df0=df[:,11:13]
    df1=hcat(df0[1:6,2:3],df0[7:12,3])
    rename!(df1,:x1 => :welfare_2)
    df2=hcat(df1,df0[13:18,3])
    rename!(df2,:x1 => :welfare_3)
end


"""
        plotgraph1(df)

        Plots graph 1. Takes as input the output of averageiterations().
        reshapeforgraph1() is performed within the function

# Examples
```julia-repl
julia> plotgraph1(analisi)
"""



function plotgraph1(df)
    #reshape the dataset
    datasetpergrafico1 = reshapeforgraph1(df)

    #plotit
    plot(datasetpergrafico1[!,:numliars],datasetpergrafico1[!,:welfare], label = "Misrepresentations made at random", color = :gray30, legend=:bottomleft)
    plot!(datasetpergrafico1[!,:numliars],datasetpergrafico1[!,:welfare_2], label = "Misrepresentations made by best students", color = :gray60)
    plot!(datasetpergrafico1[!,:numliars],datasetpergrafico1[!,:welfare_3], label = "Misrepresentations made by worst students", color = :black)
    hline!([1.075], linestyle=:dash, color = :gray50, label = "")
    hline!([1], linestyle=:dash, color = :gray50, label = "")
    hline!([0.925], linestyle=:dash, color = :gray50, label = "")
    xlabel!("Percent of students misrepresenting preferences")
    title!("Normalized welfare")
end


###### Graph 2 ##########

"""        
        reshapeforgraph2(df,lyingcond)

        Reshapes the output of averageiterations() in order to produce graph2.
        Returns a 10x7 dataframe

# Examples
```julia-repl
julia> reshapeforgraph2(analisi,1)
10×7 DataFrame
 Row │ numliar0  numliar10  numliar20  numliar30  numliar40  numliar50  baseline 
     │ Float64   Float64    Float64    Float64    Float64    Float64    Float64  
─────┼───────────────────────────────────────────────────────────────────────────
   1 │  48.9781    27.095     22.8919    23.386     25.5374    28.4071       5.5
  ⋮  │    ⋮          ⋮          ⋮          ⋮          ⋮          ⋮         ⋮
  10 │  52.7717    56.3763    60.4768    63.5313    66.7477    67.8129      95.5
                                                                   8 rows omitted  
"""



function reshapeforgraph2(df,lyingcond)
    graph2dataset = filter(:lyingcondition  => ==(lyingcond), df)
    matricegrafico2 = transpose(Matrix(graph2dataset[:,1:10]))
    #here I change a row, because the second row corresponds to school 10 (because the numbering is 1,10,2,...)
    m3 = Matrix(vcat(matricegrafico2,transpose(matricegrafico2[2,:])))
    graph2df = DataFrame(m3, :auto)
    delete!(graph2df, 2)
    rename!(graph2df, :x1 => :numliar0, :x2 => :numliar10, :x3 => :numliar20, :x4 => :numliar30, :x5 => :numliar40, :x6 => :numliar50) 
    # add the baseline element
    graph2df = hcat(graph2df,[10x-4.5 for x=1:10])
    rename!(graph2df, :x1 => :baseline)
end


"""
        plotgraph2(df)

        Plots graph 2a, 2b, 2c, according to the values of lyingcondition.
        Takes as input the output of averageiterations().
        reshapeforgraph2() is performed within the function.

# Examples
```julia-repl
julia> plotgraph2(0,analisi)
"""

function plotgraph2(lyingcond,df)
    df2a = reshapeforgraph2(df,lyingcond)
    #titolo
    plot(df2a[!,:numliar0], label = "0 percent", legendtitle = "Misreporting share", palette = :davos, legend=:bottomright, legendtitlefontsize = 8)
    plot!(df2a[!,:numliar10], label = "10 percent")
    plot!(df2a[!,:numliar20], label = "20 percent")
    plot!(df2a[!,:numliar30], label = "30 percent")
    plot!(df2a[!,:numliar40], label = "40 percent")
    plot!(df2a[!,:numliar50], label = "50 percent")
    plot!(df2a[!,:baseline], label = "baseline", line = :dashdotdot, color = :black)
    xlabel!("School rank")
    ylabel!("Average student rank")
    if lyingcond==0
        title!("Misrepresentations made at random")
    elseif lyingcond==1
        title!("Misrepresentations made by best students")
    else
        title!("Misrepresentations made by worst students")
    end            
end








########### END OF FUNCTIONS #########

"""
    Here the objects are created.
    The dataframe is "analisi".
    p1,p2a,p2b and p2c are the plots.

    In order to produce analisi with 10000 iterations, the computing time is 111 seconds on my laptop
    (opposed to 2 hours on Matlab).
    As a default, here 1000 iterations are set.

    
# Examples
```julia-repl
julia> using BenchmarkTools
julia> @btime analisi2=averageiterations(10000)
  111.699 s (677693203 allocations: 58.47 GiB)
18×13 DataFrame
 Row │ avgstudquality_1  avgstudquality_10  avgstudquality_2  avgstudquality_3  avgstudquality_4  avgstudquality_5  avgstudquali ⋯
     │ Float64           Float64            Float64           Float64           Float64           Float64           Float64      ⋯
─────┼────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────────
   1 │          48.7357            52.2088           49.2829           49.6209           49.8778           50.2375           50. ⋯
  ⋮  │        ⋮                  ⋮                 ⋮                 ⋮                 ⋮                 ⋮                 ⋮     ⋱
  18 │          62.2634            44.6134           58.196            54.7532           51.9086           49.4354           47.
  



"""

analisi=averageiterations()

p1=plotgraph1(analisi)


p2a=plotgraph2(0,analisi)
p2b=plotgraph2(1,analisi)
p2c=plotgraph2(2,analisi)
