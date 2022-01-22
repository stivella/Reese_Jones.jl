## Replicate "Mistaken Play in the Deferred
## Acceptance Algorithm: Implications for Positive Assortative Matching"

## set seed
using Random, Distributions, Plots
Random.seed!(12345)

#Instantiating variables
#numiterations=10000;
numiterations=10; ## per fare un po' più in fretta e capire come funziona il codice
numstudents=100;
numprograms=10; 
noisevariance = 100; #poi cambiarla. Qui è il succo!!

data = [] ;
#qui il codice matlab comincia con il triplo ciclo for.
#proviamo a far andare la cosa una volta sola in julia, poi vediamo

numliars=10;
lyingcondition=0;

#for liarpercent=0:10:50
 #   numliars=numstudents*liarpercent/100;
  #  for lyingcondition=0:2
        #Displaying progress during simulation:
   #     liarpercent
    #    lyingcondition
     #   for iteration=1:numiterations



#crea celle in matlab

            spreftrue=fill(Int[], numstudents); #the way students rank schools, without lies
            ppref=fill(Int[], numprograms); #the way schools rank students, as they perceive them (with noise)
            waitlist=fill(Int[], numprograms);
            quota=10*ones(Int,numprograms); #check if needed


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


            progapnumber=ones(Int,numstudents); #vedere se trasformarlo in bool
            unmatched=ones(Int,numstudents); #vedere se trasformarlo in bool

            waitlist_index=fill(Int[], numprograms);
            #ora mega ciclo while 

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

            #data=[data; iteration, liarpercent, lyingcondition, waitlist{1}(:,1)',waitlist{2}(:,1)', waitlist{3}(:,1)', waitlist{4}(:,1)', waitlist{5}(:,1)', waitlist{6}(:,1)', waitlist{7}(:,1)', waitlist{8}(:,1)', waitlist{9}(:,1)', waitlist{10}(:,1)'];
            #qui sta salvando il dataframe con tutte le iterazioni
            
  #      end
  #  end
#end

