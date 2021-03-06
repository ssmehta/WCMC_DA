# Some useful keyboard shortcuts for package authoring:
#
#   Build and Reload Package:  'Ctrl + Shift + B'
#   Check Package:             'Ctrl + Shift + E'
#   Test Package:              'Ctrl + Shift + T'
mainApp = function(input,

                   distance_method = "euclidean",
                   minkowski_p = NULL, # only used when minkowski is used.
                   cluster_method = "complete",

                   scale_feature = T,
                   scale_sample = T,

                   row_col = "none",
                   row_branchColorNumber = 1,

                   col_col = "none",
                   col_branchColorNumber = 1
                   ){
  library(pacman)
  pacman::p_load(data.table,parallel, dendextend,
                 colorspace,gplots,stringr,RColorBrewer,mvtnorm)

  data. = WCMC.Fansly::FiehnLabFormat(input)
  e = data.$e
  f = data.$f
  p = data.$p

  # e = fread("e.csv")[,-1]
  # f = fread("f.csv")[,-1]
  # p = fread("p.csv")[,-1]

  e = as.matrix(e)

  # e = t(apply(e,1,function(x){
  #   x[is.na(x)] = 0.5*min(x,na.rm = T)
  #   return(x)
  # }))

  # get the data_row
  if(scale_feature){
    data_row = scale(t(e))
  }else{
    data_row = t(e)
  }

  rownames(data_row) = p$`sample label`
  d_e <- dist(data_row, method = distance_method,p=minkowski_p)
  hc_iris_row <- hclust(d_e, method = cluster_method)
  iris_species <- rev(levels(as.factor(p[[row_col]])))

  dend_row <- as.dendrogram(hc_iris_row)
  # order it the closest we can to the order of the observations:
  dend_row <- rotate(dend_row, 1:nrow(p))

  # Branch Color
  if(row_branchColorNumber==1){
    dend_row <- color_branches(dend_row, k=row_branchColorNumber,col='black')
  }else{
    dend_row <- color_branches(dend_row, k=row_branchColorNumber,
                               col=brewer.pal(n=row_branchColorNumber,name="Set1"))
  }
  # Label Color
  labels_colors(dend_row) <-
    rainbow_hcl(length(unique(p[[row_col]])))[sort_levels_values(
      as.numeric(as.factor(p[[row_col]]))[order.dendrogram(dend_row)]
    )]


    # Change Label
  if(length(as.character(p[[row_col]]))==0){
    labels(dend_row) <- p$`sample label`
  }else{
    labels(dend_row) <- paste(as.character(p[[row_col]])[order.dendrogram(dend_row)],
                              "(",p$`sample label`[order.dendrogram(dend_row)],")",
                              sep = "")
  }


  # Hang
  dend_row <- hang.dendrogram(dend_row,hang = 0.1)

  # Label Size
  dend_row <- set(dend_row, "labels_cex",0.5)

  pdf(file = "Dendrogram_Sample.pdf")
  plot(dend_row,
       main = "Clustered Samples",
       horiz =  TRUE,  nodePar = list(cex = .007))
  # if(!length(iris_species)==0){
  #   legend("topleft", legend = unique(p[[row_col]]), fill = rainbow_hcl(length(unique(p[[row_col]]))))
  # }
  dev.off()

  # Hang back
  dend_row <- hang.dendrogram(dend_row,-1)

    # column dend.
  {
    if(scale_sample){
      data_col = scale(as.matrix(e))
    }else{
      data_col = as.matrix(e)
    }

    rownames(data_col) = f[[1]]
    d_e <- dist(data_col, method = distance_method)
    hc_iris_col <- hclust(d_e, method = cluster_method)
    iris_species <- rev(levels(as.factor(p[[col_col]])))

    dend_col <- as.dendrogram(hc_iris_col)
    # order it the closest we can to the order of the observations:
    dend_col <- rotate(dend_col, 1:nrow(f))

    # Branch Color
    if(col_branchColorNumber==1){
      dend_col <- color_branches(dend_col, k=col_branchColorNumber,col='black')
    }else{
      dend_col <- color_branches(dend_col, k=col_branchColorNumber,
                                 col=brewer.pal(n=col_branchColorNumber,name="Set1"))
    }

    # Label Color

    labels_colors(dend_col) <-
      rainbow_hcl(length(unique(f[[col_col]])))[sort_levels_values(
        as.numeric(as.factor(f[[col_col]]))[order.dendrogram(dend_col)]
      )]




    # Change Label
    if(length(as.character(f[[col_col]]))==0){
      labels(dend_col) <- f[[1]][order.dendrogram(dend_col)]
    }else{
      labels(dend_col) <- paste(as.character(f[[col_col]])[order.dendrogram(dend_col)],
                                "(",f[[1]][order.dendrogram(dend_col)],")",
                                sep = "")
    }

    # Hang
    # dend_col <- hang.dendrogram(dend_col,0.1)

    # Label Size
    dend_col <- set(dend_col, "labels_cex", 0.1)


    pdf(file = "Dendrogram_Compound.pdf",height = 14)
    plot(dend_col,
         main = "Clustered On Compounds",
         horiz =  T,  nodePar = list(cex = .007))
    # if(!length(iris_species)==0){
    #   legend("none", legend = iris_species, fill = rainbow_hcl(length(unique(f[[col_col]]))))
    # }
    dev.off()

    # Hang back
    # dend_col <- hang.dendrogram(dend_col,-1)
  }




  # HEATMAP
  some_col_func <- function(n) rev(colorspace::heat_hcl(n, c = c(80, 30), l = c(30, 90),
                                                        power = c(1/5, 1.5)))
  order.dendrogram(dend_row)= 1:nrow(p)
  order.dendrogram(dend_col)= 1:nrow(f)

  png(filename = "HeatMap.png",
      width = 3000, height = 800, res = 72)
  gplots::heatmap.2(data_row,
                    main = "A global View of Heatmap",
                    srtCol = 45,
                    dendrogram = "both",
                    Rowv = dend_row,
                    Colv = dend_col, # this to make sure the columns are not ordered
                    trace="none",
                    margins =c(10,10),
                    key.xlab = "sd",
                    denscol = "grey",
                    density.info = "density",
                    RowSideColors = labels_colors(dend_row), # to add nice colored strips
                    ColSideColors = labels_colors(dend_col), # to add nice colored strips
                    col = some_col_func,
                    colRow = labels_colors(dend_row),
                    labRow = labels(dend_row),
                    colCol = labels_colors(dend_col),
                    labCol = labels(dend_col),
                    cexCol = 1,
                    keysize =1
  )
  dev.off()

  cut_row = data.frame(cutree(hc_iris_row,k=row_branchColorNumber))
  colnames(cut_row) = paste0("Cut into ",row_branchColorNumber, " clusters")
  result_row = cbind(p,cut_row)

  cut_col = data.frame(cutree(hc_iris_col,k=col_branchColorNumber))
  colnames(cut_col) = paste0("Cut into ",col_branchColorNumber, " clusters")
  result_col = cbind(f,cut_col)


  fwrite(data.table(result_row),"Dendrogram_row.csv")
  fwrite(data.table(result_row),"Dendrogram_row.txt",sep = "\t")

  fwrite(data.table(result_col),"Dendrogram_col.csv")
  fwrite(data.table(result_col),"Dendrogram_col.txt",sep = "\t")



  zip(zipfile = "HeatMap&Dendrogram.zip",files = c("Dendrogram_col.csv",
                                                   "Dendrogram_Compound.pdf",
                                                   "Dendrogram_row.csv",
                                                   "Dendrogram_Sample.pdf",
                                                   "HeatMap.png"))
  # return(result)


}
