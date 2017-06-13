matchDatasets = function(data1, data2, flank = 0){
    # Process chromosome names
    # character or numeric
    {
        # chr1 = factor(c('chr1','chr2','chr2','chr2')); chr2 = c(1,1,2,2,3,3)
        chr1 = data1[[1]];
        if(is.character(chr1) || is.factor(chr1))
            chr1 = gsub('^chr','',chr1);
        
        chr2 = data2[[1]];
        if(is.character(chr2) || is.factor(chr2))
            chr2 = gsub('^chr','',chr2);
        
        chr12 = c(chr1, chr2);
        chrset = chr12[!duplicated(chr12)];
        
        chr1ind = match(chr1, chrset);
        chr2ind = match(chr2, chrset);
        
        rm(chr1, chr2, chr12, chrset)
    } # chr1ind, chr2ind
    
    # single number coordinates for both data sets
    {
        stopifnot(all( data1[[2]] < 1e9 ))
        stopifnot(all( data1[[3]] < 1e9 ))
        stopifnot(all( data2[[2]] < 1e9 ))
        stopifnot(all( data2[[3]] < 1e9 ))
        
        data1l = chr1ind*1e9 + data1[[2]]
        data1r = chr1ind*1e9 + data1[[3]]
        
        data2l = chr2ind*1e9 + data2[[2]]
        data2r = chr2ind*1e9 + data2[[3]]
        
        rm(chr1ind, chr2ind);
    } # data1l, data1r, data2l, data2r, -chr1ind, -chr2ind
    
    # data2 must be sorted by both coordinates
    {
        if(is.unsorted(data2l)){
            ord = order(data2l);
            data2l = data2l[ord];
            data2r = data2r[ord];
            data2  = data2[ord,];
            rm(ord)
        }
        if(is.unsorted(data2r))
            stop("Second data set must have non-overlapping regions.")
        
        # Remove duplicate records in data2
        keep = c(TRUE, (diff(data2l)>0) & (diff(data2r)>0));
        if(!all(keep)){
            data2l = data2l[keep];
            data2r = data2r[keep];
            data2 = data2[keep,];
        }
        rm(keep);
    } # data2, data2l, data2r
    
    # sort data1 too
    {
        data1c = data1l + data1r;
        if(is.unsorted(data1c)){
            ord = order(data1c);
            data1l = data1l[ord];
            data1r = data1r[ord];
            data1  = data1[ord,];
            rm(ord)
        }
        rm(data1c);
    }
    
    # Construct matching index
    {
        # find elements in data2 overlapping with data1 records
        # ind1 - number of data2 intervals left of given data1
        ind1 = findInterval(data1l, data2r + (1 + flank));
        # ind1 - number of data2 intervals left of given data1 or overlapping
        ind2 = findInterval(data1r, data2l - flank);
        # Sanity check
        stopifnot(all(ind1 <= ind2));
        
        # Final matching index
        # Zero index for unmatched
        index = integer(length(ind1));
        
        # ind2 for unique overlaps
        set = which((ind2-ind1)==1);
        index[set] = ind2[set];
        rm(set);
        
        # Closest ally for multiple overlaps
        set = which((ind2-ind1)>1);
        if(length(set)>0L){
            data1c = data1l[set] + data1r[set];
            data2c = data2l      + data2r;
            indL = findInterval(data1c, data2c);
            nudge = (2 * data1c > (data2c[indL] + data2c[indL+1L]));
            indClose = indL + nudge;
            
            # The index must be among the overlap
            message("Lower bound effect ", mean(indClose <= ind1[set]));
            message("Upper bound effect ", mean(indClose >  ind2[set]));
            
            indClose = pmax(indClose, ind1[set] + 1L);
            indClose = pmin(indClose, ind2[set]     );
            
            index[set] = indClose;
            rm(data1c, data2c, indL, nudge, indClose);
        }
        rm(ind1, ind2, set)
    }
    result = list( 
        data1 = data1[index>0L,], 
        data2 = data2[index,]
        # mch   = index
    );
    return(result);
}
