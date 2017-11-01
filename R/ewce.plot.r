#' Plot EWCE results
#'
#' \code{ewce.plot} generates plots of EWCE enrichment results
#'
#' @param total_res results dataframe generated using \code{\link{bootstrap.enrichment.test}} or \code{\link{ewce_expression_data}} functions. Multiple results tables can be merged into one results table, as long as the 'list' column is set to distinguish them.
#' @param mtc_method method to be used for multiple testing correction. Argument is passed to \code{\link{p.adjust}}. Valid options are "holm", "hochberg", "hommel", "bonferroni", "BH", "BY",
#   "fdr" or "none". Default method is bonferroni.
#' @return A ggplot containing the plot
#' @examples
#' # Load the single cell data
#' data("ctd")
#'
#' # Set the parameters for the analysis
#' reps=100 # <- Use 100 bootstrap lists so it runs quickly, for publishable analysis use >10000
#'
#' # Load the gene list and get human orthologs
#' data("example_genelist")
#' data("mouse_to_human_homologs")
#' m2h = unique(mouse_to_human_homologs[,c("HGNC.symbol","MGI.symbol")])
#' mouse.hits = unique(m2h[m2h$HGNC.symbol %in% example_genelist,"MGI.symbol"])
#' mouse.bg  = unique(m2h$MGI.symbol)
#'
#' # Bootstrap significance testing, without controlling for transcript length and GC content
#' full_results = bootstrap.enrichment.test(sct_data=ctd,hits=mouse.hits,
#'   bg=mouse.bg,reps=reps,annotLevel=2,sctSpecies="mouse",genelistSpecies="mouse")
#'
#' # Generate the plot
#' print(ewce.plot(full_results$results,mtc_method="BH"))
#' @export
#' @import ggplot2
#' @importFrom reshape2 melt
#' @import stats
#' @importFrom grid unit
# @import plyr
ewce.plot <- function(total_res,mtc_method="bonferroni"){
    if(!mtc_method %in% c("holm", "hochberg", "hommel", "bonferroni", "BH", "BY", "fdr", "none")){
        stop("ERROR: Invalid mtc_method argument. Please see '?p.adjust' for valid methods.")
    }
    multiList = TRUE
    if(is.null(total_res$list)){multiList = FALSE}

    # Multiple testing correction across all rows
    total_res$q = p.adjust(total_res$p,method=mtc_method)

    # Mark significant rows with asterixes
    ast_q = rep("",dim(total_res)[1])
    ast_q[total_res$q<0.05] = "*"
    total_res$ast_q = ast_q

    # GENERATE THE PLOT
    total_res$sd_from_mean[total_res$sd_from_mean<0]=0
    graph_theme = theme_bw(base_size = 12, base_family = "Helvetica") +
        theme(panel.grid.major = element_line(size = .5, color = "grey"),
              axis.line = element_line(size=.7, color = "black"), text = element_text(size=14),
              axis.title.y = element_text(vjust = 0.6))# + theme(legend.position="none")

    #total_res$
    upperLim = max(abs(total_res$sd_from_mean))

    total_res$y_ast = total_res$sd_from_mean*1.05

    total_res$abs_sd = abs(total_res$sd_from_mean)

    #print(upperLim)
    if("Direction" %in% colnames(total_res)){
        #the_plot = ggplot(total_res) + geom_bar(aes(x=CellType,y=abs(sd_from_mean),fill=Direction),position="dodge",stat="identity") + graph_theme
        the_plot = ggplot(total_res) + geom_bar(aes_string(x='CellType',y='abs_sd',fill='Direction'),position="dodge",stat="identity") + graph_theme
    }else{
        #the_plot = ggplot(total_res) + geom_bar(aes(x=CellType,y=abs(sd_from_mean),fill="red"),stat="identity") + graph_theme +theme(legend.position="none")
        the_plot = ggplot(total_res) + geom_bar(aes_string(x='CellType',y='abs_sd'),fill="red",stat="identity") + graph_theme +theme(legend.position="none")
    }

     the_plot = the_plot  +
         theme(plot.margin=unit(c(1,0,0,0),"mm"),axis.text.x = element_text(angle = 55, hjust = 1))+
         theme(panel.border = element_rect(colour = "black", fill=NA, size=1))+
         xlab("") +
         theme(strip.text.y = element_text(angle = 0)) +
         coord_cartesian(ylim = c(0,1.1*upperLim))+
         ylab("Std.Devs. from the mean") + theme(plot.margin = unit(c(0,0,0,1.5), "cm"))

     the_plot = the_plot + scale_y_continuous(breaks=c(0,ceiling(upperLim*0.66))) + geom_text(aes_string(label="ast_q",x="CellType",y="y_ast"),size=10)

     if(multiList){
         the_plot = the_plot + facet_grid("list ~ .",scales="free", space = "free_x")
         #the_plot = the_plot + facet_grid(facets="list ~ .",scale="free", space = "free_x")
     }

    return(the_plot)
}
