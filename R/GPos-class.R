### =========================================================================
### GPos objects
### -------------------------------------------------------------------------
###
### GPos is a container for storing a set of genomic *positions* i.e.
### genomic ranges of length 1. It's more memory-efficient than GRanges when
### the object contains long runs of adjacent positions.
###

setClass("GPos",
    contains="GenomicRanges",
    representation(
        pos_runs="GRanges",
        elementMetadata="DataFrame"
    )
)


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Accessors
###

setMethod("length", "GPos", function(x) sum(width(x@pos_runs)))

setReplaceMethod("names", "GPos",
    function(x, value) stop(class(x), " objects don't accept names")
)

setMethod("seqnames", "GPos",
    function(x) rep.int(seqnames(x@pos_runs), width(x@pos_runs))
)

setGeneric("pos", function(x) standardGeneric("pos"))
setMethod("pos", "GPos", function(x) as.integer(ranges(x@pos_runs)))
setMethod("start", "GPos", function(x) pos(x))
setMethod("end", "GPos", function(x) pos(x))
setMethod("width", "GPos", function(x) rep.int(1L, length(x)))
setMethod("ranges", "GPos", function(x) IRanges(pos(x), width=1L))

setMethod("strand", "GPos",
    function(x) rep.int(strand(x@pos_runs), width(x@pos_runs))
)

setMethod("seqinfo", "GPos", function(x) seqinfo(x@pos_runs))


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Constructor
###

### Merge adjacent ranges.
### Returns a GRanges object (NOT an endomorphism).
### Note that this transformation preserves 'sum(width(x))'.
.merge_adjacent_ranges <- function(x, drop.empty.ranges=FALSE)
{
    if (length(x) == 0L)
        return(granges(x))  # returning GRanges() would loose the seqinfo

    x_seqnames <- seqnames(x)
    x_strand <- strand(x)
    x_start <- start(x)
    x_end <- end(x)
    new_run <- x_seqnames[-1L] != x_seqnames[-length(x)] |
        x_strand[-1L] != x_strand[-length(x)] |
        Rle(x_start[-1L] != x_end[-length(x)] + 1L)
    new_run_idx <- which(new_run)
    start_idx <- c(1L, new_run_idx + 1L)
    end_idx <- c(new_run_idx, length(x))

    ans_ranges <- IRanges(x_start[start_idx], x_end[end_idx])

    if (drop.empty.ranges) {
        keep_idx <- which(width(ans_ranges) != 0L)
        ans_ranges <- ans_ranges[keep_idx]
        start_idx <- start_idx[keep_idx]
    }

    ans_seqnames <- x_seqnames[start_idx]
    ans_strand <- x_strand[start_idx]
    ans_mcols <- new("DataFrame", nrows=length(start_idx))
    ans_seqinfo <- seqinfo(x)

    ## To be as fast as possible, we don't use internal constructor
    ## newGRanges() and we don't check the new object.
    new2("GRanges", seqnames=ans_seqnames,
                    ranges=ans_ranges,
                    strand=ans_strand,
                    elementMetadata=ans_mcols,
                    seqinfo=ans_seqinfo,
                    check=FALSE)
}

### Note that if 'pos_runs' is a GPos instance with no metadata or metadata
### columns, then 'identical(GPos(pos_runs), pos_runs)' is TRUE.
GPos <- function(pos_runs)
{
    if (!is(pos_runs, "GenomicRanges"))
        stop("'pos_runs' must be a GenomicRanges object")
    suppressWarnings(ans_len <- sum(width(pos_runs)))
    if (is.na(ans_len))
        stop("too many genomic positions in 'pos_runs'")
    ans_mcols <- new("DataFrame", nrows=ans_len)
    pos_runs <- .merge_adjacent_ranges(pos_runs, drop.empty.ranges=TRUE)
    new2("GPos", pos_runs=pos_runs, elementMetadata=ans_mcols)
}


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Subsetting
###

# TODO


### - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - -
### Show
###
### The "show" method for GenomicRanges objects works on GPos objects (and
### any GenomicRanges derivative in general) because it coerces the object
### to GRanges. However, for a GPos object this coercion is typically too
### costly: it's analog to turning an Rle back into an ordinary vector for
### the sole purpose of displaying its head and its tail. This defeats the
### purpose of using an Rle or GPos object in the first place.
###

# TODO: Implement efficient "show" method.
